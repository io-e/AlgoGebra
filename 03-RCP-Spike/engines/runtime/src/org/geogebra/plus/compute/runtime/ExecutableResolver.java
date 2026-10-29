package org.geogebra.plus.compute.runtime;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/** Resolves a named executable from PATH; it never installs or substitutes one. */
public final class ExecutableResolver {

    private ExecutableResolver() {
    }

    public static Optional<Path> resolveOnPath(List<String> candidates) {
        return resolveOnPath(candidates, System.getenv(), isWindows());
    }

    /** Exposed for deterministic tests that provide a synthetic PATH. */
    public static Optional<Path> resolveOnPath(List<String> candidates,
            Map<String, String> environment, boolean windows) {
        String pathValue = environmentValue(environment, "PATH", "");
        String pathExt = environmentValue(environment, "PATHEXT", ".COM;.EXE;.BAT;.CMD");
        String separator = windows ? ";" : java.io.File.pathSeparator;
        List<String> extensions = windows ? parseExtensions(pathExt) : List.of("");
        for (String directoryEntry : pathValue.split(java.util.regex.Pattern.quote(separator))) {
            String directoryText = directoryEntry.strip().replaceAll("^\"|\"$", "");
            if (directoryText.isEmpty()) {
                continue;
            }
            Path directory;
            try {
                directory = Path.of(directoryText);
            } catch (RuntimeException invalidPath) {
                continue;
            }
            for (String candidate : candidates) {
                if (candidate == null || candidate.isBlank() || Path.of(candidate).getNameCount() != 1) {
                    continue;
                }
                List<String> fileNames = new ArrayList<>();
                fileNames.add(candidate);
                if (windows && !hasExtension(candidate)) {
                    for (String extension : extensions) {
                        fileNames.add(candidate + extension);
                    }
                }
                for (String fileName : fileNames) {
                    Path file = directory.resolve(fileName);
                    if (Files.isRegularFile(file) && (windows || Files.isExecutable(file))) {
                        return Optional.of(file.toAbsolutePath().normalize());
                    }
                }
            }
        }
        return Optional.empty();
    }

    /** Builds a direct ProcessBuilder command, wrapping only Windows batch files. */
    public static List<String> command(Path executable, List<String> arguments, boolean windows,
            Map<String, String> environment) {
        String fileName = executable.getFileName().toString().toLowerCase(Locale.ROOT);
        boolean batch = windows && (fileName.endsWith(".bat") || fileName.endsWith(".cmd"));
        if (!batch) {
            List<String> result = new ArrayList<>();
            result.add(executable.toString());
            result.addAll(arguments);
            return List.copyOf(result);
        }
        String commandProcessor = environmentValue(environment, "ComSpec", "cmd.exe");
        StringBuilder commandLine = new StringBuilder("call ").append(quoteCmd(executable.toString()));
        for (String argument : arguments) {
            commandLine.append(' ').append(quoteCmd(argument));
        }
        // cmd /s /c requires the command text to be enclosed in a pair of quotes.
        String wrappedCommand = '"' + commandLine.toString() + '"';
        return List.of(commandProcessor, "/d", "/s", "/c", wrappedCommand);
    }

    private static List<String> parseExtensions(String pathExt) {
        List<String> extensions = new ArrayList<>();
        for (String extension : pathExt.split(";")) {
            String normalized = extension.strip();
            if (!normalized.isEmpty()) {
                extensions.add(normalized.startsWith(".") ? normalized : "." + normalized);
            }
        }
        return extensions.isEmpty() ? List.of(".COM", ".EXE", ".BAT", ".CMD")
                : List.copyOf(extensions);
    }

    private static boolean hasExtension(String candidate) {
        int separator = Math.max(candidate.lastIndexOf('/'), candidate.lastIndexOf('\\'));
        return candidate.lastIndexOf('.') > separator;
    }

    private static String environmentValue(Map<String, String> environment, String name, String fallback) {
        for (Map.Entry<String, String> entry : environment.entrySet()) {
            if (entry.getKey().equalsIgnoreCase(name)) {
                return entry.getValue();
            }
        }
        return fallback;
    }

    private static String quoteCmd(String value) {
        return '"' + value.replace("\"", "\"\"") + '"';
    }

    private static boolean isWindows() {
        return System.getProperty("os.name", "").toLowerCase(Locale.ROOT).startsWith("windows");
    }
}
