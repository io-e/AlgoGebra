/* GROK_V1 — EE-P1: pngcairo header; block call/backticks (EE-12 / F-09). */
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
    // EE-12 / F-09: also block call and backtick command substitution; host forces terminal/output.
    private static final Pattern FORBIDDEN_IO = Pattern.compile(
            "(?i)(?:^|[;\\s])(?:load|call|save|cd)\\b|\\bset\\s+(?:output|terminal|print)\\b");
    private static final Pattern BACKTICK_ESCAPE = Pattern.compile("`");
    // Accept a plot command at the start of a line or after a Gnuplot semicolon command separator.
    // This permits safe setup + plot scripts such as "set grid; plot sin(x)" while still requiring
    // an actual plot/splot command in the submitted request.
    private static final Pattern PLOT_COMMAND = Pattern.compile("(?im)(?:^|;)\\s*(?:plot|splot)\\b");
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
        if (BACKTICK_ESCAPE.matcher(normalized).find()) {
            throw new ExternalComputeException(Code.COMMAND_REJECTED,
                    "Gnuplot backtick command substitution is blocked");
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
        PreparedPlot plot = createPlotRequest(validatedCommand, context);
        return request(executable, executableArguments(), plot.stdin(), plot.artifact(), plot.artifactDirectory());
    }

    /** Package-visible request builder so the host-owned output policy can be verified without launching Gnuplot. */
    static PreparedPlot createPlotRequest(String validatedCommand, ComputeContext context)
            throws ExternalComputeException {
        try {
            Path root = context.tempDirectory().toAbsolutePath().normalize();
            Files.createDirectories(root);
            Path artifactDirectory = Files.createTempDirectory(root, "algogebra-gnuplot-");
            Path artifact = artifactDirectory.resolve("plot.png");
            String quotedOutput = quoteGnuplotPath(artifact);
            // EE-12: host-owned header uses pngcairo; student commands cannot override terminal/output.
            String script = "set terminal pngcairo size " + context.plotWidth() + "," + context.plotHeight() + "\n"
                    + "set output \"" + quotedOutput + "\"\n"
                    + validatedCommand + "\n"
                    + "unset output\n"
                    + "exit\n";
            return new PreparedPlot(script, artifact, artifactDirectory);
        } catch (IOException failure) {
            throw new ExternalComputeException(Code.PROCESS_START_FAILED,
                    "Could not create Gnuplot output directory: " + failure.getMessage(), failure);
        }
    }

    record PreparedPlot(String stdin, Path artifact, Path artifactDirectory) {
    }

    @Override
    protected ComputeResult createResult(Request request, ProcessOutput output, Duration elapsed)
            throws ExternalComputeException {
        Path png = request.artifact();
        requirePngArtifact(png);
        try {
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

    static void requirePngArtifact(Path png) throws ExternalComputeException {
        if (png == null || !Files.isRegularFile(png)) {
            throw new ExternalComputeException(Code.INVALID_OUTPUT,
                    "Gnuplot exited successfully but did not produce a PNG file");
        }
        try {
            if (Files.size(png) < 24) {
                throw new ExternalComputeException(Code.INVALID_OUTPUT,
                        "Gnuplot exited successfully but did not produce a PNG file");
            }
        } catch (IOException failure) {
            throw new ExternalComputeException(Code.INVALID_OUTPUT,
                    "Could not inspect Gnuplot output file: " + failure.getMessage(), failure);
        }
    }

    private static String quoteGnuplotPath(Path output) {
        return output.toString().replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static boolean isWindows() {
        return System.getProperty("os.name", "").toLowerCase(Locale.ROOT).startsWith("windows");
    }
}
