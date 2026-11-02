package org.geogebra.plus.course;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.geogebra.common.kernel.arithmetic.Command;
import org.geogebra.common.kernel.arithmetic.ValidExpression;
import org.geogebra.common.kernel.commands.Commands;
import org.geogebra.common.main.App;
import org.geogebra.common.plugin.GgbAPI;
import org.geogebra.plus.course.CourseNode.Check;
import org.geogebra.plus.course.CourseNode.CheckType;
import org.geogebra.plus.course.CourseNode.NumberRange;

/** Post-parse allowlist enforcement and non-authoritative formative checks. */
public final class StepValidator {

    private static final Set<Commands> ALLOWED_SCRIPTING = EnumSet.of(
            Commands.SetColor,
            Commands.SetPointStyle,
            Commands.SetPointSize,
            Commands.SetLineThickness,
            Commands.SetLineStyle,
            Commands.SetCaption,
            Commands.ShowLabel,
            Commands.SetFixed,
            Commands.Slider,
            Commands.Checkbox);

    private static final Set<Commands> BLOCKED_OVERRIDES = Set.of(
            Commands.Delete,
            Commands.SetValue,
            Commands.Rename,
            Commands.Pan,
            Commands.ZoomIn,
            Commands.ZoomOut,
            Commands.CenterView,
            Commands.SetPerspective);

    /**
     * Parse with GeoGebra first, then inspect every nested command node. This
     * makes localized command names and commands nested in expressions subject
     * to the same policy as top-level commands.
     */
    public void validateCommand(App app, String source) throws Exception {
        if (app == null) {
            throw new IllegalStateException("GeoGebra application is unavailable");
        }
        if (source == null || source.isBlank()) {
            throw new IllegalArgumentException("Command must not be empty");
        }

        ValidExpression expression = app.getKernel().getAlgebraProcessor()
                .getValidExpressionNoExceptionHandling(source);
        List<String> rejected = new ArrayList<>(1);
        expression.any(value -> {
            if (value instanceof Command command) {
                Commands resolved = Commands.stringToCommand(command.getName());
                if (resolved == null || !isAllowed(resolved)) {
                    rejected.add(command.getName());
                    return true;
                }
            }
            return false;
        });
        if (!rejected.isEmpty()) {
            throw new SecurityException("Course command is not allowed: " + rejected.get(0));
        }
    }

    /** Applies the selected check locally; it never creates an authoritative grade. */
    public boolean check(Check check, GgbAPI api) {
        if (check == null || api == null) {
            return false;
        }
        String variable = check.variable();
        if (!isSafeObjectName(variable)) {
            return false;
        }
        if (check.type() == CheckType.OBJECT_EXISTS) {
            return api.isDefined(variable);
        }
        if (check.type() == CheckType.CAS_EQUALS) {
            if (!(check.expected() instanceof String expected)) {
                return false;
            }
            String actual = api.evalCommandCAS(variable, null);
            return actual != null && normalizeCas(actual).equals(normalizeCas(expected));
        }
        if (!api.isDefined(variable)) {
            return false;
        }
        double actual = api.getValue(variable);
        if (!Double.isFinite(actual)) {
            return false;
        }
        if (check.type() == CheckType.VALUE_EQUALS) {
            return check.expected() instanceof Number expected
                    && Math.abs(actual - expected.doubleValue()) <= check.tolerance();
        }
        if (check.type() == CheckType.VALUE_RANGE && check.expected() instanceof NumberRange range) {
            return actual >= range.min() && actual <= range.max();
        }
        return false;
    }

    public static boolean isAllowed(Commands command) {
        if (command == null || BLOCKED_OVERRIDES.contains(command)) {
            return false;
        }
        return command.getTable() != Commands.TABLE_SCRIPTING || ALLOWED_SCRIPTING.contains(command);
    }

    private static boolean isSafeObjectName(String value) {
        return value != null && value.matches("[\\p{L}][\\p{L}\\p{N}_]*");
    }

    private static String normalizeCas(String value) {
        return value.toLowerCase(Locale.ROOT).replaceAll("\\s+", "").replace("*", "");
    }
}
