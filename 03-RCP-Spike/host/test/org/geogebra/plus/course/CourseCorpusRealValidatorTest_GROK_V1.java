package org.geogebra.plus.course;

import java.io.IOException;
import java.io.OutputStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import org.geogebra.common.main.App;
import org.geogebra.desktop.headless.AppDNoGui;
import org.geogebra.desktop.main.LocalizationD;

/**
 * GROK_V1 GeoGebra-backed corpus test: runs every validator/scanner case of the WP9-03 corpus
 * (tests/fixtures/course-security/corpus_manifest_GROK_V1.tsv) through the REAL product checks with a headless
 * GeoGebra kernel (AppDNoGui): CourseModel.load, StepValidator.validateCommand (post-parse walk: localized names,
 * nested commands, Sequence budget), StepValidator.validateOpen and DirectiveExecutor.resolveInput (OPEN path rules,
 * toRealPath), combined like DirectiveExecutor.validateStep (first REJECT wins, warnings collected).
 * Expected failures are listed in XFAIL with their tracking item; an XFAIL case that starts passing is reported as XPASS.
 * Usage: java ... CourseCorpusRealValidatorTest_GROK_V1 <corpus dir>. Output: TAP-like lines + summary; exit 1 on any FAIL.
 */
public final class CourseCorpusRealValidatorTest_GROK_V1 {

    /** No near-limit Sequence warning XFAILs remain after owner decision Q3b (issue #21). */
    static final Map<String, String> XFAIL = Map.of();

    private int pass, fail, xfail, xpass, n;

    public static void main(String[] args) throws Exception {
        int rc = new CourseCorpusRealValidatorTest_GROK_V1().run(Path.of(args.length > 0 ? args[0]
                : "03-RCP-Spike/tests/fixtures/course-security"));
        System.exit(rc);
    }

    int run(Path corpus) throws Exception {
        Path work = Files.createTempDirectory("grok-corpus-java");
        Path dir = prepare(corpus, work);
        App app = new AppDNoGui(new LocalizationD(3), false);
        for (String line : Files.readAllLines(corpus.resolve("corpus_manifest_GROK_V1.tsv"), StandardCharsets.UTF_8)) {
            if (line.isBlank() || line.startsWith("#") || line.startsWith("id\t")) {
                continue;
            }
            String[] f = line.split("\t", -1);
            if (!f[2].equals("validator") && !f[2].equals("scanner")) {
                continue;
            }
            String id = f[0], expected = f[4];
            Path course = id.equals("T-10") ? dir.resolve("T-10_big_GROK_V1.json") : dir.resolve(Path.of(f[1]).getFileName());
            String got = verdict(app, course);
            String token = got.split("\\s", 2)[0];
            boolean ok = token.equals(expected);
            n++;
            if (XFAIL.containsKey(id)) {
                if (ok) { xpass++; System.out.println("ok " + n + " - " + id + " # XPASS " + XFAIL.get(id) + " -> now " + got); }
                else { xfail++; System.out.println("not ok " + n + " - " + id + " # TODO XFAIL " + XFAIL.get(id) + " :: got '" + got + "' expected " + expected); }
            } else if (ok) {
                pass++; System.out.println("ok " + n + " - " + id + " :: " + got);
            } else {
                fail++; System.out.println("not ok " + n + " - " + id + " :: got '" + got + "' expected " + expected + " (" + f[5] + ")");
            }
        }
        System.out.println("CourseCorpusRealValidatorTest_GROK_V1: " + pass + " PASS, " + fail + " FAIL, " + xfail + " XFAIL, " + xpass + " XPASS");
        return fail == 0 ? 0 : 1;
    }

    /** Same combination as DirectiveExecutor.validateStep, plus resolveInput which the product runs when executing OPEN. */
    static String verdict(App app, Path course) {
        try {
            CourseModel model = CourseModel.load(course);
            StepValidator validator = new StepValidator();
            DirectiveExecutor executor = new DirectiveExecutor(null, course, null, null, null, null);
            Method resolve = DirectiveExecutor.class.getDeclaredMethod("resolveInput", String.class, String.class);
            resolve.setAccessible(true);
            List<String> warnings = new ArrayList<>();
            Deque<CourseNode> queue = new ArrayDeque<>(model.getTree());
            while (!queue.isEmpty()) {
                CourseNode node = queue.pop();
                if (node.children() != null) queue.addAll(node.children());
                if (node.actions() == null) continue;
                for (CourseAction action : node.actions()) {
                    CourseValidationResult r = switch (action.directive()) {
                    case CMD, CAS -> validator.validateCommand(app, action.value());
                    case OPEN -> validator.validateOpen(action);
                    default -> CourseValidationResult.accept();
                    };
                    if (!r.isAccepted()) return "REJECT " + r.message();
                    if (action.directive() == CourseAction.Directive.OPEN) {
                        try { resolve.invoke(executor, action.value(), ".ggb"); }
                        catch (InvocationTargetException e) { return "REJECT " + e.getCause(); }
                    }
                    warnings.addAll(r.warnings());
                }
            }
            return warnings.isEmpty() ? "ACCEPT" : "ACCEPT_WITH_WARNING " + String.join(" | ", warnings);
        } catch (Throwable t) {
            return "REJECT " + t.getClass().getSimpleName() + ": " + t.getMessage();
        }
    }

    /** Mirrors suite 16: courses, built .ggb archives, a symlink escaping the course dir, generated T-10 (>1 MB). */
    static Path prepare(Path corpus, Path work) throws IOException {
        Path dir = Files.createDirectories(work.resolve("course"));
        try (Stream<Path> s = Files.list(corpus.resolve("courses"))) {
            for (Path p : (Iterable<Path>) s::iterator) Files.copy(p, dir.resolve(p.getFileName()));
        }
        try (Stream<Path> s = Files.list(corpus.resolve("ggb-src"))) {
            for (Path src : (Iterable<Path>) s::iterator) {
                try (OutputStream out = Files.newOutputStream(dir.resolve(src.getFileName() + ".ggb"));
                        ZipOutputStream zip = new ZipOutputStream(out); Stream<Path> files = Files.list(src)) {
                    for (Path file : (Iterable<Path>) files::iterator) {
                        zip.putNextEntry(new ZipEntry(file.getFileName().toString()));
                        zip.write(Files.readAllBytes(file));
                        zip.closeEntry();
                    }
                }
            }
        }
        Path outside = Files.writeString(work.resolve("outside.ggb"), "outside the course directory");
        try { Files.createSymbolicLink(dir.resolve("link_outside.ggb"), outside); } catch (IOException | UnsupportedOperationException e) {
            System.out.println("# symlink not created: " + e);
        }
        StringBuilder big = new StringBuilder("{\"schemaVersion\":\"1.0\",\"course\":\"T-10 big\",\"tree\":[");
        String title = "S".repeat(200);
        for (int c = 1; c <= 50; c++) {
            big.append(c > 1 ? "," : "").append("{\"title\":\"C").append(c).append("\",\"children\":[");
            for (int s = 0; s < 100; s++) big.append(s > 0 ? "," : "").append("{\"title\":\"").append(title).append("\"}");
            big.append("]}");
        }
        Files.writeString(dir.resolve("T-10_big_GROK_V1.json"), big.append("]}"));
        return dir;
    }
}
