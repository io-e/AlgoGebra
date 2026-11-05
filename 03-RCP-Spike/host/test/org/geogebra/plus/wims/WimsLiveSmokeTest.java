package org.geogebra.plus.wims;

import java.math.BigDecimal;
import java.net.URI;
import java.util.Locale;
import java.util.Map;

/** Explicit opt-in happy-path probe for a test WIMS endpoint; never used by default. */
public final class WimsLiveSmokeTest {
    private WimsLiveSmokeTest() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 7) {
            throw new IllegalArgumentException(
                    "Expected endpoint, module, exercise, field, answer, expected grade, and language");
        }
        URI endpoint = URI.create(args[0]);
        String module = args[1];
        String exerciseId = args[2];
        String answerField = args[3];
        String answer = args[4];
        BigDecimal expectedGrade = new BigDecimal(args[5]);
        Locale locale = Locale.forLanguageTag(args[6]);
        WimsExerciseRef exercise = new WimsExerciseRef(endpoint, module, exerciseId, locale);
        WimsClient client = new HttpWimsClient();

        WimsSession session = client.createSession(exercise, locale);
        if (!session.getAnswerFields().contains(answerField)) {
            throw new WimsException(WimsError.UNKNOWN_ANSWER_FIELD,
                    "Configured live smoke field was not present in the WIMS exercise form");
        }
        GradeResult result = client.submitAnswers(session, Map.of(answerField, answer));
        check(1, "live-session-and-reply", result.grade() != null);
        check(2, "live-grade-is-numeric", result.grade().compareTo(BigDecimal.ZERO) >= 0
                && result.grade().compareTo(BigDecimal.ONE) <= 0);
        check(3, "live-grade-matches-expected", result.grade().compareTo(expectedGrade) == 0);
        System.out.println("# WIMS live smoke: 3 PASS, 0 FAIL");
    }

    private static void check(int number, String id, boolean condition) {
        if (!condition) {
            System.out.println("not ok " + number + " - " + id);
            throw new AssertionError("WIMS live smoke failed: " + id);
        }
        System.out.println("ok " + number + " - " + id);
    }
}
