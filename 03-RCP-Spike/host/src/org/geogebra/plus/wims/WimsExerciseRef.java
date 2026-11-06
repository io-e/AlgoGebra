package org.geogebra.plus.wims;

import java.net.URI;
import java.util.Locale;
import java.util.Objects;
import java.util.regex.Pattern;

/** Validated reference to one OEF exercise on a configured WIMS CGI endpoint. */
public final class WimsExerciseRef {
    private static final Pattern MODULE = Pattern.compile("[A-Za-z0-9._/-]{1,240}");
    private static final Pattern EXERCISE = Pattern.compile("[A-Za-z0-9._-]{1,80}");

    private final URI endpoint;
    private final String module;
    private final String exerciseId;
    private final Locale locale;

    public WimsExerciseRef(URI endpoint, String module, String exerciseId, Locale locale) {
        this.endpoint = validateEndpoint(endpoint);
        this.module = validateModule(module);
        this.exerciseId = validateExercise(exerciseId);
        this.locale = Objects.requireNonNull(locale, "locale");
        if (locale.getLanguage().isBlank()) {
            throw new IllegalArgumentException("locale must have a language code");
        }
    }

    public URI getEndpoint() {
        return endpoint;
    }

    public String getModule() {
        return module;
    }

    public String getExerciseId() {
        return exerciseId;
    }

    public Locale getLocale() {
        return locale;
    }

    private static URI validateEndpoint(URI value) {
        Objects.requireNonNull(value, "endpoint");
        String scheme = value.getScheme();
        if (!value.isAbsolute() || value.getHost() == null || value.getRawUserInfo() != null
                || value.getRawQuery() != null || value.getRawFragment() != null
                || !("http".equalsIgnoreCase(scheme) || "https".equalsIgnoreCase(scheme))) {
            throw new IllegalArgumentException(
                    "endpoint must be an absolute HTTP(S) URI without user-info, query, or fragment");
        }
        if ("http".equalsIgnoreCase(scheme) && !isLoopbackHost(value.getHost())) {
            throw new IllegalArgumentException("non-loopback WIMS endpoints must use HTTPS");
        }
        return value;
    }

    private static boolean isLoopbackHost(String host) {
        return "localhost".equalsIgnoreCase(host) || "127.0.0.1".equals(host)
                || "::1".equals(host) || "[::1]".equalsIgnoreCase(host);
    }

    private static String validateModule(String value) {
        Objects.requireNonNull(value, "module");
        if (!MODULE.matcher(value).matches() || value.contains("..") || value.startsWith("/")) {
            throw new IllegalArgumentException("invalid WIMS module path");
        }
        return value;
    }

    private static String validateExercise(String value) {
        Objects.requireNonNull(value, "exerciseId");
        if (!EXERCISE.matcher(value).matches()) {
            throw new IllegalArgumentException("invalid WIMS exercise identifier");
        }
        return value;
    }
}
