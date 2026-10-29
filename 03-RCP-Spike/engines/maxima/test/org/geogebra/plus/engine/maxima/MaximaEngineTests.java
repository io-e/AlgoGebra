package org.geogebra.plus.engine.maxima;

import java.nio.file.Path;
import java.time.Duration;

import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;

public final class MaximaEngineTests {

    private MaximaEngineTests() {
    }

    public static void run() throws Exception {
        String fixture = "Maxima 5.47.0\n(%i1) diff(sin(x^2), x)\n(%o1) 2*x*cos(x^2)\n(%i2) quit();\n";
        assertTrue(MaximaEngine.parseOutput(fixture).equals("2*x*cos(x^2)"),
                "Maxima output parser should strip prompts and preserve the derivative");
        String multiple = "(%i1) 2+2; 3+3;\n(%o1) 4\n(%o2) 6\n(%i2) quit();\n";
        assertTrue(MaximaEngine.parseOutput(multiple).equals("4\n6"),
                "Maxima parser should preserve multiple output prompts in one request");
        assertTrue(MaximaEngine.parseOutput("(%i1) x;\n(%o1) 1.23b-4\n(%i2) quit();\n")
                .equals("1.23E-4"), "Maxima parser should normalize b-exponents");
        assertTrue(MaximaEngine.parseOutput("(%i1) [X, x];\n(%o1) [X, x]\n(%i2) quit();\n")
                .equals("X, x"), "Maxima parser must preserve case-sensitive symbol names");
        assertRejected(new MaximaEngine(), "system(\"calc\")", "system filter");
        assertRejected(new MaximaEngine(), "plot2d(sin(x),[x,-1,1])", "plot filter");

        MaximaEngine engine = new MaximaEngine();
        if (!engine.isAvailable()) {
            expectUnavailable(() -> engine.eval("diff(sin(x^2), x)", ComputeContext.defaults()));
            System.out.println("SKIP: Maxima derivative acceptance; maxima/maxima.bat is not on PATH (missing binary correctly errors)");
            return;
        }
        try (ComputeResult result = engine.eval("diff(sin(x^2), x)", new ComputeContext(
                Duration.ofSeconds(60), 20, 8, 1, 800, 600,
                Path.of(System.getProperty("java.io.tmpdir"))))) {
            String normalized = result.text().replaceAll("\\s+", "").toLowerCase(java.util.Locale.ROOT);
            assertTrue(normalized.equals("2*x*cos(x^2)"), "Unexpected Maxima derivative: " + result.text());
            System.out.println("PASS: Maxima derivative = " + result.text());
        }
    }

    private static void assertRejected(MaximaEngine engine, String command, String label) throws Exception {
        try {
            engine.eval(command, ComputeContext.defaults());
            throw new AssertionError(label + " should reject the request");
        } catch (ExternalComputeException expected) {
            assertTrue(expected.code() == Code.COMMAND_REJECTED, label + " returned " + expected.code());
        }
    }

    private static void expectUnavailable(CheckedRunnable call) throws Exception {
        try {
            call.run();
            throw new AssertionError("Maxima should be unavailable");
        } catch (ExternalComputeException expected) {
            assertTrue(expected.code() == Code.ENGINE_UNAVAILABLE,
                    "missing Maxima binary must be an error, not a fallback");
        }
    }

    private static void assertTrue(boolean condition, String message) {
        if (!condition) {
            throw new AssertionError(message);
        }
    }

    @FunctionalInterface
    private interface CheckedRunnable {
        void run() throws Exception;
    }
}
