package org.geogebra.plus.course;

import java.util.List;
import java.util.Objects;

/** Immutable chapter or step displayed by the course tree. */
public record CourseNode(Kind kind, String title, String description,
        List<CourseAction> actions, Check check, List<CourseNode> children) {

    public enum Kind {
        CHAPTER,
        STEP
    }

    public enum CheckType {
        VALUE_EQUALS("value_equals"),
        VALUE_RANGE("value_range"),
        OBJECT_EXISTS("object_exists"),
        CAS_EQUALS("cas_equals");

        private final String jsonValue;

        CheckType(String jsonValue) {
            this.jsonValue = jsonValue;
        }

        public String jsonValue() {
            return jsonValue;
        }

        static CheckType fromJson(String value) {
            for (CheckType type : values()) {
                if (type.jsonValue.equals(value)) {
                    return type;
                }
            }
            throw new CourseFormatException("Unknown check type: " + value);
        }
    }

    /** Numeric expected value for a {@code value_range} check. */
    public record NumberRange(double min, double max) {
        public NumberRange {
            if (!Double.isFinite(min) || !Double.isFinite(max) || min > max) {
                throw new IllegalArgumentException("Invalid numeric range");
            }
        }
    }

    /** Formative check attached to a step; it is never an authoritative grade. */
    public record Check(CheckType type, String variable, Object expected,
            double tolerance, CourseAction.Target target, String passFeedback,
            String failFeedback) {
        public Check {
            Objects.requireNonNull(type, "type");
            variable = variable == null ? "" : variable;
            if (expected != null && !(expected instanceof String)
                    && !(expected instanceof Double) && !(expected instanceof NumberRange)) {
                throw new IllegalArgumentException("Unsupported check expected value");
            }
            if (!Double.isFinite(tolerance) || tolerance < 0) {
                throw new IllegalArgumentException("Invalid check tolerance");
            }
            Objects.requireNonNull(target, "target");
            passFeedback = passFeedback == null ? "" : passFeedback;
            failFeedback = failFeedback == null ? "" : failFeedback;
        }
    }

    public CourseNode {
        Objects.requireNonNull(kind, "kind");
        Objects.requireNonNull(title, "title");
        description = description == null ? "" : description;
        actions = List.copyOf(actions == null ? List.of() : actions);
        children = List.copyOf(children == null ? List.of() : children);
        if (title.isEmpty()) {
            throw new IllegalArgumentException("Node title must not be empty");
        }
        if (kind == Kind.CHAPTER && (!actions.isEmpty() || check != null)) {
            throw new IllegalArgumentException("Chapters cannot contain actions or checks");
        }
    }
}
