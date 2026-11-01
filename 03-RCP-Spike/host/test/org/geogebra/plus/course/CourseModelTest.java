package org.geogebra.plus.course;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/** Dependency-free unit tests for the course model and strict schema-1.0 parser. */
public final class CourseModelTest {
    private static final String VALID = ""
            + "{\"schemaVersion\":\"1.0\",\"course\":\"Linear Functions\","
            + "\"description\":\"Introductory lesson\",\"author\":\"Teacher\","
            + "\"locale\":\"en\",\"tree\":[{\"title\":\"Chapter 1\","
            + "\"children\":[{\"title\":\"Create a line\","
            + "\"description\":\"Use the input bar\","
            + "\"actions\":[{\"directive\":\"CMD\",\"value\":\"f(x)=2x+1\"}],"
            + "\"check\":{\"type\":\"object_exists\",\"variable\":\"f\"}}]}]}";

    private static int passed;
    private static int failed;

    private CourseModelTest() {
    }

    public static void main(String[] args) {
        run("valid model, defaults, and immutable tree", CourseModelTest::validModel);
        run("nested steps and 3D/OPEN/check parsing", CourseModelTest::nestedActionAndCheck);
        run("strict JSON grammar and duplicate-key rejection", CourseModelTest::strictJson);
        run("schema and enum validation", CourseModelTest::schemaValidation);
        run("four nested step levels are allowed; fifth is rejected", CourseModelTest::depthLimit);
        run("action-count, trust flag, and check-range constraints", CourseModelTest::securityConstraints);
        run("1 MiB course-size cap for strings and files", CourseModelTest::sizeLimit);
        run("UTF-8 load and malformed-byte rejection", CourseModelTest::utf8Load);
        if (args.length > 0) {
            run("RCP course-tree smoke fixture loads", () -> {
                try {
                    CourseModel fixture = CourseModel.load(Path.of(args[0]));
                    equals("Course Tree Smoke — Trigonometry", fixture.getCourse());
                    equals(1, fixture.getTree().size());
                    equals(3, fixture.getTree().get(0).children().get(0).actions().size());
                } catch (IOException error) {
                    throw new AssertionError("Could not load course-tree smoke fixture", error);
                }
            });
        }
        System.out.println("CourseModelTest: " + passed + " PASS, " + failed + " FAIL");
        if (failed > 0) {
            throw new AssertionError("CourseModelTest has failures");
        }
    }

    private static void validModel() {
        CourseModel model = CourseModel.parse(VALID);
        equals("1.0", model.getSchemaVersion());
        equals("Linear Functions", model.getCourse());
        equals("Introductory lesson", model.getDescription());
        equals("Teacher", model.getAuthor());
        equals("en", model.getLocale());
        equals(1, model.getTree().size());
        CourseNode chapter = model.getTree().get(0);
        equals(CourseNode.Kind.CHAPTER, chapter.kind());
        CourseNode step = chapter.children().get(0);
        equals(CourseNode.Kind.STEP, step.kind());
        equals("Create a line", step.title());
        equals(CourseAction.Directive.CMD, step.actions().get(0).directive());
        equals(CourseAction.Target.TWO_D, step.actions().get(0).target());
        equals(false, step.actions().get(0).trustedGgb());
        equals(CourseNode.CheckType.OBJECT_EXISTS, step.check().type());
        equals("f", step.check().variable());
        expect(UnsupportedOperationException.class, () -> model.getTree().clear());
    }

    private static void nestedActionAndCheck() {
        String json = ""
                + "{\"schemaVersion\":\"1.0\",\"course\":\"3D\",\"locale\":\"fr_FR\","
                + "\"tree\":[{\"title\":\"Chapter\",\"children\":[{\"title\":\"Open file\","
                + "\"actions\":[{\"directive\":\"OPEN\",\"value\":\"starter.ggb\","
                + "\"target\":\"3d\",\"trustedGgb\":true}],"
                + "\"check\":{\"type\":\"value_range\",\"variable\":\"a\","
                + "\"expected\":{\"min\":1.5,\"max\":2.5},\"tolerance\":0.01,"
                + "\"target\":\"3d\",\"feedback\":{\"pass\":\"Good\",\"fail\":\"Try again\"}},"
                + "\"children\":[{\"title\":\"Sub-step\"}]}]}]}";
        CourseModel model = CourseModel.parse(json);
        equals("fr_FR", model.getLocale());
        CourseNode step = model.getTree().get(0).children().get(0);
        CourseAction action = step.actions().get(0);
        equals(CourseAction.Directive.OPEN, action.directive());
        equals(CourseAction.Target.THREE_D, action.target());
        equals(true, action.trustedGgb());
        equals("Sub-step", step.children().get(0).title());
        equals(0.01, step.check().tolerance());
        equals("Good", step.check().passFeedback());
        CourseNode.NumberRange range = (CourseNode.NumberRange) step.check().expected();
        equals(1.5, range.min());
        equals(2.5, range.max());
    }

    private static void strictJson() {
        String duplicateKey = "{\"schemaVersion\":\"1.0\",\"schemaVersion\":\"1.0\","
                + "\"course\":\"x\",\"tree\":[{\"title\":\"c\",\"children\":[{\"title\":\"s\"}]}]}";
        String trailingComma = "{\"schemaVersion\":\"1.0\",\"course\":\"x\","
                + "\"tree\":[{\"title\":\"c\",\"children\":[{\"title\":\"s\",}]}]}";
        String leadingZero = "{\"schemaVersion\":\"1.0\",\"course\":\"x\","
                + "\"tree\":[{\"title\":\"c\",\"children\":[{\"title\":\"s\","
                + "\"check\":{\"type\":\"value_equals\",\"expected\":01}}]}]}";
        String[] invalid = {
                "// comment\n" + VALID,
                VALID.replace('"', '\''),
                "{schemaVersion:\"1.0\",\"course\":\"x\",\"tree\":[]}",
                trailingComma,
                duplicateKey,
                VALID + " true",
                leadingZero,
                "{\"schemaVersion\":\"1.0\",\"course\":\"\\uD800\","
                        + "\"tree\":[{\"title\":\"c\",\"children\":[{\"title\":\"s\"}]}]}",
                "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"tree\":[,]}"
        };
        for (String json : invalid) {
            expect(CourseFormatException.class, () -> CourseModel.parse(json));
        }
    }

    private static void schemaValidation() {
        String[] invalid = {
                "{\"schemaVersion\":\"1.1\",\"course\":\"x\",\"tree\":[{\"title\":\"c\",\"children\":[{\"title\":\"s\"}]}]}",
                "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"tree\":[]}",
                "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"unknown\":true,\"tree\":[{\"title\":\"c\",\"children\":[{\"title\":\"s\"}]}]}",
                "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"locale\":\"EN-us\",\"tree\":[{\"title\":\"c\",\"children\":[{\"title\":\"s\"}]}]}",
                "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"tree\":[{\"title\":\"c\"}]}",
                "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"tree\":[{\"title\":\"c\",\"children\":[{}]}]}",
                "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"tree\":[{\"title\":\"c\",\"children\":[{\"title\":\"s\",\"actions\":[{\"directive\":\"RUN\",\"value\":\"x\"}]}]}]}",
                "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"tree\":[{\"title\":\"c\",\"children\":[{\"title\":\"s\",\"actions\":[{\"directive\":\"CMD\",\"value\":\"x\",\"target\":\"sideways\"}]}]}]}"
        };
        for (String json : invalid) {
            expect(CourseFormatException.class, () -> CourseModel.parse(json));
        }
    }

    private static void depthLimit() {
        CourseModel.parse(courseWithNestedSteps(4));
        expect(CourseFormatException.class, () -> CourseModel.parse(courseWithNestedSteps(5)));
    }

    private static void securityConstraints() {
        String trustedCmd = "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"tree\":[{\"title\":\"c\","
                + "\"children\":[{\"title\":\"s\",\"actions\":[{\"directive\":\"CMD\","
                + "\"value\":\"A=1\",\"trustedGgb\":true}]}]}]}";
        expect(CourseFormatException.class, () -> CourseModel.parse(trustedCmd));
        String invalidRange = "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"tree\":[{\"title\":\"c\","
                + "\"children\":[{\"title\":\"s\",\"check\":{\"type\":\"value_range\","
                + "\"expected\":{\"min\":3,\"max\":2}}}]}]}";
        expect(CourseFormatException.class, () -> CourseModel.parse(invalidRange));
        String negativeTolerance = "{\"schemaVersion\":\"1.0\",\"course\":\"x\",\"tree\":[{\"title\":\"c\","
                + "\"children\":[{\"title\":\"s\",\"check\":{\"type\":\"value_equals\","
                + "\"tolerance\":-0.1}}]}]}";
        expect(CourseFormatException.class, () -> CourseModel.parse(negativeTolerance));
        expect(CourseFormatException.class, () -> CourseModel.parse(courseWithActionCount(1, 21)));
        expect(CourseFormatException.class, () -> CourseModel.parse(courseWithActionCount(26, 20)));
    }

    private static void sizeLimit() {
        String oversized = "{\"schemaVersion\":\"1.0\",\"course\":\""
                + "x".repeat(CourseModel.MAX_FILE_BYTES) + "\",\"tree\":[]}";
        expect(CourseFormatException.class, () -> CourseModel.parse(oversized));
        Path file = null;
        try {
            file = Files.createTempFile("ggbplus-course-large-", ".json");
            Files.write(file, new byte[CourseModel.MAX_FILE_BYTES + 1]);
            expectIOException(file);
        } catch (IOException exception) {
            throw new AssertionError("Unexpected test I/O failure", exception);
        } finally {
            deleteIfPresent(file);
        }
    }

    private static void utf8Load() {
        Path validFile = null;
        Path invalidFile = null;
        try {
            validFile = Files.createTempFile("ggbplus-course-valid-", ".json");
            Files.writeString(validFile, VALID, java.nio.charset.StandardCharsets.UTF_8);
            equals("Linear Functions", CourseModel.load(validFile).getCourse());
            invalidFile = Files.createTempFile("ggbplus-course-invalid-", ".json");
            Files.write(invalidFile, new byte[] {(byte) 0xC3, (byte) 0x28});
            expectIOException(invalidFile);
        } catch (IOException exception) {
            throw new AssertionError("Unexpected test I/O failure", exception);
        } finally {
            deleteIfPresent(validFile);
            deleteIfPresent(invalidFile);
        }
    }

    private static void expectIOException(Path path) {
        try {
            CourseModel.load(path);
        } catch (IOException expected) {
            return;
        }
        throw new AssertionError("Expected invalid UTF-8 to be rejected");
    }

    private static String courseWithActionCount(int stepCount, int actionsPerStep) {
        StringBuilder json = new StringBuilder()
                .append("{\"schemaVersion\":\"1.0\",\"course\":\"Action limit\",\"tree\":[")
                .append("{\"title\":\"Chapter\",\"children\":[");
        for (int step = 0; step < stepCount; step++) {
            if (step > 0) {
                json.append(',');
            }
            json.append("{\"title\":\"Step\",\"actions\":[");
            for (int action = 0; action < actionsPerStep; action++) {
                if (action > 0) {
                    json.append(',');
                }
                json.append("{\"directive\":\"CMD\",\"value\":\"A=1\"}");
            }
            json.append("]}");
        }
        return json.append("]}]}").toString();
    }

    private static String courseWithNestedSteps(int stepCount) {
        String node = "{\"title\":\"Step " + stepCount + "\"}";
        for (int level = stepCount - 1; level >= 1; level--) {
            node = "{\"title\":\"Step " + level + "\",\"children\":[" + node + "]}";
        }
        return "{\"schemaVersion\":\"1.0\",\"course\":\"Depth test\",\"tree\":["
                + "{\"title\":\"Chapter\",\"children\":[" + node + "]}]}";
    }

    private static void deleteIfPresent(Path path) {
        if (path != null) {
            try {
                Files.deleteIfExists(path);
            } catch (IOException exception) {
                throw new AssertionError("Could not delete test file " + path, exception);
            }
        }
    }

    private static void run(String name, Runnable test) {
        try {
            test.run();
            passed++;
            System.out.println("PASS: " + name);
        } catch (Throwable throwable) {
            failed++;
            System.err.println("FAIL: " + name + " — " + throwable);
            throwable.printStackTrace(System.err);
        }
    }

    private static void equals(Object expected, Object actual) {
        if (expected instanceof Double expectedDouble && actual instanceof Double actualDouble) {
            if (Double.compare(expectedDouble, actualDouble) != 0) {
                throw new AssertionError("Expected " + expected + " but got " + actual);
            }
            return;
        }
        if (!java.util.Objects.equals(expected, actual)) {
            throw new AssertionError("Expected " + expected + " but got " + actual);
        }
    }

    private static void expect(Class<? extends Throwable> expectedType, Runnable action) {
        try {
            action.run();
        } catch (Throwable throwable) {
            if (expectedType.isInstance(throwable)) {
                return;
            }
            throw new AssertionError("Expected " + expectedType.getName()
                    + " but got " + throwable, throwable);
        }
        throw new AssertionError("Expected " + expectedType.getName() + " to be thrown");
    }
}
