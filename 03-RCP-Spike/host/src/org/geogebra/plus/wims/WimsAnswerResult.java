package org.geogebra.plus.wims;

import java.math.BigDecimal;
import java.util.Objects;

/** Per-answer grade details returned by the WIMS JSON hook. */
public record WimsAnswerResult(
        String id,
        boolean correct,
        BigDecimal score,
        String feedback,
        String expected,
        String normalizedGiven) {

    public WimsAnswerResult {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(score, "score");
        feedback = Objects.requireNonNullElse(feedback, "");
        expected = Objects.requireNonNullElse(expected, "");
        normalizedGiven = Objects.requireNonNullElse(normalizedGiven, "");
    }

    /**
     * WIMS's {@code answers[].given} is a normalized answer, not a transcript of the
     * student's keystrokes. Callers must not label or present this value as exact input.
     */
    public String normalizedGiven() {
        return normalizedGiven;
    }
}
