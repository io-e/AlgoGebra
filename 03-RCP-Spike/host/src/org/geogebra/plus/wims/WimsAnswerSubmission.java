package org.geogebra.plus.wims;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/** Immutable WIMS form answers, retaining repeated values for checkbox groups. */
public final class WimsAnswerSubmission {
    private final Map<String, List<String>> values;

    private WimsAnswerSubmission(Map<String, List<String>> values) {
        Map<String, List<String>> copy = new LinkedHashMap<>();
        values.forEach((key, items) -> copy.put(key, List.copyOf(items)));
        this.values = Collections.unmodifiableMap(copy);
    }

    public static Builder builder() {
        return new Builder();
    }

    public static WimsAnswerSubmission fromSingleValues(Map<String, String> values) {
        Objects.requireNonNull(values, "answers");
        Builder builder = builder();
        values.forEach(builder::set);
        return builder.build();
    }

    Map<String, List<String>> values() {
        return values;
    }

    public static final class Builder {
        private final Map<String, List<String>> values = new LinkedHashMap<>();

        /** Replaces any previous values for this field. */
        public Builder set(String field, String value) {
            Objects.requireNonNull(field, "field");
            Objects.requireNonNull(value, "value");
            values.put(field, new ArrayList<>(List.of(value)));
            return this;
        }

        /** Adds another value under the same form field name (e.g. checked boxes). */
        public Builder add(String field, String value) {
            Objects.requireNonNull(field, "field");
            Objects.requireNonNull(value, "value");
            values.computeIfAbsent(field, ignored -> new ArrayList<>()).add(value);
            return this;
        }

        public WimsAnswerSubmission build() {
            return new WimsAnswerSubmission(values);
        }
    }
}
