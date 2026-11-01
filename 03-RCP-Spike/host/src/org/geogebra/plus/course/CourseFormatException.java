package org.geogebra.plus.course;

/**
 * Raised when a course document is not valid JSON or does not match schema 1.0.
 */
public final class CourseFormatException extends IllegalArgumentException {
    private static final long serialVersionUID = 1L;

    public CourseFormatException(String message) {
        super(message);
    }

    public CourseFormatException(String message, Throwable cause) {
        super(message, cause);
    }
}
