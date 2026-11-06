package org.geogebra.plus.wims;

import java.net.URI;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * Immutable session state extracted from a WIMS {@code cmd=new} form. It stores only
 * form metadata and allowed answer field names; it never stores the student's answers.
 */
public final class WimsSession {
    private final URI endpoint;
    private final String module;
    private final String sessionId;
    private final String language;
    private final Map<String, String> hiddenFields;
    private final Set<String> answerFields;

    WimsSession(URI endpoint, String module, String sessionId, String language,
            Map<String, String> hiddenFields, Set<String> answerFields) {
        this.endpoint = Objects.requireNonNull(endpoint, "endpoint");
        this.module = Objects.requireNonNull(module, "module");
        this.sessionId = Objects.requireNonNull(sessionId, "sessionId");
        this.language = Objects.requireNonNull(language, "language");
        this.hiddenFields = Collections.unmodifiableMap(new LinkedHashMap<>(hiddenFields));
        this.answerFields = Collections.unmodifiableSet(new LinkedHashSet<>(answerFields));
    }

    public URI getEndpoint() {
        return endpoint;
    }

    public String getModule() {
        return module;
    }

    public String getSessionId() {
        return sessionId;
    }

    public String getLanguage() {
        return language;
    }

    public Set<String> getAnswerFields() {
        return answerFields;
    }

    Map<String, String> hiddenFields() {
        return hiddenFields;
    }
}
