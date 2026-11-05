package org.geogebra.plus.compute.runtime;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.List;

/** Child-process fixture used to prove that a subprocess timeout also kills descendants. */
public final class SubprocessEngineTestChild {

    private SubprocessEngineTestChild() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            throw new IllegalArgumentException("Expected mode, PID file, and completion marker");
        }
        Path pidFile = Path.of(args[1]);
        Path markerFile = Path.of(args[2]);
        if (args[0].equals("child")) {
            Files.writeString(pidFile, Long.toString(ProcessHandle.current().pid()));
            Thread.sleep(Duration.ofSeconds(30));
            Files.writeString(markerFile, "child survived the parent timeout");
            return;
        }
        if (args[0].equals("parent")) {
            String javaExecutable = Path.of(System.getProperty("java.home"), "bin",
                    System.getProperty("os.name", "").toLowerCase(java.util.Locale.ROOT).contains("win")
                            ? "java.exe" : "java").toString();
            Process child = new ProcessBuilder(javaExecutable, "-cp", System.getProperty("java.class.path"),
                    SubprocessEngineTestChild.class.getName(), "child", pidFile.toString(), markerFile.toString())
                    .inheritIO().start();
            child.waitFor();
            return;
        }
        throw new IllegalArgumentException("Unknown helper mode: " + args[0]);
    }
}
