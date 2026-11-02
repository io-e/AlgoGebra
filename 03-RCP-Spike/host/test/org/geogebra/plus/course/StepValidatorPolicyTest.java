package org.geogebra.plus.course;

import org.geogebra.common.kernel.commands.Commands;

/** Small executable policy tests that do not construct a GUI or GeoGebra app. */
public final class StepValidatorPolicyTest {

    private int passed;
    private int failed;

    public static void main(String[] args) {
        new StepValidatorPolicyTest().run();
    }

    private void run() {
        test("geometry command allowed", () -> check(StepValidator.isAllowed(Commands.Line)));
        test("algebra command allowed", () -> check(StepValidator.isAllowed(Commands.Factor)));
        test("CAS command allowed", () -> check(StepValidator.isAllowed(Commands.Integral)));
        test("SetColor scripting exception allowed", () -> check(StepValidator.isAllowed(Commands.SetColor)));
        test("Slider scripting exception allowed", () -> check(StepValidator.isAllowed(Commands.Slider)));
        test("Execute scripting command blocked", () -> check(!StepValidator.isAllowed(Commands.Execute)));
        test("Delete blocked", () -> check(!StepValidator.isAllowed(Commands.Delete)));
        test("SetValue blocked", () -> check(!StepValidator.isAllowed(Commands.SetValue)));
        test("null command denied", () -> check(!StepValidator.isAllowed(null)));
        test("untrusted OPEN rejected until archive scanner exists", this::untrustedOpenRejected);
        test("trusted OPEN is accepted with an explicit warning", this::trustedOpenWarns);
        test("Sequence accepts the 1,000 iteration boundary", () ->
                equals(1_000L, StepValidator.estimateSequenceIterations(1, 1_000, 1)));
        test("Sequence rejects more than 1,000 iterations", this::sequenceLimitRejects);
        test("Sequence rejects non-finite bounds or a zero step", this::invalidSequenceBoundsReject);
        test("Sequence handles direction mismatch as empty", () ->
                equals(0L, StepValidator.estimateSequenceIterations(10, 1, 1)));
        test("per-directive Sequence budget allows exactly 10,000 items", this::sequenceBudgetBoundary);
        test("nested Sequence expansion cannot exceed total budget", this::nestedSequenceBudgetReject);
        test("warning result is distinct from rejection", this::warningResultIsAccepted);
        System.out.println("StepValidatorPolicyTest: " + passed + " PASS, " + failed + " FAIL");
        if (failed != 0) {
            throw new AssertionError("Course command policy tests failed");
        }
    }

    private void test(String name, Runnable assertion) {
        try {
            assertion.run();
            passed++;
            System.out.println("PASS: " + name);
        } catch (Throwable error) {
            failed++;
            System.out.println("FAIL: " + name + " — " + error.getMessage());
        }
    }

    private static void check(boolean condition) {
        if (!condition) {
            throw new AssertionError("condition was false");
        }
    }

    private static void equals(Object expected, Object actual) {
        if (!java.util.Objects.equals(expected, actual)) {
            throw new AssertionError("expected " + expected + " but got " + actual);
        }
    }

    private void untrustedOpenRejected() {
        CourseAction action = new CourseAction(CourseAction.Directive.OPEN, "clean.ggb",
                CourseAction.Target.TWO_D, false, "");
        CourseValidationResult result = new StepValidator().validateOpen(action);
        check(result.status() == CourseValidationResult.Status.REJECT);
        check(!result.isAccepted());
    }

    private void trustedOpenWarns() {
        CourseAction action = new CourseAction(CourseAction.Directive.OPEN, "trusted.ggb",
                CourseAction.Target.TWO_D, true, "");
        CourseValidationResult result = new StepValidator().validateOpen(action);
        check(result.status() == CourseValidationResult.Status.ACCEPT_WITH_WARNING);
        check(result.isAccepted());
        equals(1, result.warnings().size());
    }

    private void sequenceLimitRejects() {
        try {
            StepValidator.estimateSequenceIterations(1, 1_001, 1);
            throw new AssertionError("expected the sequence limit to reject 1,001 iterations");
        } catch (IllegalArgumentException expected) {
            check(expected.getMessage().contains(Integer.toString(StepValidator.MAX_SEQUENCE_ITERATIONS)));
        }
    }

    private void invalidSequenceBoundsReject() {
        expectIllegalArgument(() -> StepValidator.estimateSequenceIterations(1, 10, 0));
        expectIllegalArgument(() -> StepValidator.estimateSequenceIterations(Double.NaN, 10, 1));
    }

    private void sequenceBudgetBoundary() {
        StepValidator.SequenceBudget budget = new StepValidator.SequenceBudget();
        check(budget.add(1_000));
        check(budget.add(9_000));
        equals(10_000L, budget.generatedItems());
        check(!budget.add(1));
    }

    private void nestedSequenceBudgetReject() {
        StepValidator.SequenceBudget budget = new StepValidator.SequenceBudget();
        check(budget.add(StepValidator.SequenceBudget.estimateGeneratedItems(100, 100)));
        equals(10_000L, budget.generatedItems());
        check(!budget.add(StepValidator.SequenceBudget.estimateGeneratedItems(10, 1_001)));
    }

    private void warningResultIsAccepted() {
        CourseValidationResult result = CourseValidationResult.acceptWithWarning("diagnostic only");
        check(result.status() == CourseValidationResult.Status.ACCEPT_WITH_WARNING);
        check(result.isAccepted());
        expectIllegalArgument(() -> new CourseValidationResult(
                CourseValidationResult.Status.ACCEPT_WITH_WARNING, "", java.util.List.of()));
    }

    private static void expectIllegalArgument(Runnable action) {
        try {
            action.run();
            throw new AssertionError("expected IllegalArgumentException");
        } catch (IllegalArgumentException expected) {
            // Expected fail-closed policy outcome.
        }
    }
}
