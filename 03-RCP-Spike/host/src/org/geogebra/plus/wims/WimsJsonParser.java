package org.geogebra.plus.wims;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Small strict JSON parser for the bounded WIMS grade block (no third-party dependency). */
final class WimsJsonParser {
    private static final int MAX_DEPTH = 32;

    private final String source;
    private int index;

    private WimsJsonParser(String source) {
        this.source = source;
    }

    static Object parse(String source) {
        WimsJsonParser parser = new WimsJsonParser(source);
        Object value = parser.value(0);
        parser.whitespace();
        if (parser.index != source.length()) {
            throw parser.error("trailing content");
        }
        return value;
    }

    private Object value(int depth) {
        if (depth > MAX_DEPTH) {
            throw error("nesting limit exceeded");
        }
        whitespace();
        if (index >= source.length()) {
            throw error("unexpected end of JSON");
        }
        return switch (source.charAt(index)) {
            case '{' -> object(depth + 1);
            case '[' -> array(depth + 1);
            case '"' -> string();
            case 't' -> literal("true", Boolean.TRUE);
            case 'f' -> literal("false", Boolean.FALSE);
            case 'n' -> literal("null", null);
            default -> number();
        };
    }

    private Map<String, Object> object(int depth) {
        index++;
        whitespace();
        Map<String, Object> result = new LinkedHashMap<>();
        if (consume('}')) {
            return result;
        }
        while (true) {
            whitespace();
            if (index >= source.length() || source.charAt(index) != '"') {
                throw error("object key must be a string");
            }
            String key = string();
            whitespace();
            require(':');
            Object value = value(depth);
            if (result.containsKey(key)) {
                throw error("duplicate object key");
            }
            result.put(key, value);
            whitespace();
            if (consume('}')) {
                return result;
            }
            require(',');
        }
    }

    private List<Object> array(int depth) {
        index++;
        whitespace();
        List<Object> result = new ArrayList<>();
        if (consume(']')) {
            return result;
        }
        while (true) {
            result.add(value(depth));
            whitespace();
            if (consume(']')) {
                return result;
            }
            require(',');
        }
    }

    private String string() {
        require('"');
        StringBuilder result = new StringBuilder();
        while (index < source.length()) {
            char current = source.charAt(index++);
            if (current == '"') {
                return result.toString();
            }
            if (current < 0x20) {
                throw error("unescaped control character in string");
            }
            if (current != '\\') {
                result.append(current);
                continue;
            }
            if (index >= source.length()) {
                throw error("unfinished escape sequence");
            }
            char escaped = source.charAt(index++);
            switch (escaped) {
                case '"', '\\', '/' -> result.append(escaped);
                case 'b' -> result.append('\b');
                case 'f' -> result.append('\f');
                case 'n' -> result.append('\n');
                case 'r' -> result.append('\r');
                case 't' -> result.append('\t');
                case 'u' -> result.append(unicodeEscape());
                default -> throw error("invalid string escape");
            }
        }
        throw error("unterminated string");
    }

    private char unicodeEscape() {
        if (index + 4 > source.length()) {
            throw error("short unicode escape");
        }
        int value = 0;
        for (int count = 0; count < 4; count++) {
            int digit = Character.digit(source.charAt(index++), 16);
            if (digit < 0) {
                throw error("invalid unicode escape");
            }
            value = value * 16 + digit;
        }
        return (char) value;
    }

    private Object number() {
        int start = index;
        consume('-');
        if (consume('0')) {
            if (index < source.length() && Character.isDigit(source.charAt(index))) {
                throw error("leading zero in number");
            }
        } else {
            digits(true);
        }
        if (consume('.')) {
            digits(true);
        }
        if (consume('e') || consume('E')) {
            if (!consume('+')) {
                consume('-');
            }
            digits(true);
        }
        if (start == index) {
            throw error("expected a JSON value");
        }
        try {
            return new BigDecimal(source.substring(start, index));
        } catch (NumberFormatException exception) {
            throw error("invalid number");
        }
    }

    private void digits(boolean required) {
        int start = index;
        while (index < source.length() && source.charAt(index) >= '0'
                && source.charAt(index) <= '9') {
            index++;
        }
        if (required && start == index) {
            throw error("expected a digit");
        }
    }

    private Object literal(String text, Object value) {
        if (!source.startsWith(text, index)) {
            throw error("invalid literal");
        }
        index += text.length();
        return value;
    }

    private void whitespace() {
        while (index < source.length()) {
            char value = source.charAt(index);
            if (value == ' ' || value == '\t' || value == '\r' || value == '\n') {
                index++;
            } else {
                return;
            }
        }
    }

    private boolean consume(char expected) {
        if (index < source.length() && source.charAt(index) == expected) {
            index++;
            return true;
        }
        return false;
    }

    private void require(char expected) {
        if (!consume(expected)) {
            throw error("expected '" + expected + "'");
        }
    }

    private IllegalArgumentException error(String message) {
        return new IllegalArgumentException(message + " at character " + index);
    }
}
