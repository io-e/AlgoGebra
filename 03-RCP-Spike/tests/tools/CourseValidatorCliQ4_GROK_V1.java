package org.geogebra.plus.course;
// GROK_V1 test-side COURSE_VALIDATOR for suite 16 over Codex's Q2-Q4 classes (feat/course-security-q2-q4).
// Uses the REAL product checks: CourseModel.load, StepValidator.validateCommand(App, ...) with a headless
// GeoGebra AppDNoGui (post-parse walk: localized names, nested commands, Sequence budget), StepValidator.validateOpen,
// and DirectiveExecutor.resolveInput (OPEN path rules incl. toRealPath, run at execution time in the product).
// Combination mirrors DirectiveExecutor.validateStep: first REJECT wins, warnings are collected.
// Output: first token ACCEPT | ACCEPT_WITH_WARNING | REJECT (owner Q4, issue #17).
import java.lang.reflect.*; import java.nio.file.*; import java.util.*;
import org.geogebra.common.main.App;
import org.geogebra.desktop.headless.AppDNoGui; import org.geogebra.desktop.main.LocalizationD;
public final class CourseValidatorCliQ4_GROK_V1 {
  public static void main(String[] a) {
    try { Path f = Path.of(a[0]); CourseModel m = CourseModel.load(f);
      App app = new AppDNoGui(new LocalizationD(3), false); StepValidator v = new StepValidator();
      DirectiveExecutor ex = new DirectiveExecutor(null, f, null, null, null, null);
      Method ri = DirectiveExecutor.class.getDeclaredMethod("resolveInput", String.class, String.class); ri.setAccessible(true);
      List<String> warn = new ArrayList<>(); Deque<CourseNode> q = new ArrayDeque<>(m.getTree());
      while (!q.isEmpty()) { CourseNode n = q.pop(); if (n.children() != null) q.addAll(n.children());
        if (n.actions() == null) continue;
        for (CourseAction act : n.actions()) {
          CourseValidationResult r = switch (act.directive()) {
            case CMD, CAS -> v.validateCommand(app, act.value());
            case OPEN -> v.validateOpen(act);
            default -> CourseValidationResult.accept(); };
          if (!r.isAccepted()) { System.out.println("REJECT " + r.message()); return; }
          if (act.directive() == CourseAction.Directive.OPEN) {
            try { ri.invoke(ex, act.value(), ".ggb"); } catch (InvocationTargetException e) { System.out.println("REJECT " + e.getCause()); return; } }
          warn.addAll(r.warnings()); } }
      System.out.println(warn.isEmpty() ? "ACCEPT" : "ACCEPT_WITH_WARNING " + String.join(" | ", warn));
    } catch (Throwable t) { System.out.println("REJECT " + t.getClass().getSimpleName() + ": " + t.getMessage()); }
    System.exit(0);
  }
}
