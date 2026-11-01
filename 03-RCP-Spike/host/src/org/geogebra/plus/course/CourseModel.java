package org.geogebra.plus.course;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import org.geogebra.plus.course.CourseAction.Directive;
import org.geogebra.plus.course.CourseAction.Target;
import org.geogebra.plus.course.CourseNode.Check;
import org.geogebra.plus.course.CourseNode.CheckType;
import org.geogebra.plus.course.CourseNode.Kind;
import org.geogebra.plus.course.CourseNode.NumberRange;

/**
 * Validated immutable representation of a GeoGebraPlus course JSON document.
 * The parser is strict RFC 8259 JSON (unlike GeoGebra's legacy lenient tokener)
 * and enforces the schema and resource limits before UI or GeoGebra code sees it.
 */
public final class CourseModel {
    public static final String SUPPORTED_SCHEMA_VERSION = "1.0";
    public static final int MAX_FILE_BYTES = 1_048_576;
    private static final int MAX_JSON_NESTING = 32;
    private static final int MAX_TOTAL_ACTIONS = 500;

    private static final Set<String> ROOT_KEYS = Set.of(
            "schemaVersion", "course", "description", "author", "locale", "tree");
    private static final Set<String> CHAPTER_KEYS = Set.of("title", "description", "children");
    private static final Set<String> STEP_KEYS = Set.of(
            "title", "description", "actions", "check", "children");
    private static final Set<String> ACTION_KEYS = Set.of(
            "directive", "value", "target", "trustedGgb", "description");
    private static final Set<String> CHECK_KEYS = Set.of(
            "type", "variable", "expected", "tolerance", "target", "feedback");
    private static final Set<String> FEEDBACK_KEYS = Set.of("pass", "fail");
    private static final Set<String> RANGE_KEYS = Set.of("min", "max");

    private final String schemaVersion;
    private final String course;
    private final String description;
    private final String author;
    private final String locale;
    private final List<CourseNode> tree;

    private CourseModel(String schemaVersion, String course, String description,
            String author, String locale, List<CourseNode> tree) {
        this.schemaVersion = schemaVersion;
        this.course = course;
        this.description = description;
        this.author = author;
        this.locale = locale;
        this.tree = List.copyOf(tree);
    }

    public String getSchemaVersion() {
        return schemaVersion;
    }

    public String getCourse() {
        return course;
    }

    public String getDescription() {
        return description;
    }

    public String getAuthor() {
        return author;
    }

    public String getLocale() {
        return locale;
    }

    /** Top-level chapter nodes in display order. */
    public List<CourseNode> getTree() {
        return tree;
    }

    /** Loads a course as UTF-8, with a bounded read and strict decoding. */
    public static CourseModel load(Path path) throws IOException {
        Objects.requireNonNull(path, "path");
        long declaredSize = Files.size(path);
        if (declaredSize > MAX_FILE_BYTES) {
            throw new IOException("Course file exceeds the 1 MiB limit: " + declaredSize + " bytes");
        }
        byte[] bytes = readBounded(path, (int) Math.min(declaredSize, MAX_FILE_BYTES));
        String json;
        try {
            json = StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(bytes)).toString();
        } catch (CharacterCodingException exception) {
            throw new IOException("Course file is not valid UTF-8", exception);
        }
        try {
            return parse(json);
        } catch (CourseFormatException exception) {
            throw new IOException("Invalid course file: " + exception.getMessage(), exception);
        }
    }

    private static byte[] readBounded(Path path, int initialCapacity) throws IOException {
        try (InputStream input = Files.newInputStream(path);
                ByteArrayOutputStream output = new ByteArrayOutputStream(initialCapacity)) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = input.read(buffer)) != -1) {
                if ((long) output.size() + read > MAX_FILE_BYTES) {
                    throw new IOException("Course file grew beyond the 1 MiB limit while reading");
                }
                output.write(buffer, 0, read);
            }
            return output.toByteArray();
        }
    }

    /** Parses and validates a course JSON string. */
    public static CourseModel parse(String json) {
        if (json == null) {
            throw new CourseFormatException("Course JSON must not be null");
        }
        if (json.getBytes(StandardCharsets.UTF_8).length > MAX_FILE_BYTES) {
            throw new CourseFormatException("Course JSON exceeds the 1 MiB limit");
        }
        Object parsed = new StrictJsonParser(json).parseDocument();
        Map<String, Object> root = object(parsed, "$");
        checkKeys(root, ROOT_KEYS, "$");

        String version = requiredString(root, "schemaVersion", 1, 20, "$");
        if (!SUPPORTED_SCHEMA_VERSION.equals(version)) {
            throw format("$.schemaVersion", "unsupported version '" + version + "'");
        }
        String course = requiredString(root, "course", 1, 200, "$");
        String description = optionalString(root, "description", 0, 2000, "", "$");
        String author = optionalString(root, "author", 0, 200, "", "$");
        String locale = optionalString(root, "locale", 2, 5, "en", "$");
        if (!locale.matches("[a-z]{2}(_[A-Z]{2})?")) {
            throw format("$.locale", "must match xx or xx_YY");
        }
        List<Object> rawTree = requiredArray(root, "tree", "$");
        if (rawTree.isEmpty() || rawTree.size() > 50) {
            throw format("$.tree", "must contain between 1 and 50 chapters");
        }
        int[] actionCount = {0};
        List<CourseNode> chapters = new ArrayList<>(rawTree.size());
        for (int index = 0; index < rawTree.size(); index++) {
            chapters.add(parseChapter(rawTree.get(index), "$.tree[" + index + "]", actionCount));
        }
        if (actionCount[0] > MAX_TOTAL_ACTIONS) {
            throw format("$.tree", "course exceeds the maximum of 500 actions");
        }
        return new CourseModel(version, course, description, author, locale, chapters);
    }

    private static CourseNode parseChapter(Object raw, String path, int[] actionCount) {
        Map<String, Object> chapter = object(raw, path);
        checkKeys(chapter, CHAPTER_KEYS, path);
        String title = requiredString(chapter, "title", 1, 200, path);
        String description = optionalString(chapter, "description", 0, 2000, "", path);
        List<Object> rawChildren = requiredArray(chapter, "children", path);
        if (rawChildren.isEmpty() || rawChildren.size() > 100) {
            throw format(path + ".children", "must contain between 1 and 100 steps");
        }
        List<CourseNode> children = new ArrayList<>(rawChildren.size());
        for (int index = 0; index < rawChildren.size(); index++) {
            children.add(parseStep(rawChildren.get(index), 1,
                    path + ".children[" + index + "]", actionCount));
        }
        return new CourseNode(Kind.CHAPTER, title, description, List.of(), null, children);
    }

    private static CourseNode parseStep(Object raw, int stepLevel, String path,
            int[] actionCount) {
        if (stepLevel > 4) {
            throw format(path, "step nesting exceeds four levels below a chapter");
        }
        Map<String, Object> step = object(raw, path);
        checkKeys(step, STEP_KEYS, path);
        String title = requiredString(step, "title", 1, 200, path);
        String description = optionalString(step, "description", 0, 2000, "", path);
        List<CourseAction> actions = new ArrayList<>();
        if (step.containsKey("actions")) {
            List<Object> rawActions = array(step.get("actions"), path + ".actions");
            if (rawActions.size() > 20) {
                throw format(path + ".actions", "must contain at most 20 actions");
            }
            for (int index = 0; index < rawActions.size(); index++) {
                actions.add(parseAction(rawActions.get(index), path + ".actions[" + index + "]"));
                actionCount[0]++;
                if (actionCount[0] > MAX_TOTAL_ACTIONS) {
                    throw format(path + ".actions", "course exceeds the maximum of 500 actions");
                }
            }
        }
        Check check = step.containsKey("check")
                ? parseCheck(step.get("check"), path + ".check") : null;
        List<CourseNode> children = new ArrayList<>();
        if (step.containsKey("children")) {
            List<Object> rawChildren = array(step.get("children"), path + ".children");
            if (rawChildren.size() > 50) {
                throw format(path + ".children", "must contain at most 50 sub-steps");
            }
            for (int index = 0; index < rawChildren.size(); index++) {
                children.add(parseStep(rawChildren.get(index), stepLevel + 1,
                        path + ".children[" + index + "]", actionCount));
            }
        }
        return new CourseNode(Kind.STEP, title, description, actions, check, children);
    }

    private static CourseAction parseAction(Object raw, String path) {
        Map<String, Object> action = object(raw, path);
        checkKeys(action, ACTION_KEYS, path);
        Directive directive = enumValue(Directive.class,
                requiredString(action, "directive", 1, 20, path), path + ".directive");
        String value = requiredString(action, "value", 1, 2000, path);
        Target target = Target.fromJson(optionalString(action, "target", 2, 3, "2d", path));
        boolean trustedGgb = optionalBoolean(action, "trustedGgb", false, path);
        String description = optionalString(action, "description", 0, 500, "", path);
        if (trustedGgb && directive != Directive.OPEN) {
            throw format(path + ".trustedGgb", "is valid only for OPEN actions");
        }
        return new CourseAction(directive, value, target, trustedGgb, description);
    }

    private static Check parseCheck(Object raw, String path) {
        Map<String, Object> check = object(raw, path);
        checkKeys(check, CHECK_KEYS, path);
        String typeValue = requiredString(check, "type", 1, 32, path);
        CheckType type = CheckType.fromJson(typeValue);
        String variable = optionalString(check, "variable", 1, 200, "", path);
        Object expected = check.containsKey("expected")
                ? parseExpected(check.get("expected"), path + ".expected") : null;
        double tolerance = check.containsKey("tolerance")
                ? finiteNumber(check.get("tolerance"), path + ".tolerance") : 0.001;
        if (tolerance < 0) {
            throw format(path + ".tolerance", "must be zero or greater");
        }
        Target target = Target.fromJson(optionalString(check, "target", 2, 3, "2d", path));
        String pass = "";
        String fail = "";
        if (check.containsKey("feedback")) {
            Map<String, Object> feedback = object(check.get("feedback"), path + ".feedback");
            checkKeys(feedback, FEEDBACK_KEYS, path + ".feedback");
            pass = optionalString(feedback, "pass", 0, 500, "", path + ".feedback");
            fail = optionalString(feedback, "fail", 0, 500, "", path + ".feedback");
        }
        return new Check(type, variable, expected, tolerance, target, pass, fail);
    }

    private static Object parseExpected(Object value, String path) {
        if (value instanceof String) {
            return value;
        }
        if (value instanceof BigDecimal) {
            return finiteNumber(value, path);
        }
        if (value instanceof Map<?, ?>) {
            Map<String, Object> range = object(value, path);
            checkKeys(range, RANGE_KEYS, path);
            double min = finiteNumber(requiredValue(range, "min", path), path + ".min");
            double max = finiteNumber(requiredValue(range, "max", path), path + ".max");
            try {
                return new NumberRange(min, max);
            } catch (IllegalArgumentException exception) {
                throw new CourseFormatException(path + " must have min <= max", exception);
            }
        }
        throw format(path, "must be a string, finite number, or {min,max} range");
    }

    private static double finiteNumber(Object value, String path) {
        if (!(value instanceof BigDecimal decimal)) {
            throw format(path, "must be a JSON number");
        }
        double number = decimal.doubleValue();
        if (!Double.isFinite(number)) {
            throw format(path, "number is outside the supported finite range");
        }
        return number;
    }

    private static boolean optionalBoolean(Map<String, Object> object, String key,
            boolean fallback, String path) {
        if (!object.containsKey(key)) {
            return fallback;
        }
        Object value = object.get(key);
        if (!(value instanceof Boolean result)) {
            throw format(path + "." + key, "must be a boolean");
        }
        return result;
    }

    private static String requiredString(Map<String, Object> object, String key,
            int minLength, int maxLength, String path) {
        if (!object.containsKey(key)) {
            throw format(path + "." + key, "is required");
        }
        return string(object.get(key), minLength, maxLength, path + "." + key);
    }

    private static String optionalString(Map<String, Object> object, String key,
            int minLength, int maxLength, String fallback, String path) {
        if (!object.containsKey(key)) {
            return fallback;
        }
        return string(object.get(key), minLength, maxLength, path + "." + key);
    }

    private static String string(Object value, int minLength, int maxLength, String path) {
        if (!(value instanceof String result)) {
            throw format(path, "must be a string");
        }
        int length = result.codePointCount(0, result.length());
        if (length < minLength || length > maxLength) {
            throw format(path, "length must be between " + minLength + " and " + maxLength);
        }
        return result;
    }

    private static List<Object> requiredArray(Map<String, Object> object, String key, String path) {
        if (!object.containsKey(key)) {
            throw format(path + "." + key, "is required");
        }
        return array(object.get(key), path + "." + key);
    }

    @SuppressWarnings("unchecked")
    private static List<Object> array(Object value, String path) {
        if (!(value instanceof List<?>)) {
            throw format(path, "must be an array");
        }
        return (List<Object>) value;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> object(Object value, String path) {
        if (!(value instanceof Map<?, ?>)) {
            throw format(path, "must be an object");
        }
        return (Map<String, Object>) value;
    }

    private static Object requiredValue(Map<String, Object> object, String key, String path) {
        if (!object.containsKey(key)) {
            throw format(path + "." + key, "is required");
        }
        return object.get(key);
    }

    private static void checkKeys(Map<String, Object> object, Set<String> allowed, String path) {
        for (String key : object.keySet()) {
            if (!allowed.contains(key)) {
                throw format(path + "." + key, "is not allowed by schema 1.0");
            }
        }
    }

    private static <T extends Enum<T>> T enumValue(Class<T> enumType, String value, String path) {
        try {
            return Enum.valueOf(enumType, value);
        } catch (IllegalArgumentException exception) {
            throw new CourseFormatException(path + " has unknown value '" + value + "'", exception);
        }
    }

    private static CourseFormatException format(String path, String message) {
        return new CourseFormatException(path + " " + message);
    }

    /** Small strict JSON parser: no comments, unquoted names, duplicate keys, or trailing tokens. */
    private static final class StrictJsonParser {
        private final String input;
        private int index;

        private StrictJsonParser(String input) {
            this.input = input;
        }

        private Object parseDocument() {
            skipWhitespace();
            Object value = parseValue(0);
            skipWhitespace();
            if (index != input.length()) {
                throw syntax("unexpected content after the JSON value");
            }
            return value;
        }

        private Object parseValue(int depth) {
            if (depth > MAX_JSON_NESTING) {
                throw syntax("JSON nesting exceeds " + MAX_JSON_NESTING);
            }
            skipWhitespace();
            if (index >= input.length()) {
                throw syntax("unexpected end of input");
            }
            char current = input.charAt(index);
            return switch (current) {
            case '{' -> parseObject(depth);
            case '[' -> parseArray(depth);
            case '"' -> parseString();
        case 't' -> parseLiteral("true", Boolean.TRUE);
        case 'f' -> parseLiteral("false", Boolean.FALSE);
        case 'n' -> parseLiteral("null", null);
        default -> current == '-' || isDigit(current) ? parseNumber() : invalidValue();
            };
        }

        private Map<String, Object> parseObject(int depth) {
            index++;
            skipWhitespace();
            Map<String, Object> values = new LinkedHashMap<>();
            if (consume('}')) {
                return values;
            }
            while (true) {
                skipWhitespace();
                if (index >= input.length() || input.charAt(index) != '"') {
                    throw syntax("object member name must be a quoted string");
                }
                String key = parseString();
                if (values.containsKey(key)) {
                    throw syntax("duplicate object member '" + key + "'");
                }
                skipWhitespace();
                expect(':');
                Object value = parseValue(depth + 1);
                values.put(key, value);
                skipWhitespace();
                if (consume('}')) {
                    return values;
                }
                expect(',');
            }
        }

        private List<Object> parseArray(int depth) {
            index++;
            skipWhitespace();
            List<Object> values = new ArrayList<>();
            if (consume(']')) {
                return values;
            }
            while (true) {
                values.add(parseValue(depth + 1));
                skipWhitespace();
                if (consume(']')) {
                    return values;
                }
                expect(',');
            }
        }

        private String parseString() {
            expect('"');
            StringBuilder result = new StringBuilder();
            while (index < input.length()) {
                char current = input.charAt(index++);
                if (current == '"') {
                    validateSurrogates(result);
                    return result.toString();
                }
                if (current == '\\') {
                    if (index >= input.length()) {
                        throw syntax("unterminated escape sequence");
                }
                char escape = input.charAt(index++);
                switch (escape) {
                case '"', '\\', '/' -> result.append(escape);
                case 'b' -> result.append('\b');
                case 'f' -> result.append('\f');
                case 'n' -> result.append('\n');
                case 'r' -> result.append('\r');
                case 't' -> result.append('\t');
                case 'u' -> result.append(parseUnicodeEscape());
                default -> throw syntax("invalid escape sequence");
                }
            } else {
                if (current < 0x20) {
                    throw syntax("unescaped control character in string");
                }
                result.append(current);
            }
        }
            throw syntax("unterminated string");
        }

        private char parseUnicodeEscape() {
            if (input.length() - index < 4) {
                throw syntax("incomplete Unicode escape");
            }
            int value = 0;
            for (int count = 0; count < 4; count++) {
                int digit = asciiHexDigit(input.charAt(index++));
                if (digit < 0) {
                    throw syntax("invalid Unicode escape");
                }
                value = value * 16 + digit;
            }
            return (char) value;
        }

        private static int asciiHexDigit(char value) {
            if (value >= '0' && value <= '9') {
                return value - '0';
            }
            if (value >= 'a' && value <= 'f') {
                return value - 'a' + 10;
            }
            if (value >= 'A' && value <= 'F') {
                return value - 'A' + 10;
            }
            return -1;
        }

        private void validateSurrogates(CharSequence value) {
            for (int offset = 0; offset < value.length(); offset++) {
                char current = value.charAt(offset);
                if (Character.isHighSurrogate(current)) {
                    if (offset + 1 >= value.length()
                            || !Character.isLowSurrogate(value.charAt(offset + 1))) {
                        throw syntax("unpaired high surrogate in string");
                    }
                    offset++;
                } else if (Character.isLowSurrogate(current)) {
                    throw syntax("unpaired low surrogate in string");
                }
            }
        }

        private Object parseNumber() {
            int start = index;
            consume('-');
            if (consume('0')) {
                if (index < input.length() && isDigit(input.charAt(index))) {
                    throw syntax("leading zero in number");
                }
            } else {
                if (!consumeDigitOneToNine()) {
                    throw syntax("invalid number");
                }
                consumeDigits();
            }
            if (consume('.')) {
                if (index >= input.length() || !isDigit(input.charAt(index))) {
                    throw syntax("fraction requires at least one digit");
                }
                consumeDigits();
            }
            if (consume('e') || consume('E')) {
                if (!consume('+')) {
                    consume('-');
                }
                if (index >= input.length() || !isDigit(input.charAt(index))) {
                    throw syntax("exponent requires at least one digit");
                }
                consumeDigits();
            }
            String token = input.substring(start, index);
            if (token.length() > 128) {
                throw syntax("number token exceeds 128 characters");
            }
            try {
                return new BigDecimal(token);
            } catch (NumberFormatException exception) {
                throw new CourseFormatException("Invalid JSON number at offset " + start, exception);
            }
        }

        private Object parseLiteral(String token, Object value) {
            if (!input.startsWith(token, index)) {
                throw syntax("invalid literal");
            }
            index += token.length();
            return value;
        }

        private Object invalidValue() {
            throw syntax("expected a JSON value");
        }

        private void consumeDigits() {
            while (index < input.length() && isDigit(input.charAt(index))) {
                index++;
            }
        }

        private boolean consumeDigitOneToNine() {
            if (index < input.length()) {
                char current = input.charAt(index);
                if (current >= '1' && current <= '9') {
                    index++;
                    return true;
                }
            }
            return false;
        }

        private static boolean isDigit(char value) {
            return value >= '0' && value <= '9';
        }

        private boolean consume(char expected) {
            if (index < input.length() && input.charAt(index) == expected) {
                index++;
                return true;
            }
            return false;
        }

        private void expect(char expected) {
            if (!consume(expected)) {
                throw syntax("expected '" + expected + "'");
            }
        }

        private void skipWhitespace() {
            while (index < input.length()) {
                char current = input.charAt(index);
                if (current == ' ' || current == '\t' || current == '\r' || current == '\n') {
                    index++;
                } else {
                    return;
                }
            }
        }

        private CourseFormatException syntax(String message) {
            return new CourseFormatException("Invalid JSON at offset " + index + ": " + message);
        }
    }
}
