package org.geogebra.plus.engine.pari;

import java.time.Duration;

import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;

public final class PariEngineTests {

    private static final String[] EXPECTED_WIMS_ILLPART = { "plot", "write", "help" };
    private static final String[] EXPECTED_AGB_ILLEGAL = {
            "system", "extern", "externstr", "fileextern", "install", "eval"
    };

    private PariEngineTests() {
    }

    public static void run() throws Exception {
        String fixture = "? factor(2^64-1)\n%1 = [3, 1; 5, 1; 17, 1; 257, 1; 641, 1; 65537, 1; 6700417, 1]\n"
                + "? quit\nGood bye!\n";
        String parsed = PariGPEngine.parseOutput(fixture);
        for (String row : new String[] { "3, 1", "5, 1", "17, 1", "257, 1", "641, 1", "65537, 1", "6700417, 1" }) {
            assertTrue(parsed.contains(row), "PARI parser missed factor row " + row + ": " + parsed);
        }
        assertTrue(PariGPEngine.parseOutput("? x\n%1 = 1.2300\n? quit\nGood bye!\n").equals("1.23"),
                "PARI parser should strip trailing decimal zeros");
        testAlgoGebraForbiddenCommands();
        testWimsForbiddenTermsAndEscapes();
        testWholeWordAndDynamicNameFilters();
        testEmptySuccessfulOutputRejected();

        PariGPEngine engine = new PariGPEngine();
        if (!engine.isAvailable()) {
            expectUnavailable(() -> engine.eval("factor(2^64-1)", ComputeContext.defaults()), "gp/gp.exe");
            System.out.println("SKIP: PARI factorization acceptance; gp/gp.exe is not on PATH (missing binary correctly errors)");
            return;
        }
        try (ComputeResult result = engine.eval("factor(2^64-1)", new ComputeContext(
                Duration.ofSeconds(60), 20, 8, 1, 800, 600,
                java.nio.file.Path.of(System.getProperty("java.io.tmpdir"))))) {
            assertFactorization(result.text());
            System.out.println("PASS: PARI factor(2^64-1) = " + result.text());
        }
        // BUG-015 / T-PARI empty-output: malformed input must not return successful empty text.
        try {
            engine.eval("factor((", new ComputeContext(
                    Duration.ofSeconds(60), 20, 8, 1, 800, 600,
                    java.nio.file.Path.of(System.getProperty("java.io.tmpdir"))));
            throw new AssertionError("BUG-015: malformed PARI input should not succeed");
        } catch (ExternalComputeException expected) {
            assertTrue(expected.code() == Code.INVALID_OUTPUT || expected.code() == Code.PROCESS_FAILED,
                    "BUG-015 expected INVALID_OUTPUT/PROCESS_FAILED, got " + expected.code());
            System.out.println("PASS: BUG-015 malformed factor(( -> " + expected.code());
        }
    }

    private static void testAlgoGebraForbiddenCommands() throws Exception {
        PariGPEngine engine = new PariGPEngine();
        // BUG-006: validateCommand runs before executable lookup; COMMAND_REJECTED proves gp is never reached.
        assertTrue(java.util.Arrays.equals(PariGPEngine.AGB_ILLEGAL, EXPECTED_AGB_ILLEGAL),
                "T-PARI-01 AGB_ILLEGAL list differs from the approved six-command filter");
        for (String blocked : EXPECTED_AGB_ILLEGAL) {
            assertRejected(engine, blocked + "(\"test\")", "T-PARI-01 AGB_ILLEGAL: " + blocked);
        }
        System.out.println("PASS: T-PARI-01 all AGB_ILLEGAL commands rejected before gp launch");

        assertRejected(engine, "alias(s,system); s(\"id\")", "T-PARI-02 alias to system");
        assertRejected(engine, "SYSTEM(\"id\")", "T-PARI-02 case-insensitive command");
        System.out.println("PASS: T-PARI-02 alias and case variants are rejected");

        assertRejected(engine, "1+1\n  system (\"id\")", "T-PARI-03 multiline/indented command");
        System.out.println("PASS: T-PARI-03 multiline command injection is rejected");
    }

    private static void testWimsForbiddenTermsAndEscapes() throws Exception {
        PariGPEngine engine = new PariGPEngine();
        assertTrue(java.util.Arrays.equals(PariGPEngine.WIMS_ILLPART, EXPECTED_WIMS_ILLPART),
                "T-PARI-04 PARI WIMS_ILLPART list changed unexpectedly");
        for (String blocked : EXPECTED_WIMS_ILLPART) {
            assertRejected(engine, blocked + "(sin(x))", "T-PARI-04 WIMS illpart: " + blocked);
        }
        assertRejected(engine, "2+2\n\\quit", "T-PARI-04 GP escape-command filter");
        assertRejected(engine, "\\quit", "T-PARI-04 leading GP escape-command filter");
        System.out.println("PASS: T-PARI-04 WIMS denied terms and GP escape commands are rejected");
    }

    private static void testWholeWordAndDynamicNameFilters() throws Exception {
        PariGPEngine engine = new PariGPEngine();
        assertRejected(engine, "eval(Str(\"ins\",\"tall(\\\"getpid\\\",\\\"l\\\")\"))",
                "T-PARI-05 dynamic reconstruction via eval");
        String safe = engine.validateCommand("systematic=1; installed=2; externality=3; evaluate=4");
        assertTrue(safe.contains("systematic"), "T-PARI-05 filter must match whole words only");
        System.out.println("PASS: T-PARI-05 dynamic reconstruction rejected; longer identifiers remain allowed");
    }

    private static void testEmptySuccessfulOutputRejected() throws Exception {
        PariGPEngine engine = new PariGPEngine();
        assertTrue(engine.validateCommand("1+1").equals("1+1"), "T-PARI-06 fixture must be valid input");
        assertInvalidOutput(() -> PariGPEngine.requireNonEmptyOutput(""), "empty PARI payload");
        assertInvalidOutput(() -> PariGPEngine.requireNonEmptyOutput(" \r\n\t"), "whitespace-only PARI payload");
        System.out.println("PASS: T-PARI-06 valid request with empty successful output returns INVALID_OUTPUT");
    }

    private static void assertFactorization(String value) {
        java.util.Map<String, String> factors = new java.util.LinkedHashMap<>();
        java.util.regex.Matcher rows = java.util.regex.Pattern
                .compile("(?<!\\d)(\\d+)\\s*[,;\\s]+\\s*(\\d+)(?!\\d)")
                .matcher(value);
        while (rows.find()) {
            factors.put(rows.group(1), rows.group(2));
        }
        java.util.Map<String, String> expected = java.util.Map.of(
                "3", "1", "5", "1", "17", "1", "257", "1", "641", "1", "65537", "1", "6700417", "1");
        assertTrue(factors.equals(expected), "Incorrect PARI factorization rows: " + value + " -> " + factors);
    }

    private static void assertRejected(PariGPEngine engine, String command, String label) throws Exception {
        try {
            engine.eval(command, ComputeContext.defaults());
            throw new AssertionError(label + " should reject the request");
        } catch (ExternalComputeException expected) {
            assertTrue(expected.code() == Code.COMMAND_REJECTED, label + " returned " + expected.code());
        }
    }

    private static void expectUnavailable(CheckedRunnable call, String label) throws Exception {
        try {
            call.run();
            throw new AssertionError(label + " should be unavailable");
        } catch (ExternalComputeException expected) {
            assertTrue(expected.code() == Code.ENGINE_UNAVAILABLE, "missing binary must be an error, not fallback");
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
