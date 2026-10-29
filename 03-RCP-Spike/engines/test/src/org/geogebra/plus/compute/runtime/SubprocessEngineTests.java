package org.geogebra.plus.compute.runtime;

import java.nio.file.Path;
import java.time.Duration;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.geogebra.plus.compute.api.ComputeCapability;
import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;

/** Focused tests for pipes, PATH discovery, and process timeout/kill behavior. */
public final class SubprocessEngineTests {

    private SubprocessEngineTests() {
    }

    public static void run() throws Exception {
        testPathDiscovery();
        testPipesAndTimeout();
        testWimsMarkerExtraction();
    }

    /** BUG-001/BUG-002 (GROK_V1): WIMS common.c readresult() marker extraction. */
    private static void testWimsMarkerExtraction() {
        SubprocessEngine.WimsMarkers m = new SubprocessEngine.WimsMarkers(
                "Start line pari 1 2 3 4", "End line pari 1 2 3 4");
        // 1. header noise before the start marker is discarded (gp echo mode: prompt echoes carry the markers)
        String gp = "I\n2.718\n2.718\n? print(\"Start line pari 1 2 3 4\")\nStart line pari 1 2 3 4\n"
                + "? factor(2^64-1)\n[3,1;5,1]\n? print(\"End line pari 1 2 3 4\")\nEnd line pari 1 2 3 4\n";
        String slice = SubprocessEngine.extractBetweenMarkers(gp, m);
        assertTrue(slice != null && slice.equals("\n? factor(2^64-1)\n[3,1;5,1]"),
                "Header noise / echoed markers must be dropped: [" + slice + "]");
        // 2. Maxima style, quoted string output and CRLF
        String mx = "(%o1) 20\r\n(%o2) \"Start line pari 1 2 3 4\"\r\n(%o3) 2*x*cos(x^2)\r\n(%o4) \"End line pari 1 2 3 4\"\r\n";
        slice = SubprocessEngine.extractBetweenMarkers(mx, m);
        assertTrue(slice != null && slice.equals("\"\n(%o3) 2*x*cos(x^2)"), "Maxima slice: [" + slice + "]");
        // 3. marker-like text with another random suffix in output is kept as data
        String fake = "Start line pari 1 2 3 4\nStart line pari 9 9 9 9 is data\nEnd line pari 1 2 3 4\n";
        slice = SubprocessEngine.extractBetweenMarkers(fake, m);
        assertTrue(slice != null && slice.contains("Start line pari 9 9 9 9 is data"), "Foreign marker text kept: [" + slice + "]");
        // 4. the LAST start marker wins (WIMS while(strstr(p,startstring)))
        String twice = "Start line pari 1 2 3 4\nnoise\nStart line pari 1 2 3 4\n42\nEnd line pari 1 2 3 4";
        slice = SubprocessEngine.extractBetweenMarkers(twice, m);
        assertTrue(slice != null && slice.strip().equals("42"), "Last start marker must win: [" + slice + "]");
        // 5. no end marker (killed / timeout / crash) -> null => engine reports execution error or time out
        assertTrue(SubprocessEngine.extractBetweenMarkers("Start line pari 1 2 3 4\npartial", m) == null,
                "Missing end marker must yield null");
        assertTrue(SubprocessEngine.extractBetweenMarkers("no markers at all", m) == null,
                "Missing start marker must yield null");
        // 6. random markers are unique per call and wrap() follows putparm()
        SubprocessEngine.WimsMarkers a = SubprocessEngine.newMarkers("pari");
        SubprocessEngine.WimsMarkers b = SubprocessEngine.newMarkers("pari");
        assertTrue(!a.start().equals(b.start()) && a.start().startsWith("Start line pari ")
                && a.end().equals(a.start().replace("Start", "End")), "Marker generation");
        String wrapped = SubprocessEngine.wrapWithMarkers("1+1", m, "print(\"%s\")\n");
        assertTrue(wrapped.equals("print(\"Start line pari 1 2 3 4\")\n1+1\nprint(\"End line pari 1 2 3 4\")\n"),
                "putparm wrapping: [" + wrapped + "]");
        System.out.println("PASS: WIMS start/end marker extraction (header noise, CRLF, foreign markers, last start, missing end)");
    }

    private static void testPathDiscovery() throws Exception {
        Path directory = java.nio.file.Files.createTempDirectory("ggbplus-path-test-");
        try {
            Path executable = directory.resolve(isWindows() ? "mockgp.exe" : "mockgp");
            java.nio.file.Files.writeString(executable, "test");
            if (!isWindows()) {
                executable.toFile().setExecutable(true);
            }
            java.util.Map<String, String> environment = isWindows()
                    ? java.util.Map.of("Path", directory.toString(), "PathExt", ".EXE;.BAT")
                    : java.util.Map.of("PATH", directory.toString());
            Optional<Path> resolved = ExecutableResolver.resolveOnPath(List.of("mockgp"), environment, isWindows());
            assertTrue(resolved.isPresent(), "PATH resolver should find a candidate with PATHEXT support");
            if (isWindows()) {
                List<String> batchCommand = ExecutableResolver.command(directory.resolve("mock maxima.bat"),
                        List.of("--quiet"), true,
                        java.util.Map.of("ComSpec", "C:\\Windows\\System32\\cmd.exe"));
                assertTrue(batchCommand.size() == 5 && batchCommand.get(1).equals("/d")
                        && batchCommand.get(2).equals("/s") && batchCommand.get(4).contains("mock maxima.bat"),
                        "Windows .bat executables should be wrapped with cmd.exe quoting");
            }
        } finally {
            java.nio.file.Files.deleteIfExists(directory.resolve(isWindows() ? "mockgp.exe" : "mockgp"));
            java.nio.file.Files.deleteIfExists(directory);
        }
        System.out.println("PASS: PATH discovery (including Windows PATHEXT)");
    }

    private static void testPipesAndTimeout() throws Exception {
        ProbeEngine probe = new ProbeEngine();
        List<String> echoCommand;
        List<String> sleepCommand;
        if (isWindows()) {
            Path commandProcessor = Path.of(System.getenv("SystemRoot"), "System32", "cmd.exe");
            assertTrue(java.nio.file.Files.isRegularFile(commandProcessor), "Windows cmd.exe is required for tests");
            echoCommand = List.of(commandProcessor.toString(), "/d", "/c", "more");
            sleepCommand = List.of(commandProcessor.toString(), "/d", "/c", "ping 127.0.0.1 -n 6 > nul");
        } else {
            echoCommand = List.of("/bin/sh", "-c", "cat");
            sleepCommand = List.of("/bin/sh", "-c", "sleep 5");
        }
        String input = "pipe-ok\n";
        SubprocessEngine.ProcessOutput echoed = probe.run(echoCommand, input, Duration.ofSeconds(5));
        assertTrue(echoed.exitCode() == 0 && echoed.stdout().contains("pipe-ok"),
                "stdin and stdout pipes should round-trip a marker");
        try {
            probe.run(sleepCommand, "", Duration.ofMillis(250));
            throw new AssertionError("A process exceeding its timeout must be killed");
        } catch (ExternalComputeException expected) {
            assertTrue(expected.code() == Code.PROCESS_TIMEOUT, "timeout should report PROCESS_TIMEOUT");
        }
        System.out.println("PASS: ProcessBuilder pipes and timeout/process-tree kill");
    }

    private static boolean isWindows() {
        return System.getProperty("os.name", "").toLowerCase(java.util.Locale.ROOT).contains("win");
    }

    private static void assertTrue(boolean condition, String message) {
        if (!condition) {
            throw new AssertionError(message);
        }
    }

    private static final class ProbeEngine extends SubprocessEngine {

        @Override
        public String getEngineId() {
            return "probe";
        }

        @Override
        public Set<ComputeCapability> getCapabilities() {
            return Set.of(ComputeCapability.SYMBOLIC_MATH);
        }

        @Override
        protected List<String> executableCandidates() {
            return List.of("powershell.exe");
        }

        @Override
        protected String validateCommand(String command) {
            return command;
        }

        @Override
        protected Request prepareRequest(Path executable, String command, ComputeContext context) {
            return request(executable, List.of(), command, null, null);
        }

        @Override
        protected ComputeResult createResult(Request request, ProcessOutput output, Duration elapsed) {
            return ComputeResult.text(getEngineId(), output.stdout(), elapsed);
        }

        private ProcessOutput run(List<String> command, String stdin, Duration timeout)
                throws ExternalComputeException, java.io.IOException {
            return runProcess(command, stdin, timeout);
        }
    }
}
