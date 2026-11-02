package org.geogebra.plus.course;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import org.geogebra.common.kernel.arithmetic.Command;
import org.geogebra.common.kernel.arithmetic.ExpressionValue;
import org.geogebra.common.kernel.arithmetic.ExpressionNode;
import org.geogebra.common.kernel.arithmetic.ValidExpression;
import org.geogebra.common.kernel.commands.Commands;
import org.geogebra.common.main.App;
import org.geogebra.common.plugin.GgbAPI;
import org.geogebra.plus.course.CourseNode.Check;
import org.geogebra.plus.course.CourseNode.CheckType;
import org.geogebra.plus.course.CourseNode.NumberRange;

/** Post-parse allowlist enforcement and non-authoritative formative checks. */
public final class StepValidator {

    static final int MAX_SEQUENCE_ITERATIONS = 1_000;
    static final long MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE = 10_000;
    private static final int MAX_EXPRESSION_DEPTH = 256;
    private static final String TRUSTED_OPEN_WARNING = "This .ggb file is explicitly trusted but its embedded scripts "
            + "are not scanned; scripts may execute when it is opened.";

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
    public CourseValidationResult validateCommand(App app, String source) throws Exception {
        if (app == null) {
            return CourseValidationResult.reject("GeoGebra application is unavailable.");
        }
        if (source == null || source.isBlank()) {
            return CourseValidationResult.reject("Command must not be empty.");
        }

        ValidExpression expression = app.getKernel().getAlgebraProcessor()
                .getValidExpressionNoExceptionHandling(source);
        if (expression == null) {
            return CourseValidationResult.reject("GeoGebra could not parse the course command.");
        }

        ValidationState state = new ValidationState();
        validateExpressionTree(expression, 0, state);
        if (state.rejection != null) {
            return CourseValidationResult.reject(state.rejection);
        }
        long generatedItems = sequenceGeneratedItems(expression, 0, state);
        if (!state.sequenceBudget.add(generatedItems)) {
            return CourseValidationResult.reject("Course directive exceeds the total Sequence output budget of "
                    + MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE + " items.");
        }
        return CourseValidationResult.acceptWithWarnings(state.warnings);
    }

    /**
     * OPEN stays fail-closed until archive scanning exists. Explicit teacher trust
     * permits the action, but requires the host UI to warn before the file loads.
     */
    public CourseValidationResult validateOpen(CourseAction action) {
        if (action == null || action.directive() != CourseAction.Directive.OPEN) {
            return CourseValidationResult.reject("Expected an OPEN course action.");
        }
        if (!action.trustedGgb()) {
            return CourseValidationResult.reject("OPEN is blocked for untrusted .ggb files until script scanning is available.");
        }
        return CourseValidationResult.acceptWithWarning(TRUSTED_OPEN_WARNING);
    }

    private static void validateExpressionTree(ExpressionValue value, int depth, ValidationState state) {
        if (state.rejection != null) {
            return;
        }
        if (depth > MAX_EXPRESSION_DEPTH) {
            state.rejection = "Course command expression exceeds the maximum validation depth.";
            return;
        }
        state.nodes++;
        if (state.nodes > MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE) {
            state.rejection = "Course command expression exceeds the validation complexity limit.";
            return;
        }

        if (value instanceof Command command) {
            Commands resolved = Commands.stringToCommand(command.getName());
            if (resolved == null || !isAllowed(resolved)) {
                state.rejection = "Course command is not allowed: " + command.getName();
                return;
            }
            if (resolved == Commands.Sequence) {
                try {
                    long iterations = sequenceIterations(command);
                    state.sequenceIterations.put(command, iterations);
                    // Q3b (#21): valid near-limit sequences are plain ACCEPT; warnings remain for other Q4 cases.
                } catch (IllegalArgumentException error) {
                    state.rejection = error.getMessage();
                    return;
                }
            }
        }

        for (int index = 0; index < value.getChildCount(); index++) {
            validateExpressionTree(value.getChild(index), depth + 1, state);
            if (state.rejection != null) {
                return;
            }
        }
    }

    private static long sequenceGeneratedItems(ExpressionValue value, int depth, ValidationState state) {
        if (depth > MAX_EXPRESSION_DEPTH) {
            return MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE + 1;
        }
        if (value instanceof Command command
                && Commands.stringToCommand(command.getName()) == Commands.Sequence) {
            Long iterations = state.sequenceIterations.get(command);
            if (iterations == null) {
                return MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE + 1;
            }
            long nestedItems = sequenceGeneratedItems(command.getArgument(0), depth + 1, state);
            long generated = SequenceBudget.estimateGeneratedItems(iterations, nestedItems);
            for (int index = 1; index < command.getChildCount(); index++) {
                generated = SequenceBudget.saturatingAdd(generated,
                        sequenceGeneratedItems(command.getChild(index), depth + 1, state));
            }
            return generated;
        }
        long generated = 0;
        for (int index = 0; index < value.getChildCount(); index++) {
            generated = SequenceBudget.saturatingAdd(generated,
                    sequenceGeneratedItems(value.getChild(index), depth + 1, state));
            if (generated > MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE) {
                return generated;
            }
        }
        return generated;
    }

    private static long sequenceIterations(Command command) {
        int count = command.getArgumentNumber();
        if (count != 4 && count != 5) {
            throw new IllegalArgumentException("Sequence requires explicit start and end bounds in a course command.");
        }
        double start = constantNumber(command.getArgument(2), "start");
        double end = constantNumber(command.getArgument(3), "end");
        double step = count == 5 ? constantNumber(command.getArgument(4), "step") : 1.0;
        return estimateSequenceIterations(start, end, step);
    }

    private static double constantNumber(ExpressionNode expression, String name) {
        if (expression == null || !expression.isConstant()) {
            throw new IllegalArgumentException("Sequence " + name + " bound must be a static numeric constant.");
        }
        double value;
        try {
            value = expression.evaluateDouble();
        } catch (RuntimeException error) {
            throw new IllegalArgumentException("Sequence " + name + " bound is not a numeric constant.", error);
        }
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException("Sequence " + name + " bound must be finite.");
        }
        return value;
    }

    static long estimateSequenceIterations(double start, double end, double step) {
        if (!Double.isFinite(start) || !Double.isFinite(end) || !Double.isFinite(step) || step == 0) {
            throw new IllegalArgumentException("Sequence bounds must be finite and the step must be non-zero.");
        }
        if ((step > 0 && end < start) || (step < 0 && end > start)) {
            return 0;
        }
        double span = Math.abs(end - start);
        if (!Double.isFinite(span)) {
            throw new IllegalArgumentException("Sequence range is too large.");
        }
        // ceil is intentionally conservative at floating-point endpoints.
        double upperBound = Math.ceil(span / Math.abs(step)) + 1;
        if (!Double.isFinite(upperBound) || upperBound > MAX_SEQUENCE_ITERATIONS) {
            throw new IllegalArgumentException("Sequence exceeds the maximum of " + MAX_SEQUENCE_ITERATIONS
                    + " iterations.");
        }
        return (long) upperBound;
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

    private static final class ValidationState {
        private final SequenceBudget sequenceBudget = new SequenceBudget();
        private final List<String> warnings = new ArrayList<>();
        private final Map<Command, Long> sequenceIterations = new IdentityHashMap<>();
        private String rejection;
        private int nodes;
    }

    static final class SequenceBudget {
        private long generatedItems;

        boolean add(long amount) {
            if (amount > MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE - generatedItems) {
                return false;
            }
            generatedItems += amount;
            return true;
        }

        static long estimateGeneratedItems(long iterations, long nestedItems) {
            if (iterations < 0 || nestedItems < 0) {
                throw new IllegalArgumentException("Sequence budget inputs must be non-negative.");
            }
            long perIteration = nestedItems == 0 ? 1 : nestedItems;
            if (iterations == 0 || perIteration == 0) {
                return 0;
            }
            if (iterations > MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE / perIteration) {
                return MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE + 1;
            }
            return iterations * perIteration;
        }

        static long saturatingAdd(long left, long right) {
            if (left > MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE
                    || right > MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE - left) {
                return MAX_SEQUENCE_GENERATED_ITEMS_PER_DIRECTIVE + 1;
            }
            return left + right;
        }

        long generatedItems() {
            return generatedItems;
        }
    }
}
