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
}
