package org.geogebra.plus.engine.pari;

import java.time.Duration;

import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;

public final class PariEngineTests {

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
        assertRejected(new PariGPEngine(), "plot(sin(x))", "WIMS plot filter");
        assertRejected(new PariGPEngine(), "2+2\n\\quit", "GP escape-command filter");
        assertRejected(new PariGPEngine(), "\\quit", "leading GP escape-command filter");

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
