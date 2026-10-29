package org.geogebra.plus.engine.gnuplot;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;

import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;

public final class GnuplotEngineTests {

    private GnuplotEngineTests() {
    }

    public static void run() throws Exception {
        GnuplotEngine engine = new GnuplotEngine();
        assertRejected(engine, "!echo nope", "! prefix filter");
        assertRejected(engine, "plot sin(x); !echo nope", "inline ! prefix filter");
        assertRejected(engine, "plot system(\"calc\")", "system filter");
        assertRejected(engine, "plot sin(x); set output \"other.png\"", "output redirection filter");

        if (!engine.isAvailable()) {
            try {
                engine.eval("plot sin(x)", ComputeContext.defaults());
                throw new AssertionError("Gnuplot should be unavailable");
            } catch (ExternalComputeException expected) {
                assertTrue(expected.code() == Code.ENGINE_UNAVAILABLE,
                        "missing Gnuplot binary must be an error, not a fallback");
            }
            System.out.println("SKIP: Gnuplot PNG acceptance; gnuplot is not on PATH (missing binary correctly errors)");
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
            System.out.println("PASS: Gnuplot produced a valid " + width + "x" + height + " PNG");
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
