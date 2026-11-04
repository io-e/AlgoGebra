package org.geogebra.plus.engine.maxima;

import java.nio.file.Path;
import java.time.Duration;

import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;

public final class MaximaEngineTests {

    private static final String[] EXPECTED_WIMS_ILLEGAL = {
            "system", "describe", "example", "save", "fassave", "stringout", "batcon",
            "batcount", "cursordisp", "direc", "readonly", "with_stdout", "pscom",
            "demo", "ttyintfun", "bug"
    };
    private static final String[] EXPECTED_WIMS_ILLPART = { "file", "debug", "plot", "load", "store", "batch" };

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
        testCompleteWimsFilter();
        testEmptySuccessfulOutputRejected();

        MaximaEngine engine = new MaximaEngine();
        if (!engine.isAvailable()) {
            expectUnavailable(() -> engine.eval("diff(sin(x^2), x)", ComputeContext.defaults()));
            System.out.println("SKIP: T-MAX-03 derivative acceptance; maxima/maxima.bat is not on PATH (missing binary correctly errors)");
            return;
        }
        try (ComputeResult result = engine.eval("diff(sin(x^2), x)", new ComputeContext(
                Duration.ofSeconds(60), 20, 8, 1, 800, 600,
                Path.of(System.getProperty("java.io.tmpdir"))))) {
            String normalized = result.text().replaceAll("\\s+", "").toLowerCase(java.util.Locale.ROOT);
            assertTrue(normalized.equals("2*x*cos(x^2)"), "Unexpected Maxima derivative: " + result.text());
            System.out.println("PASS: T-MAX-03 diff(sin(x^2),x) = " + result.text());
        }
    }

    private static void testCompleteWimsFilter() throws Exception {
        MaximaEngine engine = new MaximaEngine();
        assertTrue(java.util.Arrays.equals(MaximaEngine.WIMS_ILLEGAL, EXPECTED_WIMS_ILLEGAL),
                "T-MAX-01 WIMS_ILLEGAL list is incomplete or changed");
        for (String blocked : EXPECTED_WIMS_ILLEGAL) {
            assertRejected(engine, blocked + "(x)", "T-MAX-01 WIMS illegal: " + blocked);
        }
        assertRejected(engine, "SYSTEM(\"calc\")", "T-MAX-01 case-insensitive system filter");
        System.out.println("PASS: T-MAX-01 all WIMS_ILLEGAL commands rejected");

        assertTrue(java.util.Arrays.equals(MaximaEngine.WIMS_ILLPART, EXPECTED_WIMS_ILLPART),
                "T-MAX-02 WIMS_ILLPART list is incomplete or changed");
        for (String blocked : EXPECTED_WIMS_ILLPART) {
            assertRejected(engine, "x:" + blocked + "(x)", "T-MAX-02 WIMS illpart: " + blocked);
        }
        System.out.println("PASS: T-MAX-02 all WIMS_ILLPART terms rejected");
    }

    private static void testEmptySuccessfulOutputRejected() throws Exception {
        MaximaEngine engine = new MaximaEngine();
        assertTrue(engine.validateCommand("1+1").equals("1+1;"), "T-MAX-04 fixture must be valid input");
        assertInvalidOutput(() -> MaximaEngine.requireNonEmptyOutput(""), "empty Maxima payload");
        assertInvalidOutput(() -> MaximaEngine.requireNonEmptyOutput(" \r\n\t"),
                "whitespace-only Maxima payload");
        System.out.println("PASS: T-MAX-04 valid request with empty successful output returns INVALID_OUTPUT");
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

    private static void assertInvalidOutput(CheckedRunnable call, String label) throws Exception {
        try {
            call.run();
            throw new AssertionError(label + " should fail with INVALID_OUTPUT");
        } catch (ExternalComputeException expected) {
            assertTrue(expected.code() == Code.INVALID_OUTPUT,
                    label + " returned " + expected.code() + " instead of INVALID_OUTPUT");
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
