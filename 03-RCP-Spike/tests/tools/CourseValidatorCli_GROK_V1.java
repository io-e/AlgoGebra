package org.geogebra.plus.course;
// GROK_V1 test-side adapter: COURSE_VALIDATOR for suite 16 using Codex PR #11 classes (no GeoGebra App).
// Real code used: CourseModel.load (schema/limits/trustedGgb), StepValidator.isAllowed (allow-list),
// DirectiveExecutor.resolveInput (OPEN path rules incl. toRealPath) + its "untrusted OPEN disabled" policy.
// APPROXIMATION: command names are tokenized by regex (Name( / Name[) + Commands.stringToCommand, NOT the
// post-parse walk of StepValidator.validateCommand (needs a live App), so localized names are not resolved.
import java.lang.reflect.*; import java.nio.file.*; import java.util.*; import java.util.regex.*;
import org.geogebra.common.kernel.commands.Commands;
public final class CourseValidatorCli_GROK_V1 {
  static final Pattern NAME = Pattern.compile("([\\p{L}][\\p{L}\\p{N}]*)\\s*[\\[(]");
  public static void main(String[] a) {
    try { Path f = Path.of(a[0]); CourseModel m = CourseModel.load(f);
      DirectiveExecutor ex = new DirectiveExecutor(null, f, null, null, null, null);
      Method ri = DirectiveExecutor.class.getDeclaredMethod("resolveInput", String.class, String.class); ri.setAccessible(true);
      Deque<CourseNode> q = new ArrayDeque<>(m.getTree());
      while (!q.isEmpty()) { CourseNode n = q.pop(); if (n.children() != null) q.addAll(n.children());
        if (n.actions() == null) continue;
        for (CourseAction act : n.actions()) switch (act.directive()) {
          case CMD, CAS -> { Matcher mt = NAME.matcher(act.value()); while (mt.find()) {
              Commands c = Commands.stringToCommand(mt.group(1));
              if (c != null && !StepValidator.isAllowed(c)) { System.out.println("REJECT command " + mt.group(1)); return; } } }
          case OPEN -> { if (!act.trustedGgb()) { System.out.println("REJECT OPEN untrusted (disabled until scanner)"); return; }
              try { ri.invoke(ex, act.value(), ".ggb"); } catch (InvocationTargetException e) { System.out.println("REJECT " + e.getCause()); return; } }
          default -> { } } }
      System.out.println("ACCEPT");
    } catch (Throwable t) { System.out.println("REJECT " + t.getClass().getSimpleName() + ": " + t.getMessage()); }
  }
}
