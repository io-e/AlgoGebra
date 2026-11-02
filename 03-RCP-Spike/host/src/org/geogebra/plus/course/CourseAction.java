package org.geogebra.plus.course;

import java.util.Objects;

/** Immutable, validated action in a course step. */
public record CourseAction(Directive directive, String value, Target target,
        boolean trustedGgb, String description) {

    public enum Directive {
        CMD,
        CAS,
        VAL,
        OPEN,
        SAVE,
        PNG
    }

    public enum Target {
        TWO_D("2d"),
        THREE_D("3d");

        private final String jsonValue;

        Target(String jsonValue) {
            this.jsonValue = jsonValue;
        }

        public String jsonValue() {
            return jsonValue;
        }

        static Target fromJson(String value) {
            for (Target target : values()) {
                if (target.jsonValue.equals(value)) {
                    return target;
                }
            }
            throw new CourseFormatException("Unknown action target: " + value);
        }
    }

    public CourseAction {
        Objects.requireNonNull(directive, "directive");
        Objects.requireNonNull(value, "value");
        Objects.requireNonNull(target, "target");
        description = description == null ? "" : description;
        if (value.isEmpty()) {
            throw new IllegalArgumentException("Action value must not be empty");
        }
        if (trustedGgb && directive != Directive.OPEN) {
            throw new IllegalArgumentException("trustedGgb is valid only for OPEN actions");
        }
    }
}
