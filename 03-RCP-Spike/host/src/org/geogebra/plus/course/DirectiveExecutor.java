package org.geogebra.plus.course;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.InvalidPathException;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Locale;
import java.util.function.BiConsumer;

import javax.swing.SwingUtilities;

import org.eclipse.swt.widgets.Display;
import org.geogebra.common.main.App;
import org.geogebra.common.plugin.GgbAPI;
import org.geogebra.plus.course.CourseAction.Directive;
import org.geogebra.plus.course.CourseAction.Target;
import org.geogebra.plus.course.CourseNode.Check;
import org.geogebra.plus.course.CourseNode.Kind;

/** Executes trusted course directives without blocking either UI event thread. */
public final class DirectiveExecutor {

    private final Display display;
    private final Path courseDirectory;
    private final GgbAPI api2d;
    private final GgbAPI api3d;
    private final App app2d;
    private final App app3d;
    private final StepValidator validator = new StepValidator();

    public DirectiveExecutor(Display display, Path courseFile,
            GgbAPI api2d, GgbAPI api3d, App app2d, App app3d) throws IOException {
        this.display = display;
        this.courseDirectory = courseFile.toRealPath().getParent();
        this.api2d = api2d;
        this.api3d = api3d;
        this.app2d = app2d;
        this.app3d = app3d;
    }

    public void runAsync(CourseNode step, BiConsumer<Boolean, String> completion) {
        if (step == null || step.kind() != Kind.STEP) {
            complete(completion, false, "Select a course step first.");
            return;
        }
        SwingUtilities.invokeLater(() -> {
            List<GgbAPI> dialogsDisabled = new ArrayList<>(2);
            try {
                disableErrorDialogs(api2d, dialogsDisabled);
                if (api3d != api2d) {
                    disableErrorDialogs(api3d, dialogsDisabled);
                }
                List<String> results = new ArrayList<>();
                for (CourseAction action : step.actions()) {
                    results.add(execute(action));
                }
                String message = results.isEmpty() ? "This step has no actions." : String.join("; ", results);
                complete(completion, true, message);
            } catch (Throwable error) {
                complete(completion, false, message(error));
            } finally {
                for (GgbAPI api : dialogsDisabled) {
                    try {
                        setErrorDialogsActive(api, true);
                    } catch (Exception restoreError) {
                        System.err.println("[GeoGebraPlus] Could not restore GeoGebra error dialogs: "
                                + restoreError);
                    }
                }
            }
        });
    }

    public void checkAsync(CourseNode step, BiConsumer<Boolean, String> completion) {
        if (step == null || step.kind() != Kind.STEP || step.check() == null) {
            complete(completion, false, "The selected step has no check.");
            return;
        }
        SwingUtilities.invokeLater(() -> {
            try {
                Check check = step.check();
                GgbAPI api = apiFor(check.target());
                boolean passed = validator.check(check, api);
                String feedback = passed ? check.passFeedback() : check.failFeedback();
                if (feedback.isBlank()) {
                    feedback = passed ? "Check passed (formative only)." : "Check not passed yet.";
                }
                complete(completion, passed, feedback);
            } catch (Throwable error) {
                complete(completion, false, message(error));
            }
        });
    }

    private String execute(CourseAction action) throws Exception {
        GgbAPI api = apiFor(action.target());
        App app = appFor(action.target());
        return switch (action.directive()) {
        case CMD -> {
            validator.validateCommand(app, action.value());
            boolean labelReturned = api.evalCommand(action.value());
            yield labelReturned
                    ? "Command submitted; GeoGebra returned output labels"
                    : "Command submitted; no output labels returned (not treated as a failure)";
        }
        case CAS -> {
            validator.validateCommand(app, action.value());
            String result = api.evalCommandCAS(action.value(), null);
            yield "CAS: " + (result == null ? "(no result)" : result);
        }
        case VAL -> "Value: " + api.getValueString(requireObjectName(action.value()));
        case OPEN -> openTrustedGgb(api, action);
        case SAVE -> saveConstruction(api, action.value());
        case PNG -> exportPng(api, action.value());
        };
    }

    private String openTrustedGgb(GgbAPI api, CourseAction action) throws IOException {
        if (!action.trustedGgb()) {
            throw new SecurityException("OPEN is disabled for untrusted .ggb files until script scanning is available; "
                    + "teacher trust must be explicit.");
        }
        Path path = resolveInput(action.value(), ".ggb");
        byte[] bytes = Files.readAllBytes(path);
        api.setBase64(Base64.getEncoder().encodeToString(bytes));
        return "Opened trusted construction " + path.getFileName();
    }

    private String saveConstruction(GgbAPI api, String rawPath) throws IOException {
        Path target = resolveNewOutput(rawPath, ".ggb");
        byte[] bytes = Base64.getDecoder().decode(api.getBase64());
        Files.write(target, bytes, StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
        return "Saved construction " + target.getFileName();
    }

    private String exportPng(GgbAPI api, String rawPath) throws IOException {
        Path target = resolveNewOutput(rawPath, ".png");
        if (!api.writePNGtoFile(target.toString(), 1.0, false, 72.0, false)) {
            throw new IOException("GeoGebra could not export the PNG");
        }
        return "Exported " + target.getFileName();
    }

    private Path resolveInput(String rawPath, String extension) throws IOException {
        Path candidate = resolveRelativePath(rawPath, extension);
        Path real = candidate.toRealPath();
        if (!real.startsWith(courseDirectory) || !Files.isRegularFile(real)) {
            throw new SecurityException("Course input must be a regular file inside the course directory.");
        }
        return real;
    }

    private Path resolveNewOutput(String rawPath, String extension) throws IOException {
        Path candidate = resolveRelativePath(rawPath, extension);
        if (Files.exists(candidate)) {
            throw new IOException("Refusing to overwrite existing course output: " + candidate.getFileName());
        }
        Path parent = candidate.getParent();
        if (parent == null || !Files.isDirectory(parent)) {
            throw new IOException("Output directory must already exist inside the course directory.");
        }
        Path realParent = parent.toRealPath();
        if (!realParent.startsWith(courseDirectory)) {
            throw new SecurityException("Course output escapes the course directory.");
        }
        return realParent.resolve(candidate.getFileName()).normalize();
    }

    private Path resolveRelativePath(String rawPath, String extension) {
        if (rawPath == null || rawPath.isBlank()
                || rawPath.matches("(?i)^[a-z][a-z0-9+.-]*://.*")) {
            throw new SecurityException("Course file paths must be non-empty relative paths, not URLs.");
        }
        try {
            Path relative = Path.of(rawPath);
            if (relative.isAbsolute() || !relative.getFileName().toString().toLowerCase(Locale.ROOT)
                    .endsWith(extension)) {
                throw new SecurityException("Course file path must be relative and end with " + extension + ".");
            }
            Path candidate = courseDirectory.resolve(relative).normalize();
            if (!candidate.startsWith(courseDirectory)) {
                throw new SecurityException("Course file path escapes the course directory.");
            }
            return candidate;
        } catch (InvalidPathException error) {
            throw new SecurityException("Invalid course file path.", error);
        }
    }

    private static String requireObjectName(String value) {
        if (value == null || !value.matches("[\\p{L}][\\p{L}\\p{N}_]*")) {
            throw new SecurityException("VAL requires a single GeoGebra object name.");
        }
        return value;
    }

    private GgbAPI apiFor(Target target) {
        GgbAPI api = target == Target.THREE_D ? api3d : api2d;
        if (api == null) {
            throw new IllegalStateException("The requested GeoGebra " + target.jsonValue() + " API is unavailable.");
        }
        return api;
    }

    private App appFor(Target target) {
        App app = target == Target.THREE_D ? app3d : app2d;
        if (app == null) {
            throw new IllegalStateException("The requested GeoGebra " + target.jsonValue() + " app is unavailable.");
        }
        return app;
    }

    private static void disableErrorDialogs(GgbAPI api, List<GgbAPI> disabled) throws Exception {
        if (api == null) {
            return;
        }
        setErrorDialogsActive(api, false);
        disabled.add(api);
    }

    private static void setErrorDialogsActive(GgbAPI api, boolean active) throws Exception {
        api.getClass().getMethod("setErrorDialogsActive", boolean.class).invoke(api, active);
    }

    private void complete(BiConsumer<Boolean, String> completion, boolean success, String message) {
        if (completion == null) {
            return;
        }
        if (display.isDisposed()) {
            return;
        }
        display.asyncExec(() -> {
            if (!display.isDisposed()) {
                completion.accept(success, message);
            }
        });
    }

    private static String message(Throwable error) {
        Throwable root = error;
        while (root.getCause() != null && root.getCause() != root) {
            root = root.getCause();
        }
        String detail = root.getMessage();
        return detail == null || detail.isBlank() ? root.getClass().getSimpleName() : detail;
    }
}
