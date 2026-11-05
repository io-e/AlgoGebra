package org.geogebra.plus.wims;

import java.util.Locale;
import java.util.Map;

/** Client for WIMS OEF's stock {@code cmd=new} / {@code cmd=reply} grading flow. */
public interface WimsClient {
    WimsSession createSession(WimsExerciseRef exercise, Locale locale) throws WimsException;

    /**
     * Submits one or more values for each answer field. Repeated values are supported for
     * checkbox-style OEF fields, which WIMS represents as repeated form keys.
     */
    GradeResult submitAnswers(WimsSession session, WimsAnswerSubmission answers)
            throws WimsException;

    /** Convenience overload for exercises where each field has one value. */
    default GradeResult submitAnswers(WimsSession session, Map<String, String> answers)
            throws WimsException {
        return submitAnswers(session, WimsAnswerSubmission.fromSingleValues(answers));
    }
}
