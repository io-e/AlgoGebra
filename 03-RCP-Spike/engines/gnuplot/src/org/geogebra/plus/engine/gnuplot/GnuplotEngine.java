package org.geogebra.plus.engine.gnuplot;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Pattern;

import org.geogebra.plus.compute.api.ComputeCapability;
import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;
import org.geogebra.plus.compute.runtime.SubprocessEngine;

/** One-shot Gnuplot wrapper that captures a validated PNG artifact. */
public final class GnuplotEngine extends SubprocessEngine {

    private static final byte[] PNG_SIGNATURE = {
            (byte) 0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a
    };
    private static final Pattern FORBIDDEN_COMMAND = Pattern.compile(
            "(?i)(?:^|[;\\s])(?:system|shell)\\s*(?:\\(|\\b)");
    private static final Pattern FORBIDDEN_IO = Pattern.compile(
            "(?i)(?:^|[;\\s])(?:load|save|cd)\\b|\\bset\\s+(?:output|terminal|print)\\b");
    private static final Pattern PLOT_COMMAND = Pattern.compile("(?im)^\\s*(?:plot|splot)\\b");
    private static final Pattern PROCESS_INPUT = Pattern.compile("(?i)\\b(?:plot|splot)\\s+[\"'][|<]");
    private static final Pattern SHELL_ESCAPE = Pattern.compile("(?m)(?:^|[;\\n])\\s*!");

    @Override
    public String getEngineId() {
        return "gnuplot";
    }

    @Override
    public Set<ComputeCapability> getCapabilities() {
        return Set.of(ComputeCapability.PLOT_2D, ComputeCapability.PLOT_3D);
    }

    @Override
    protected List<String> executableCandidates() {
        return isWindows() ? List.of("gnuplot.exe", "gnuplot") : List.of("gnuplot");
    }

    @Override
    protected String validateCommand(String command) throws ExternalComputeException {
        String normalized = normalizeControls(command).strip();
        String lower = normalized.toLowerCase(Locale.ROOT);
        if (SHELL_ESCAPE.matcher(normalized).find()) {
            throw new ExternalComputeException(Code.COMMAND_REJECTED,
                    "Gnuplot shell escape commands beginning with ! are blocked");
        }
        if (FORBIDDEN_COMMAND.matcher(lower).find()) {
            throw new ExternalComputeException(Code.COMMAND_REJECTED,
                    "Gnuplot system and shell commands are blocked");
        }
        if (FORBIDDEN_IO.matcher(lower).find()) {
            throw new ExternalComputeException(Code.COMMAND_REJECTED,
                    "Gnuplot file, terminal, and output redirection commands are blocked");
        }
        if (PROCESS_INPUT.matcher(normalized).find()) {
            throw new ExternalComputeException(Code.COMMAND_REJECTED,
                    "Gnuplot process-pipe plot sources are blocked");
        }
        if (!PLOT_COMMAND.matcher(normalized).find()) {
            throw new ExternalComputeException(Code.INVALID_REQUEST,
                    "Gnuplot MVP accepts a command containing plot or splot");
        }
        return normalized;
    }

    @Override
    protected Request prepareRequest(Path executable, String validatedCommand,
            ComputeContext context) throws ExternalComputeException {
        try {
            Path root = context.tempDirectory().toAbsolutePath().normalize();
            Files.createDirectories(root);
            Path artifactDirectory = Files.createTempDirectory(root, "algogebra-gnuplot-");
            Path artifact = artifactDirectory.resolve("plot.png");
            String quotedOutput = quoteGnuplotPath(artifact);
            String script = "set terminal png size " + context.plotWidth() + "," + context.plotHeight() + "\n"
                    + "set output \"" + quotedOutput + "\"\n"
                    + validatedCommand + "\n"
                    + "unset output\n"
                    + "exit\n";
            return request(executable, executableArguments(), script, artifact, artifactDirectory);
        } catch (IOException failure) {
            throw new ExternalComputeException(Code.PROCESS_START_FAILED,
                    "Could not create Gnuplot output directory: " + failure.getMessage(), failure);
        }
    }

    @Override
    protected ComputeResult createResult(Request request, ProcessOutput output, Duration elapsed)
            throws ExternalComputeException {
        Path png = request.artifact();
        try {
            if (png == null || !Files.isRegularFile(png) || Files.size(png) < 24) {
                throw new ExternalComputeException(Code.INVALID_OUTPUT,
                        "Gnuplot exited successfully but did not produce a PNG file");
            }
            byte[] header = new byte[24];
            try (var input = Files.newInputStream(png)) {
                if (input.read(header) != header.length) {
                    throw new ExternalComputeException(Code.INVALID_OUTPUT, "Gnuplot output is a truncated PNG");
                }
            }
            for (int i = 0; i < PNG_SIGNATURE.length; i++) {
                if (header[i] != PNG_SIGNATURE[i]) {
                    throw new ExternalComputeException(Code.INVALID_OUTPUT,
                            "Gnuplot output does not have the PNG signature");
                }
            }
            if (header[12] != 'I' || header[13] != 'H' || header[14] != 'D' || header[15] != 'R') {
                throw new ExternalComputeException(Code.INVALID_OUTPUT,
                        "Gnuplot PNG is missing the IHDR chunk");
            }
            ByteBuffer dimensions = ByteBuffer.wrap(header, 16, 8).order(ByteOrder.BIG_ENDIAN);
            int width = dimensions.getInt();
            int height = dimensions.getInt();
            if (width < 1 || height < 1) {
                throw new ExternalComputeException(Code.INVALID_OUTPUT,
                        "Gnuplot PNG reports invalid dimensions: " + width + "x" + height);
            }
            return ComputeResult.image(getEngineId(), png, "image/png", elapsed,
                    request.artifactDirectory());
        } catch (IOException failure) {
            throw new ExternalComputeException(Code.INVALID_OUTPUT,
                    "Could not read Gnuplot PNG output: " + failure.getMessage(), failure);
        }
    }

    private static String quoteGnuplotPath(Path output) {
        return output.toString().replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static boolean isWindows() {
        return System.getProperty("os.name", "").toLowerCase(Locale.ROOT).startsWith("windows");
    }
}
