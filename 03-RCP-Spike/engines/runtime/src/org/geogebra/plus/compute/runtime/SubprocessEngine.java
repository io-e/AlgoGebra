package org.geogebra.plus.compute.runtime;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;
import org.geogebra.plus.compute.api.ExternalComputeService;

/**
 * One-process-per-evaluation engine runner. It writes a complete script to
 * stdin, drains stdout/stderr concurrently, applies a hard timeout, and kills
 * the process tree if the engine does not exit. It never substitutes engines.
 */
public abstract class SubprocessEngine implements ExternalComputeService {

    private static final int MAX_COMMAND_BYTES = 131_072;
    private static final int MAX_CAPTURE_BYTES = 1_048_576;
    private static final long STREAM_JOIN_MILLIS = 2_000;
    private static final ExecutorService IO_POOL = Executors.newCachedThreadPool(task -> {
        Thread thread = new Thread(task, "geogebraplus-engine-io");
        thread.setDaemon(true);
        return thread;
    });

    protected abstract List<String> executableCandidates();

    protected abstract String validateCommand(String command) throws ExternalComputeException;

    protected abstract Request prepareRequest(Path executable, String validatedCommand,
            ComputeContext context) throws ExternalComputeException;

    protected abstract ComputeResult createResult(Request request, ProcessOutput output,
            Duration elapsed) throws ExternalComputeException;

    protected List<String> executableArguments() {
        return List.of();
    }

    @Override
    public final boolean isAvailable() {
        return ExecutableResolver.resolveOnPath(executableCandidates()).isPresent();
    }

    @Override
    public final ComputeResult eval(String command, ComputeContext context)
            throws ExternalComputeException {
        if (command == null || command.isBlank()) {
            throw new ExternalComputeException(Code.INVALID_REQUEST, "Command must not be empty");
        }
        byte[] commandBytes = command.getBytes(StandardCharsets.UTF_8);
        if (commandBytes.length > MAX_COMMAND_BYTES) {
            throw new ExternalComputeException(Code.INVALID_REQUEST,
                    "Command exceeds the WIMS interface limit of " + MAX_COMMAND_BYTES + " UTF-8 bytes");
        }
        ComputeContext effectiveContext = context == null ? ComputeContext.defaults() : context;
        String validatedCommand = validateCommand(command);
        Path executable = ExecutableResolver.resolveOnPath(executableCandidates())
                .orElseThrow(() -> new ExternalComputeException(Code.ENGINE_UNAVAILABLE,
                        getEngineId() + " executable is not installed on PATH; checked "
                                + String.join(", ", executableCandidates())));

        Request request = null;
        long started = System.nanoTime();
        try {
            request = prepareRequest(executable, validatedCommand, effectiveContext);
            ProcessOutput output = runProcess(request.processCommand(), request.stdin(),
                    effectiveContext.timeout());
            if (output.exitCode() != 0) {
                throw new ExternalComputeException(Code.PROCESS_FAILED,
                        getEngineId() + " exited with code " + output.exitCode() + diagnostic(output.stderr()));
            }
            if (output.stdoutTruncated()) {
                throw new ExternalComputeException(Code.INVALID_OUTPUT,
                        getEngineId() + " stdout exceeded the " + MAX_CAPTURE_BYTES + " byte capture limit");
            }
            Duration elapsed = Duration.ofNanos(System.nanoTime() - started);
            ComputeResult result = createResult(request, output, elapsed);
            request = null; // The result, if any, now owns its artifact lifecycle.
            return result;
        } catch (ExternalComputeException failure) {
            cleanupAfterFailure(request, failure);
            throw failure;
        } catch (IOException failure) {
            cleanupAfterFailure(request, failure);
            throw new ExternalComputeException(Code.PROCESS_START_FAILED,
                    "Could not run " + getEngineId() + ": " + failure.getMessage(), failure);
        } catch (RuntimeException failure) {
            cleanupAfterFailure(request, failure);
            throw new ExternalComputeException(Code.PROCESS_FAILED,
                    "Unexpected " + getEngineId() + " runner failure: " + failure.getMessage(), failure);
        }
    }

    // ---- WIMS src/Interfaces/common.c port (prepare1/putparm/readresult), BUG-001/BUG-002 fix, GROK_V1 ----
    private static final java.security.SecureRandom MARKER_RANDOM = new java.security.SecureRandom();

    /** Per-call random marker pair, as WIMS prepare1(): "Start line <prog> r1 r2 r3 r4" / "End line ...". */
    public record WimsMarkers(String start, String end) {
    }

    public static WimsMarkers newMarkers(String progname) {
        StringBuilder r = new StringBuilder();
        for (int i = 0; i < 4; i++) {
            r.append(' ').append(Integer.toUnsignedString(MARKER_RANDOM.nextInt() & 0x7fffffff));
        }
        return new WimsMarkers("Start line " + progname + r, "End line " + progname + r);
    }

    /**
     * WIMS putparm(): start marker, command, newline if missing, end marker, each marker printed with the
     * engine's stringprinter (PARI {@code print("%s")\n}, Maxima {@code "%s";\n}).
     */
    public static String wrapWithMarkers(String command, WimsMarkers markers, String stringPrinter) {
        StringBuilder b = new StringBuilder();
        b.append(String.format(Locale.ROOT, stringPrinter, markers.start()));
        b.append(command);
        if (!command.endsWith("\n")) {
            b.append('\n');
        }
        b.append(String.format(Locale.ROOT, stringPrinter, markers.end()));
        return b.toString();
    }

    /**
     * WIMS readresult(): locate the first start marker, then the end marker after it; move the end back to the
     * preceding newline when it is within 64 chars (drops the prompt/echo that carries the end marker); then skip
     * to the text after the LAST start marker in that slice. Returns null when either marker is missing
     * (WIMS: "execution error or time out").
     */
    public static String extractBetweenMarkers(String stdout, WimsMarkers markers) {
        if (stdout == null) {
            return null;
        }
        String out = stdout.replace("\r", "");
        int p = out.indexOf(markers.start());
        if (p < 0) {
            return null;
        }
        p += markers.start().length();
        int pe = out.indexOf(markers.end(), p);
        if (pe < 0) {
            return null;
        }
        int pp = pe - 1;
        while (pp >= p && pp > pe - 64 && out.charAt(pp) != '\n') {
            pp--;
        }
        if (pp >= p && out.charAt(pp) == '\n') {
            pe = pp;
        }
        String slice = out.substring(p, pe);
        int last;
        while ((last = slice.indexOf(markers.start())) >= 0) {
            slice = slice.substring(last + markers.start().length());
        }
        return slice;
    }

    /** Extraction that fails like WIMS when the end marker never arrived. */
    protected final String extractOrFail(String stdout, WimsMarkers markers) throws ExternalComputeException {
        String slice = extractBetweenMarkers(stdout, markers);
        if (slice == null) {
            throw new ExternalComputeException(Code.INVALID_OUTPUT,
                    getEngineId() + ": execution error or time out (WIMS start/end markers not found in output)");
        }
        return slice;
    }

    protected final Request request(Path executable, List<String> arguments, String stdin,
            WimsMarkers markers) {
        List<String> processCommand = ExecutableResolver.command(executable, arguments,
                isWindows(), System.getenv());
        return new Request(processCommand, stdin, null, null, markers);
    }

    protected final Request request(Path executable, List<String> arguments, String stdin,
            Path artifact, Path artifactDirectory) {
        List<String> processCommand = ExecutableResolver.command(executable, arguments,
                isWindows(), System.getenv());
        return new Request(processCommand, stdin, artifact, artifactDirectory);
    }

    protected final ProcessOutput runProcess(List<String> processCommand, String stdin,
            Duration timeout) throws ExternalComputeException, IOException {
        if (processCommand == null || processCommand.isEmpty()) {
            throw new ExternalComputeException(Code.PROCESS_START_FAILED, "Empty process command");
        }
        byte[] input = stdin.getBytes(StandardCharsets.UTF_8);
        if (input.length > 1_048_576) {
            throw new ExternalComputeException(Code.INVALID_REQUEST, "Engine script exceeds 1 MiB");
        }
        ProcessBuilder builder = new ProcessBuilder(processCommand);
        builder.environment().putIfAbsent("LC_ALL", "C");
        final Process process;
        try {
            process = builder.start();
        } catch (IOException failure) {
            throw new ExternalComputeException(Code.PROCESS_START_FAILED,
                    "Could not start executable " + processCommand.get(0) + ": " + failure.getMessage(), failure);
        }

        Future<CapturedStream> stdoutFuture = IO_POOL.submit(() -> capture(process.getInputStream()));
        Future<CapturedStream> stderrFuture = IO_POOL.submit(() -> capture(process.getErrorStream()));
        Future<IOException> stdinFuture = IO_POOL.submit(() -> writeAndClose(process.getOutputStream(), input));
        boolean completed;
        try {
            completed = process.waitFor(Math.max(1, timeout.toMillis()), TimeUnit.MILLISECONDS);
        } catch (InterruptedException interrupted) {
            terminateTree(process);
            Thread.currentThread().interrupt();
            throw new ExternalComputeException(Code.PROCESS_FAILED,
                    getEngineId() + " evaluation was interrupted", interrupted);
        }

        if (!completed) {
            terminateTree(process);
            stdinFuture.cancel(true);
            CapturedStream stdout = collect(stdoutFuture);
            collect(stderrFuture);
            throw new ExternalComputeException(Code.PROCESS_TIMEOUT,
                    getEngineId() + " exceeded timeout " + timeout.toMillis() + " ms; process tree was killed"
                            + (stdout.text().isBlank() ? "" : "; partial stdout was captured"));
        }

        IOException inputFailure = awaitInput(stdinFuture);
        CapturedStream stdout = collect(stdoutFuture);
        CapturedStream stderr = collect(stderrFuture);
        if (inputFailure != null) {
            throw new ExternalComputeException(Code.PROCESS_FAILED,
                    "Could not send the script to " + getEngineId() + ": " + inputFailure.getMessage(), inputFailure);
        }
        return new ProcessOutput(process.exitValue(), stdout.text(), stderr.text(),
                stdout.truncated(), stderr.truncated());
    }

    protected static boolean containsForbidden(String command, String[] forbidden) {
        String lower = command.toLowerCase(Locale.ROOT);
        for (String value : forbidden) {
            if (lower.contains(value.toLowerCase(Locale.ROOT))) {
                return true;
            }
        }
        return false;
    }

    protected static String normalizeControls(String command) {
        StringBuilder normalized = new StringBuilder(command.length());
        for (int i = 0; i < command.length(); i++) {
            char character = command.charAt(i);
            if ((character < 0x20 && character != '\n' && character != '\t')
                    || character >= 0x7f && character <= 0x9f) {
                normalized.append(' ');
            } else {
                normalized.append(character);
            }
        }
        return normalized.toString();
    }

    private static IOException writeAndClose(OutputStream stream, byte[] input) {
        try (stream) {
            stream.write(input);
            stream.flush();
            return null;
        } catch (IOException failure) {
            return failure;
        }
    }

    private static CapturedStream capture(InputStream input) throws IOException {
        try (input; ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[8192];
            int remaining = MAX_CAPTURE_BYTES;
            boolean truncated = false;
            int count;
            while ((count = input.read(buffer)) != -1) {
                int copied = Math.min(count, remaining);
                if (copied > 0) {
                    output.write(buffer, 0, copied);
                    remaining -= copied;
                }
                if (copied < count) {
                    truncated = true;
                }
            }
            return new CapturedStream(output.toString(StandardCharsets.UTF_8), truncated);
        }
    }

    private static CapturedStream collect(Future<CapturedStream> future) {
        try {
            return future.get(STREAM_JOIN_MILLIS, TimeUnit.MILLISECONDS);
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            return new CapturedStream("", false);
        } catch (ExecutionException | TimeoutException failure) {
            future.cancel(true);
            return new CapturedStream("", false);
        }
    }

    private static IOException awaitInput(Future<IOException> future) {
        try {
            return future.get(500, TimeUnit.MILLISECONDS);
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            future.cancel(true);
            return new IOException("Interrupted while sending script", interrupted);
        } catch (ExecutionException failure) {
            Throwable cause = failure.getCause();
            return cause instanceof IOException ioFailure ? ioFailure : new IOException(cause);
        } catch (TimeoutException timeout) {
            future.cancel(true);
            return new IOException("Engine did not finish reading stdin", timeout);
        }
    }

    private static void terminateTree(Process process) {
        List<ProcessHandle> descendants = new ArrayList<>(process.descendants().toList());
        for (int i = descendants.size() - 1; i >= 0; i--) {
            descendants.get(i).destroyForcibly();
        }
        process.destroy();
        try {
            if (!process.waitFor(250, TimeUnit.MILLISECONDS)) {
                process.destroyForcibly();
                process.waitFor(1, TimeUnit.SECONDS);
            }
        } catch (InterruptedException interrupted) {
            process.destroyForcibly();
            Thread.currentThread().interrupt();
        }
    }

    private static void cleanupAfterFailure(Request request, Throwable failure) {
        if (request == null) {
            return;
        }
        try {
            request.deleteArtifacts();
        } catch (IOException cleanupFailure) {
            failure.addSuppressed(cleanupFailure);
        }
    }

    private static String diagnostic(String stderr) {
        String trimmed = stderr == null ? "" : stderr.strip();
        if (trimmed.isEmpty()) {
            return "";
        }
        return "; stderr: " + trimmed.substring(0, Math.min(trimmed.length(), 2000));
    }

    private static boolean isWindows() {
        return System.getProperty("os.name", "").toLowerCase(Locale.ROOT).contains("win");
    }

    protected static final class Request {
        private final List<String> processCommand;
        private final String stdin;
        private final Path artifact;
        private final Path artifactDirectory;
        private final WimsMarkers markers;

        protected Request(List<String> processCommand, String stdin, Path artifact, Path artifactDirectory) {
            this(processCommand, stdin, artifact, artifactDirectory, null);
        }

        protected Request(List<String> processCommand, String stdin, Path artifact, Path artifactDirectory,
                WimsMarkers markers) {
            this.markers = markers;
            this.processCommand = List.copyOf(processCommand);
            this.stdin = stdin;
            this.artifact = artifact;
            this.artifactDirectory = artifactDirectory;
        }

        public List<String> processCommand() {
            return processCommand;
        }

        public WimsMarkers markers() {
            return markers;
        }

        public String stdin() {
            return stdin;
        }

        public Path artifact() {
            return artifact;
        }

        public Path artifactDirectory() {
            return artifactDirectory;
        }

        public void deleteArtifacts() throws IOException {
            if (artifact != null) {
                java.nio.file.Files.deleteIfExists(artifact);
            }
            if (artifactDirectory != null) {
                java.nio.file.Files.deleteIfExists(artifactDirectory);
            }
        }
    }

    protected record ProcessOutput(int exitCode, String stdout, String stderr,
            boolean stdoutTruncated, boolean stderrTruncated) {
    }

    private record CapturedStream(String text, boolean truncated) {
    }
}
