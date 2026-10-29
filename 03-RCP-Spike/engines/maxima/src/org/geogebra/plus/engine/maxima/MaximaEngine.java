/*
 * WIMS-derived material in this file is based on src/Interfaces/maxima.c from
 * wims4win, Copyright (C) 1998-2003 XIAO, Gang of Universite de Nice - Sophia
 * Antipolis. The original file is licensed under GNU GPL version 2 or (at
 * your option) any later version. See engines/licenses/WIMS-INTERFACES.md.
 */
package org.geogebra.plus.engine.maxima;

import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.geogebra.plus.compute.api.ComputeCapability;
import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeException;
import org.geogebra.plus.compute.api.ExternalComputeException.Code;
import org.geogebra.plus.compute.runtime.SubprocessEngine;

/** One-shot Maxima process using WIMS maxima.c configuration, filters, and output rules. */
public final class MaximaEngine extends SubprocessEngine {

    // Verbatim command header from WIMS src/Interfaces/maxima.c (GPL-2.0-or-later).
    static final String WIMS_HEADER = "\n" + """
            display2d:false;
            letrat:true;
            keepfloat:true;
            rombergmin:5;
            rombergtol:1.E-6;
            rombergit:13;
            simpsum:true;
            triginverses:true; logabs:true;
            e:%e;pi:%pi;Pi:%pi;PI:%pi;I:%i;i:%i;
            ln:log;sh:sinh;ch:cosh;th:tanh;
            arctan:atan;arcsin:asin;arccos:acos;
            tg:tan;arctg:atan;
            argsh:asinh;argch:acosh;argth:atanh;
            Argsh:asinh;Argch:acosh;Argth:atanh;
            cotan:cot;ctg:cot;
            log10(x):=block([],return(log(x)/log(10)));
            log2(x):=block([],return(log(x)/log(2)));
            lg(x):=log10(x);
            sgn:sign;
            nolabels:true; kill(labels);
            """;

    // Exact WIMS maxima.c illegal[] and illpart[] values (preserved verbatim).
    static final String[] WIMS_ILLEGAL = {
            "system", "describe", "example", "save", "fassave", "stringout", "batcon",
            "batcount", "cursordisp", "direc", "readonly", "with_stdout", "pscom",
            "demo", "ttyintfun", "bug"
    };
    static final String[] WIMS_ILLPART = { "file", "debug", "plot", "load", "store", "batch" };
    static final String WIMS_QUIT = "\nquit();\n";
    private static final Pattern ENGINE_PROMPT = Pattern.compile("(?m)^\\(%([io])\\d+\\)\\s*");

    @Override
    public String getEngineId() {
        return "maxima";
    }

    @Override
    public Set<ComputeCapability> getCapabilities() {
        return Set.of(ComputeCapability.SYMBOLIC_MATH);
    }

    @Override
    protected List<String> executableCandidates() {
        return isWindows()
                ? List.of("maxima.exe", "maxima.bat", "maxima.cmd", "maxima")
                : List.of("maxima");
    }

    @Override
    protected String validateCommand(String command) throws ExternalComputeException {
        String cleaned = normalizeControls(command).replace('_', 'K').replace('?', ' ')
                .toLowerCase(Locale.ROOT).stripTrailing();
        if (cleaned.isBlank()) {
            throw new ExternalComputeException(Code.INVALID_REQUEST, "Maxima command is empty after cleanup");
        }
        // The source C check_parm() lowercases and mutates blocked tokens. This port rejects the same
        // token lists outright rather than sending a deliberately corrupted expression to the engine.
        String searchable = normalizeControls(command).replace('?', ' ').toLowerCase(Locale.ROOT);
        for (String forbidden : WIMS_ILLPART) {
            if (searchable.contains(forbidden)) {
                throw new ExternalComputeException(Code.COMMAND_REJECTED,
                        "Maxima command contains a WIMS-blocked term: " + forbidden);
            }
        }
        for (String forbidden : WIMS_ILLEGAL) {
            if (containsWord(searchable, forbidden)) {
                throw new ExternalComputeException(Code.COMMAND_REJECTED,
                        "Maxima command contains a WIMS-blocked command: " + forbidden);
            }
        }
        if (!cleaned.endsWith(";")) {
            cleaned += ";";
        }
        return cleaned;
    }

    @Override
    protected Request prepareRequest(Path executable, String validatedCommand,
            ComputeContext context) {
        String script = "fpprec:" + context.precision() + ";\n"
                + WIMS_HEADER + validatedCommand + "\n" + WIMS_QUIT;
        return request(executable, executableArguments(), script, null, null);
    }

    @Override
    protected ComputeResult createResult(Request request, ProcessOutput output, Duration elapsed) {
        return ComputeResult.text(getEngineId(), parseOutput(output.stdout()), elapsed);
    }

    static String parseOutput(String stdout) {
        String cleaned = stdout.replace("\r", "");
        Matcher matcher = ENGINE_PROMPT.matcher(cleaned);
        List<Prompt> prompts = new ArrayList<>();
        while (matcher.find()) {
            prompts.add(new Prompt(matcher.group(1).charAt(0), matcher.start(), matcher.end()));
        }
        List<String> results = new ArrayList<>();
        for (int index = 0; index < prompts.size(); index++) {
            Prompt prompt = prompts.get(index);
            if (prompt.kind() != 'o') {
                continue;
            }
            int end = index + 1 < prompts.size() ? prompts.get(index + 1).start() : cleaned.length();
            String output = normalizeOutput(cleaned.substring(prompt.end(), end));
            if (!output.isEmpty()) {
                results.add(output);
            }
        }
        return String.join("\n", results);
    }

    private record Prompt(char kind, int start, int end) {
    }

    private static String normalizeOutput(String output) {
        String value = output.replace('%', ' ').replace('\n', ' ').replace('\t', ' ')
                .replaceAll("\\s+", " ").strip();
        value = removeOuterBrackets(value);
        Matcher exponent = Pattern.compile("(?i)(?<=\\d)b(?=-|\\d)").matcher(value);
        value = exponent.replaceAll("E");
        return value.replaceAll("(?i)b0(?!\\d)", "");
    }

    private static String removeOuterBrackets(String value) {
        if (value.length() < 2 || value.charAt(0) != '[' || value.charAt(value.length() - 1) != ']') {
            return value;
        }
        int depth = 0;
        for (int index = 0; index < value.length(); index++) {
            if (value.charAt(index) == '[') {
                depth++;
            } else if (value.charAt(index) == ']') {
                depth--;
                if (depth < 0 || depth == 0 && index != value.length() - 1) {
                    return value;
                }
            }
        }
        return depth == 0 ? value.substring(1, value.length() - 1).strip() : value;
    }

    private static boolean containsWord(String text, String word) {
        return Pattern.compile("(?<![a-z0-9])" + Pattern.quote(word) + "(?![a-z0-9])")
                .matcher(text).find();
    }

    private static boolean isWindows() {
        return System.getProperty("os.name", "").toLowerCase(Locale.ROOT).startsWith("windows");
    }
}
