/*
 * WIMS-derived material in this file is based on src/Interfaces/pari.c from
 * wims4win, Copyright (C) 1998-2003 XIAO, Gang of Universite de Nice - Sophia
 * Antipolis. The original file is licensed under GNU GPL version 2 or (at
 * your option) any later version. See engines/licenses/WIMS-INTERFACES.md.
 */
package org.geogebra.plus.engine.pari;

import java.nio.file.Path;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.geogebra.plus.compute.api.ComputeCapability;
import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;
import org.geogebra.plus.compute.runtime.SubprocessEngine;

/** One-shot PARI/GP process using the WIMS pari.c header, filter, and output rules. */
public final class PariGPEngine extends SubprocessEngine {

    // Verbatim command header from WIMS src/Interfaces/pari.c (GPL-2.0-or-later).
    /** WIMS stringprinter for this interface. */
    static final String WIMS_STRINGPRINTER = "print(\"%s\")\n";

    static final String WIMS_HEADER = """
            default(output,0)
            default(secure,1)
            alias(ln,log)
            alias(pi,Pi)
            alias(euler,Euler)
            alias(PI,Pi)
            i=I
            e=exp(1)
            E=exp(1)
            sec(x)=1/cos(x);
            csc(x)=1/sin(x);
            lg(x)=log(x)/log(10);
            log2(x)=log(x)/log(10);
            alias(log10,lg)
            alias(sgn,sign)
            alias(ch,cosh)
            alias(sh,sinh)
            alias(th,tanh)
            alias(arccos,acos)
            alias(arcsin,asin)
            alias(tg,tan)
            alias(arctan,atan)
            alias(arctg,atan)
            alias(Argch,acosh)
            alias(Argsh,asinh)
            alias(Argth,atanh)
            alias(argch,acosh)
            alias(argsh,asinh)
            alias(argth,atanh)
            alias(cot,cotan)
            alias(ctg,cotan)
            alias(rint,round)
            alias(RANDOM,random)
            alias(SOLVE,solve)
            alias(parirandom,random)
            alias(parisolve,solve)
            """;

    // Exact WIMS pari.c illegal[] and illpart[] values. illegal[] is empty.
    static final String[] WIMS_ILLEGAL = {};
    static final String[] WIMS_ILLPART = { "plot", "write", "help" };
    static final String WIMS_QUIT = "\nquit\n";
    // BUG-006 (user decision 2026-10-29, 02-Cdc/Decisions_PARI_Forbidden_GROK_V1.md): deliberate deviation from WIMS
    // (illegal[] empty). Defence in depth on top of default(secure,1), which stays in the header: gp functions that run
    // shell commands or load native code. Verified with '?name' in gp 2.17.2 (systemstr does not exist).
    // Matched as whole words, so alias(s,system) is also rejected. "eval" is blocked too: eval(Str("ins","tall(..)"))
    // rebuilds a blocked name at run time, and in secure mode gp only *asks* before install(), the next stdin line
    // confirms it (reproduced 2026-10-29 with gp 2.17.2 through the engine: native getpid loaded). Not a sandbox claim (D-ENG-03).
    static final String[] AGB_ILLEGAL = { "system", "extern", "externstr", "fileextern", "install", "eval" };

    @Override
    public String getEngineId() {
        return "pari";
    }

    @Override
    public Set<ComputeCapability> getCapabilities() {
        return Set.of(ComputeCapability.SYMBOLIC_MATH, ComputeCapability.NUMBER_THEORY);
    }

    @Override
    protected List<String> executableCandidates() {
        return isWindows() ? List.of("gp.exe", "gp") : List.of("gp");
    }

    @Override
    protected List<String> executableArguments() {
        return List.of("-f", "-q");
    }

    @Override
    protected String validateCommand(String command) throws ExternalComputeException {
        String normalized = normalizeControls(command).replace('_', 'K');
        String lower = normalized.toLowerCase(Locale.ROOT);
        for (String forbidden : WIMS_ILLPART) {
            if (lower.contains(forbidden)) {
                throw new ExternalComputeException(Code.COMMAND_REJECTED,
                        "PARI/GP command contains a WIMS-blocked term: " + forbidden);
            }
        }
        for (String forbidden : WIMS_ILLEGAL) {
            if (containsWord(lower, forbidden)) {
                throw new ExternalComputeException(Code.COMMAND_REJECTED,
                        "PARI/GP command contains a WIMS-blocked command: " + forbidden);
            }
        }
        for (String forbidden : AGB_ILLEGAL) {
            if (containsWord(lower, forbidden)) {
                throw new ExternalComputeException(Code.COMMAND_REJECTED,
                        "PARI/GP command contains a blocked command (AlgoGebra defence in depth, BUG-006): " + forbidden);
            }
        }
        for (int index = 0; index < normalized.length(); index++) {
            if (index != 0 && normalized.charAt(index - 1) != '\n') {
                continue;
            }
            int next = index;
            while (next < normalized.length()
                    && (normalized.charAt(next) == ' ' || normalized.charAt(next) == '\t')) {
                next++;
            }
            if (next < normalized.length() && normalized.charAt(next) == '\\') {
                char escape = next + 1 < normalized.length() ? normalized.charAt(next + 1) : '\0';
                if (escape != '\\' && escape != 'v' && escape != 'p') {
                    throw new ExternalComputeException(Code.COMMAND_REJECTED,
                            "PARI/GP escape commands are blocked except \\\\, \\v, and \\p");
                }
            }
        }
        return normalized;
    }

    @Override
    protected Request prepareRequest(Path executable, String validatedCommand,
            ComputeContext context) {
        // Kept deviations from WIMS pari.c (GROK_V1 review): setrand() makes runs reproducible from
        // ComputeContext.randomSeed (WIMS seeds through its own environment); \\e1 is required because gp
        // prints no "? " prompts on a non-TTY pipe and parseOutput splits results on echoed prompts; "-f"
        // skips any gprc, so WIMS's GPRC=../.gprc (a WIMS-runtime file) is intentionally not reproduced.
        // WIMS putparm(): header, then start marker / command / end marker (BUG-001 fix, GROK_V1).
        WimsMarkers markers = newMarkers("pari");
        String script = "setrand(" + context.randomSeed() + ");\n"
                + "\\p " + context.precision() + "\n"
                + "\\ps " + context.seriesLength() + "\n"
                + "\\e1\n"
                + WIMS_HEADER
                + wrapWithMarkers(validatedCommand, markers, WIMS_STRINGPRINTER) + WIMS_QUIT;
        return request(executable, executableArguments(), script, markers);
    }

    @Override
    protected ComputeResult createResult(Request request, ProcessOutput output, Duration elapsed)
            throws ExternalComputeException {
        // WIMS readresult(): parse only the slice between the last start marker and the end marker.
        return ComputeResult.text(getEngineId(),
                parseOutput(extractOrFail(output.stdout(), request.markers())), elapsed);
    }

    static String parseOutput(String stdout) {
        List<String> results = new java.util.ArrayList<>();
        StringBuilder current = null;
        for (String line : stdout.replace("\r", "").split("\n", -1)) {
            String promptLine = line.stripLeading();
            if (promptLine.contains("Good bye!")) {
                break;
            }
            if (promptLine.startsWith("? ") || promptLine.equals("?")) {
                flushResult(current, results);
                current = new StringBuilder(); // The prompt line echoes the submitted command.
                continue;
            }
            if (current == null) {
                continue; // Ignore a banner emitted before the first GP prompt.
            }
            String value = line.strip();
            if (value.matches("%\\d+\\s*=.*")) {
                value = value.replaceFirst("^%\\d+\\s*=\\s*", "");
            }
            if (!value.isEmpty()) {
                if (!current.isEmpty()) {
                    current.append(' ');
                }
                current.append(value);
            }
        }
        flushResult(current, results);
        return String.join("\n", results);
    }

    private static void flushResult(StringBuilder current, List<String> results) {
        if (current == null || current.isEmpty()) {
            return;
        }
        String value = current.toString().replaceAll("\\s+", " ").strip();
        value = removeWrapper(value, "Mat(");
        value = removeWrapper(value, "Vecsmall(");
        value = removeOuterBrackets(value);
        value = stripTrailingDecimalZeros(value);
        if (!value.isEmpty()) {
            results.add(value);
        }
    }

    private static String removeWrapper(String value, String wrapper) {
        if (!value.startsWith(wrapper) || !value.endsWith(")")) {
            return value;
        }
        int depth = 0;
        for (int index = wrapper.length() - 1; index < value.length(); index++) {
            char character = value.charAt(index);
            if (character == '(') {
                depth++;
            } else if (character == ')') {
                depth--;
                if (depth == 0 && index != value.length() - 1) {
                    return value;
                }
            }
        }
        return depth == 0 ? value.substring(wrapper.length(), value.length() - 1) : value;
    }

    private static String removeOuterBrackets(String value) {
        if (value.length() < 2 || value.charAt(0) != '[' || value.charAt(value.length() - 1) != ']') {
            return value;
        }
        int depth = 0;
        for (int index = 0; index < value.length(); index++) {
            char character = value.charAt(index);
            if (character == '[') {
                depth++;
            } else if (character == ']') {
                depth--;
                if (depth == 0 && index != value.length() - 1) {
                    return value;
                }
            }
        }
        return depth == 0 ? value.substring(1, value.length() - 1) : value;
    }

    private static String stripTrailingDecimalZeros(String value) {
        java.util.regex.Matcher matcher = java.util.regex.Pattern
                .compile("(?<![\\w.])\\d+\\.\\d+(?:[Ee][+-]?\\d+)?")
                .matcher(value);
        StringBuffer cleaned = new StringBuffer();
        while (matcher.find()) {
            String number = matcher.group();
            int exponent = Math.max(number.indexOf('E'), number.indexOf('e'));
            String mantissa = exponent < 0 ? number : number.substring(0, exponent);
            String suffix = exponent < 0 ? "" : number.substring(exponent);
            mantissa = mantissa.replaceFirst("0+$", "").replaceFirst("\\.$", ".0");
            matcher.appendReplacement(cleaned, java.util.regex.Matcher.quoteReplacement(mantissa + suffix));
        }
        matcher.appendTail(cleaned);
        return cleaned.toString();
    }

    private static boolean containsWord(String text, String word) {
        return java.util.regex.Pattern.compile("(?<![a-z0-9])" + java.util.regex.Pattern.quote(word)
                + "(?![a-z0-9])").matcher(text).find();
    }

    private static boolean isWindows() {
        return System.getProperty("os.name", "").toLowerCase(Locale.ROOT).startsWith("windows");
    }
}
