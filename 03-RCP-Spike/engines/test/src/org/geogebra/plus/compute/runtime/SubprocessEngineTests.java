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
