package org.geogebra.plus.course;

import java.util.List;
import java.util.Objects;

/** Structured course-policy outcome; warnings never turn a rejection into acceptance. */
public record CourseValidationResult(Status status, String message, List<String> warnings) {

    public enum Status {
        ACCEPT,
        ACCEPT_WITH_WARNING,
        REJECT
    }

    public CourseValidationResult {
        Objects.requireNonNull(status, "status");
        message = message == null ? "" : message;
        warnings = List.copyOf(warnings == null ? List.of() : warnings);
        if (status == Status.ACCEPT_WITH_WARNING && warnings.isEmpty()) {
            throw new IllegalArgumentException("ACCEPT_WITH_WARNING requires at least one warning");
        }
        if (status == Status.ACCEPT && !warnings.isEmpty()) {
            throw new IllegalArgumentException("ACCEPT cannot contain warnings");
        }
    }

    public static CourseValidationResult accept() {
        return new CourseValidationResult(Status.ACCEPT, "", List.of());
    }

    public static CourseValidationResult acceptWithWarning(String warning) {
        return new CourseValidationResult(Status.ACCEPT_WITH_WARNING, "", List.of(warning));
    }

    public static CourseValidationResult acceptWithWarnings(List<String> warnings) {
        return warnings == null || warnings.isEmpty()
                ? accept()
                : new CourseValidationResult(Status.ACCEPT_WITH_WARNING, "", warnings);
    }

    public static CourseValidationResult reject(String reason) {
        return new CourseValidationResult(Status.REJECT, Objects.requireNonNull(reason, "reason"), List.of());
    }

    public boolean isAccepted() {
        return status != Status.REJECT;
    }
}
