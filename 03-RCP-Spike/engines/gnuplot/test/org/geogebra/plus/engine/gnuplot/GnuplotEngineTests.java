package org.geogebra.plus.engine.gnuplot;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.List;

import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;

public final class GnuplotEngineTests {

    private GnuplotEngineTests() {
    }

    public static void run() throws Exception {
        GnuplotEngine engine = new GnuplotEngine();
        testHostOwnedOutputPath();
        testEmptyValidPlotRejected();
        testPlotAfterSemicolon();
        assertRejected(engine, "!echo nope", "! prefix filter");
        assertRejected(engine, "plot sin(x); !echo nope", "inline ! prefix filter");
        assertRejected(engine, "plot system(\"calc\")", "system filter");
        assertRejected(engine, "plot sin(x); set output \"other.png\"", "output redirection filter");
        assertRejected(engine, "plot sin(x); set print \"/tmp/evil.txt\"", "set print filter");
        assertRejected(engine, "plot sin(x); call \"evil.gp\"", "call filter");
        assertRejected(engine, "plot sin(x); load \"evil.gp\"", "load filter");
        assertRejected(engine, "plot `dir`", "T-GNU-03 backtick filter");
        System.out.println("PASS: T-GNU-03 backtick and shell/file redirection filters");

        if (!engine.isAvailable()) {
            try {
                engine.eval("plot sin(x)", ComputeContext.defaults());
                throw new AssertionError("Gnuplot should be unavailable");
            } catch (ExternalComputeException expected) {
                assertTrue(expected.code() == Code.ENGINE_UNAVAILABLE,
                        "missing Gnuplot binary must be an error, not a fallback");
            }
            System.out.println("SKIP: T-GNU-02 PNG magic-byte acceptance; gnuplot is not on PATH (missing binary correctly errors)");
            return;
        }

        try (ComputeResult result = engine.eval("plot sin(x)", new ComputeContext(
                Duration.ofSeconds(60), 20, 8, 1, 800, 600,
                Path.of(System.getProperty("java.io.tmpdir"))))) {
            Path png = result.artifact().orElseThrow(() -> new AssertionError("Gnuplot did not return a PNG"));
            byte[] header = Files.readAllBytes(png);
            byte[] signature = { (byte) 0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a };
            for (int i = 0; i < signature.length; i++) {
                assertTrue(header[i] == signature[i], "Gnuplot output has an invalid PNG signature");
            }
            int width = ByteBuffer.wrap(header, 16, 4).order(ByteOrder.BIG_ENDIAN).getInt();
            int height = ByteBuffer.wrap(header, 20, 4).order(ByteOrder.BIG_ENDIAN).getInt();
            assertTrue(width == 800 && height == 600,
                    "Gnuplot PNG dimensions were " + width + "x" + height);
            assertTrue(result.mediaType().orElse("").equals("image/png"), "Gnuplot result media type mismatch");
            result.close();
            assertTrue(!Files.exists(png), "Closing a plot result should delete the temporary PNG");
            System.out.println("PASS: T-GNU-02 Gnuplot produced a valid " + width + "x" + height + " PNG magic bytes");
        }
    }

    private static void testPlotAfterSemicolon() throws Exception {
        GnuplotEngine engine = new GnuplotEngine();
        for (String command : List.of(
                "set xrange [0:1]; plot x",
                "set grid; plot sin(x)",
                "set samples 50; plot sin(x)",
                "set key left; plot sin(x), cos(x)")) {
            assertTrue(engine.validateCommand(command).equals(command),
                    "Gnuplot must accept setup commands followed by plot after ';': " + command);
        }
        try {
            engine.validateCommand("set grid; print 1");
            throw new AssertionError("A request without plot/splot must be rejected");
        } catch (ExternalComputeException expected) {
            assertTrue(expected.code() == Code.INVALID_REQUEST,
                    "A request without plot/splot returned " + expected.code());
        }
        System.out.println("PASS: Gnuplot accepts setup + plot separated by semicolon; non-plot remains invalid");
    }

    private static void testHostOwnedOutputPath() throws Exception {
        Path tempRoot = Files.createTempDirectory("ggbplus-gnuplot-output-test-");
        Path hostOutputRoot = tempRoot.resolve("host-output");
        ComputeContext context = new ComputeContext(Duration.ofSeconds(5), 20, 8, 1, 640, 480, hostOutputRoot);
        GnuplotEngine.PreparedPlot request = GnuplotEngine.createPlotRequest("plot sin(x)", context);
        try {
            Path artifactDirectory = request.artifactDirectory().toAbsolutePath().normalize();
            Path artifact = request.artifact().toAbsolutePath().normalize();
            assertTrue(artifactDirectory.startsWith(hostOutputRoot.toAbsolutePath().normalize()),
                    "T-GNU-01 output directory must be contained in the host-selected temp root");
            assertTrue(artifact.equals(artifactDirectory.resolve("plot.png")),
                    "T-GNU-01 host must choose the fixed plot.png artifact path");
            String[] lines = request.stdin().split("\\R");
            List<String> outputLines = java.util.Arrays.stream(lines)
                    .filter(line -> line.stripLeading().toLowerCase(java.util.Locale.ROOT).startsWith("set output "))
                    .toList();
            String expectedPath = artifact.toString().replace("\\", "\\\\").replace("\"", "\\\"");
            assertTrue(outputLines.equals(List.of("set output \"" + expectedPath + "\"")),
                    "T-GNU-01 script must contain exactly one host-forced output path: " + outputLines);
            assertTrue(request.stdin().startsWith("set terminal pngcairo size 640,480\n"),
                    "T-GNU-01 host must force the PNG terminal and requested dimensions");
        } finally {
            Files.deleteIfExists(request.artifact());
            Files.deleteIfExists(request.artifactDirectory());
            Files.deleteIfExists(hostOutputRoot);
            Files.deleteIfExists(tempRoot);
        }
        System.out.println("PASS: T-GNU-01 host forces isolated output path and pngcairo terminal");
    }

    private static void testEmptyValidPlotRejected() throws Exception {
        GnuplotEngine engine = new GnuplotEngine();
        assertTrue(engine.validateCommand("plot sin(x)").equals("plot sin(x)"),
                "T-GNU-04 fixture must be valid plot input");
        Path temp = Files.createTempDirectory("ggbplus-gnuplot-empty-test-");
        Path missing = temp.resolve("plot.png");
        try {
            assertInvalidOutput(missing, "valid plot with no output artifact");
            Files.write(missing, new byte[] { 1, 2, 3 });
            assertInvalidOutput(missing, "valid plot with an empty/truncated output artifact");
        } finally {
            Files.deleteIfExists(missing);
            Files.deleteIfExists(temp);
        }
        System.out.println("PASS: T-GNU-04 valid plot with absent/empty output returns INVALID_OUTPUT");
    }

    private static void assertInvalidOutput(Path png, String label) throws Exception {
        try {
            GnuplotEngine.requirePngArtifact(png);
            throw new AssertionError(label + " should fail with INVALID_OUTPUT");
        } catch (ExternalComputeException expected) {
            assertTrue(expected.code() == Code.INVALID_OUTPUT,
                    label + " returned " + expected.code() + " instead of INVALID_OUTPUT");
        }
    }

    private static void assertRejected(GnuplotEngine engine, String command, String label) throws Exception {
        try {
            engine.eval(command, ComputeContext.defaults());
            throw new AssertionError(label + " should reject the request");
        } catch (ExternalComputeException expected) {
            assertTrue(expected.code() == Code.COMMAND_REJECTED, label + " returned " + expected.code());
        }
    }

    private static void assertTrue(boolean condition, String message) {
        if (!condition) {
            throw new AssertionError(message);
        }
    }
}
