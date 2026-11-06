package org.geogebra.plus.wims;

import java.math.BigDecimal;
import java.util.List;
import java.util.Objects;

/** Overall and per-answer grade returned by the WIMS hook. Integer JSON grades are valid. */
public record GradeResult(BigDecimal grade, Long seed, List<WimsAnswerResult> answers,
        String feedback) {
    public GradeResult {
        Objects.requireNonNull(grade, "grade");
        answers = List.copyOf(answers);
        feedback = Objects.requireNonNullElse(feedback, "");
    }
}
