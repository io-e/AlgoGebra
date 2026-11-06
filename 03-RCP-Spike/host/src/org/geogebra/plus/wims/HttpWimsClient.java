package org.geogebra.plus.wims;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.net.CookieManager;
import java.net.CookiePolicy;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Flow;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * OEF grader adapter for stock WIMS {@code cmd=new} / {@code cmd=reply}.
 * Requests use strict Windows-1252 form encoding; replies are decoded using their
 * declared charset (Windows-1252 is the observed WIMS HTML default).
 */
public final class HttpWimsClient implements WimsClient {
    private static final String FORM_CONTENT_TYPE =
            "application/x-www-form-urlencoded; charset=windows-1252";
    private static final String JSON_BEGIN = "ALGOGEBRA_JSON_BEGIN";
    private static final String JSON_END = "ALGOGEBRA_JSON_END";
    private static final String JSON_HOOK = "algogebra_json";
    private static final Pattern FORM = Pattern.compile("(?is)<form\\b[^>]*>(.*?)</form\\s*>");
    private static final Pattern INPUT = Pattern.compile("(?is)<input\\b([^>]*)>");
    private static final Pattern ATTRIBUTE = Pattern.compile(
            "(?is)([A-Za-z_:][A-Za-z0-9_:.-]*)\\s*(?:=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s>]+)))?");
    private static final Pattern ANSWER_FIELD = Pattern.compile("(?:reply|choice)\\d+");
    private static final Pattern CHARSET = Pattern.compile(
            "(?i)(?:^|;)\\s*charset\\s*=\\s*(?:\"([^\"]+)\"|'([^']+)'|([^;\\s]+))");
    private static final Duration DEFAULT_TIMEOUT = Duration.ofSeconds(20);
    private static final int DEFAULT_MAX_RESPONSE_BYTES = 4 * 1024 * 1024;
    private static final int MAX_FORM_BYTES = 512 * 1024;
    private static final int MAX_ANSWER_CHARS = 128 * 1024;
    private static final int MAX_ANSWER_FIELDS = 100;

    private final HttpClient httpClient;
    private final Duration timeout;
    private final int maxResponseBytes;

    public HttpWimsClient() {
        this(HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                // Do not forward student answers to a redirect-selected host.
                .followRedirects(HttpClient.Redirect.NEVER)
                .cookieHandler(new CookieManager(null, CookiePolicy.ACCEPT_ORIGINAL_SERVER))
                .build(), DEFAULT_TIMEOUT, DEFAULT_MAX_RESPONSE_BYTES);
    }

    public HttpWimsClient(HttpClient httpClient, Duration timeout, int maxResponseBytes) {
        this.httpClient = Objects.requireNonNull(httpClient, "httpClient");
        this.timeout = Objects.requireNonNull(timeout, "timeout");
        if (timeout.isZero() || timeout.isNegative()) {
            throw new IllegalArgumentException("timeout must be positive");
        }
        if (maxResponseBytes < 1024) {
            throw new IllegalArgumentException("maxResponseBytes must be at least 1024");
        }
        this.maxResponseBytes = maxResponseBytes;
    }

    @Override
    public WimsSession createSession(WimsExerciseRef exercise, Locale locale) throws WimsException {
        if (exercise == null || locale == null || locale.getLanguage().isBlank()) {
            throw new WimsException(WimsError.INVALID_REQUEST,
                    "A WIMS exercise and locale with a language code are required");
        }
        Map<String, String> parameters = new LinkedHashMap<>();
        parameters.put("module", exercise.getModule());
        parameters.put("cmd", "new");
        parameters.put("lang", locale.getLanguage().toLowerCase(Locale.ROOT));
        parameters.put("exo", exercise.getExerciseId());
        Response response = send(exercise.getEndpoint(), parameters);
        requireSuccess(response, "WIMS cmd=new");
        String html = decode(response);
        FormFields form = parseExerciseForm(html);
        String sessionId = form.hidden().get("session");
        if (sessionId == null || sessionId.isBlank()) {
            sessionId = form.hidden().get("wims_session");
        }
        if (sessionId == null || sessionId.isBlank() || sessionId.length() > 512) {
            throw new WimsException(WimsError.SESSION_NOT_FOUND,
                    "WIMS cmd=new returned no usable hidden session field");
        }
        if (form.answerFields().isEmpty()) {
            throw new WimsException(WimsError.ANSWER_FIELDS_NOT_FOUND,
                    "WIMS cmd=new returned no replyN or choiceN input fields");
        }
        if (form.answerFields().size() > MAX_ANSWER_FIELDS) {
            throw new WimsException(WimsError.INVALID_REQUEST,
                    "WIMS exercise exceeds the client answer-field limit");
        }
        return new WimsSession(exercise.getEndpoint(), exercise.getModule(), sessionId,
                locale.getLanguage().toLowerCase(Locale.ROOT), form.hidden(), form.answerFields());
    }

    @Override
    public GradeResult submitAnswers(WimsSession session, WimsAnswerSubmission answers)
            throws WimsException {
        if (session == null || answers == null || answers.values().isEmpty()) {
            throw new WimsException(WimsError.INVALID_REQUEST,
                    "A WIMS session and at least one answer value are required");
        }
        List<WimsFormEncoding.FormField> fields = new ArrayList<>();
        for (Map.Entry<String, String> entry : session.hiddenFields().entrySet()) {
            String name = entry.getKey();
            if (isReservedFormName(name) || ANSWER_FIELD.matcher(name).matches()) {
                continue;
            }
            fields.add(new WimsFormEncoding.FormField(name, entry.getValue()));
        }
        fields.add(new WimsFormEncoding.FormField("session", session.getSessionId()));
        fields.add(new WimsFormEncoding.FormField("lang", session.getLanguage()));
        fields.add(new WimsFormEncoding.FormField("cmd", "reply"));
        fields.add(new WimsFormEncoding.FormField("module", session.getModule()));
        // This option is deliberately added only in the reply path, never in cmd=new.
        fields.add(new WimsFormEncoding.FormField("special_parm", JSON_HOOK));

        int answerCount = 0;
        long valueChars = 0;
        for (Map.Entry<String, List<String>> entry : answers.values().entrySet()) {
            String field = entry.getKey();
            if (!ANSWER_FIELD.matcher(field).matches() || !session.getAnswerFields().contains(field)) {
                throw new WimsException(WimsError.UNKNOWN_ANSWER_FIELD,
                        "Answer field was not present in this WIMS exercise form");
            }
            if (entry.getValue().isEmpty()) {
                throw new WimsException(WimsError.INVALID_REQUEST,
                        "Answer field must contain at least one value");
            }
            for (String value : entry.getValue()) {
                if (value.length() > MAX_ANSWER_CHARS) {
                    throw new WimsException(WimsError.INVALID_REQUEST,
                            "An answer exceeds the configured size limit");
                }
                valueChars += value.length();
                if (valueChars > MAX_FORM_BYTES) {
                    throw new WimsException(WimsError.INVALID_REQUEST,
                            "The answer submission exceeds the configured size limit");
                }
                fields.add(new WimsFormEncoding.FormField(field, value));
                answerCount++;
            }
        }
        if (answerCount == 0) {
            throw new WimsException(WimsError.INVALID_REQUEST,
                    "At least one answer value is required");
        }

        byte[] body = WimsFormEncoding.encode(fields);
        if (body.length > MAX_FORM_BYTES) {
            throw new WimsException(WimsError.INVALID_REQUEST,
                    "The encoded answer submission exceeds the configured size limit");
        }
        Response response = send(session.getEndpoint(), body);
        requireSuccess(response, "WIMS cmd=reply");
        return parseGradeResponse(decode(response));
    }

    private Response send(URI endpoint, Map<String, String> form) throws WimsException {
        return send(endpoint, WimsFormEncoding.encode(form));
    }

    private Response send(URI endpoint, byte[] body) throws WimsException {
        HttpRequest request = HttpRequest.newBuilder(endpoint)
                .timeout(timeout)
                .header("Content-Type", FORM_CONTENT_TYPE)
                .header("Accept", "text/html")
                .POST(HttpRequest.BodyPublishers.ofByteArray(body))
                .build();
        try {
            HttpResponse<byte[]> response = httpClient.send(request,
                    responseInfo -> new BoundedBodySubscriber(maxResponseBytes));
            return new Response(response.statusCode(), response.headers()
                    .firstValue("Content-Type").orElse("text/html"), response.body());
        } catch (HttpTimeoutException exception) {
            throw new WimsException(WimsError.TIMEOUT,
                    "WIMS request exceeded the configured timeout", exception);
        } catch (IOException exception) {
            if (causedByResponseLimit(exception)) {
                throw new WimsException(WimsError.RESPONSE_TOO_LARGE,
                        "WIMS response exceeded the configured size limit", exception);
            }
            throw new WimsException(WimsError.NETWORK_ERROR,
                    "Could not complete the WIMS HTTP request", exception);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new WimsException(WimsError.NETWORK_ERROR,
                    "WIMS request was interrupted", exception);
        } catch (IllegalArgumentException exception) {
            throw new WimsException(WimsError.NETWORK_ERROR,
                    "Could not complete the WIMS HTTP request", exception);
        }
    }

    private static boolean causedByResponseLimit(Throwable exception) {
        for (Throwable cause = exception; cause != null; cause = cause.getCause()) {
            if (cause instanceof ResponseTooLargeException) {
                return true;
            }
        }
        return false;
    }

    private static final class BoundedBodySubscriber extends CompletableFuture<byte[]>
            implements HttpResponse.BodySubscriber<byte[]> {
        private final int limit;
        private final ByteArrayOutputStream output = new ByteArrayOutputStream();
        private Flow.Subscription subscription;

        private BoundedBodySubscriber(int limit) {
            this.limit = limit;
        }

        @Override
        public CompletionStage<byte[]> getBody() {
            return this;
        }

        @Override
        public void onSubscribe(Flow.Subscription value) {
            subscription = value;
            value.request(1);
        }

        @Override
        public void onNext(List<ByteBuffer> items) {
            try {
                for (ByteBuffer item : items) {
                    if ((long) output.size() + item.remaining() > limit) {
                        subscription.cancel();
                        completeExceptionally(new ResponseTooLargeException());
                        return;
                    }
                    byte[] chunk = new byte[item.remaining()];
                    item.get(chunk);
                    output.write(chunk, 0, chunk.length);
                }
                subscription.request(1);
            } catch (RuntimeException exception) {
                subscription.cancel();
                completeExceptionally(exception);
            }
        }

        @Override
        public void onError(Throwable throwable) {
            completeExceptionally(throwable);
        }

        @Override
        public void onComplete() {
            complete(output.toByteArray());
        }
    }

    private static void requireSuccess(Response response, String operation) throws WimsException {
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new WimsException(WimsError.HTTP_ERROR,
                    operation + " returned HTTP " + response.statusCode());
        }
    }

    private static String decode(Response response) throws WimsException {
        Charset charset = responseCharset(response.contentType());
        try {
            return charset.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(response.body())).toString();
        } catch (CharacterCodingException exception) {
            throw new WimsException(WimsError.ENCODING_ERROR,
                    "WIMS response could not be decoded using its declared charset", exception);
        }
    }

    private static Charset responseCharset(String contentType) throws WimsException {
        Matcher matcher = CHARSET.matcher(contentType);
        if (!matcher.find()) {
            return WimsFormEncoding.CHARSET;
        }
        String name = firstNonNull(matcher.group(1), matcher.group(2), matcher.group(3));
        try {
            return Charset.forName(name.trim());
        } catch (IllegalArgumentException exception) {
            throw new WimsException(WimsError.ENCODING_ERROR,
                    "WIMS response declared an unsupported charset", exception);
        }
    }

    private static FormFields parseExerciseForm(String html) throws WimsException {
        Matcher formMatcher = FORM.matcher(html);
        while (formMatcher.find()) {
            FormFields candidate = parseInputs(formMatcher.group(1));
            if (!candidate.answerFields().isEmpty()) {
                return candidate;
            }
        }
        FormFields fallback = parseInputs(html);
        if (!fallback.answerFields().isEmpty()) {
            return fallback;
        }
        return fallback;
    }

    private static FormFields parseInputs(String source) throws WimsException {
        Map<String, String> hidden = new LinkedHashMap<>();
        Set<String> answerFields = new LinkedHashSet<>();
        Matcher inputMatcher = INPUT.matcher(source);
        while (inputMatcher.find()) {
            Map<String, String> attributes = parseAttributes(inputMatcher.group(1));
            String name = attributes.get("name");
            if (name == null || name.isBlank()) {
                continue;
            }
            String type = attributes.getOrDefault("type", "text").toLowerCase(Locale.ROOT);
            if ("hidden".equals(type)) {
                hidden.put(name, decodeHtmlEntities(attributes.getOrDefault("value", "")));
            } else if (ANSWER_FIELD.matcher(name).matches()) {
                answerFields.add(name);
            }
        }
        return new FormFields(hidden, answerFields);
    }

    private static Map<String, String> parseAttributes(String source) {
        Map<String, String> result = new LinkedHashMap<>();
        Matcher matcher = ATTRIBUTE.matcher(source);
        while (matcher.find()) {
            String name = matcher.group(1).toLowerCase(Locale.ROOT);
            String value = firstNonNull(matcher.group(2), matcher.group(3), matcher.group(4));
            result.putIfAbsent(name, value == null ? "" : value);
        }
        return result;
    }

    private static GradeResult parseGradeResponse(String html) throws WimsException {
        int start = html.indexOf(JSON_BEGIN);
        int end = html.indexOf(JSON_END, Math.max(0, start));
        if (start < 0 || end < 0 || end <= start) {
            if (start >= 0 || end >= 0) {
                throw new WimsException(WimsError.MALFORMED_JSON,
                        "WIMS reply contained an incomplete ALGOGEBRA_JSON marker pair");
            }
            WimsError classification = classifyMissingJson(html);
            String message = switch (classification) {
                case HOOK_NOT_INSTALLED -> "WIMS returned an answer-analysis page without the AlgoGebra JSON hook";
                case RETRY_REQUIRED -> "WIMS returned an incomplete-answer retry page; ask the student to review and resubmit";
                default -> "WIMS reply did not contain an ALGOGEBRA_JSON block";
            };
            throw new WimsException(classification, message);
        }
        String json = html.substring(start + JSON_BEGIN.length(), end).trim();
        try {
            return gradeResult(WimsJsonParser.parse(json));
        } catch (IllegalArgumentException exception) {
            throw new WimsException(WimsError.MALFORMED_JSON,
                    "WIMS returned a malformed ALGOGEBRA_JSON block", exception);
        }
    }

    private static WimsError classifyMissingJson(String html) {
        String normalized = Normalizer.normalize(decodeHtmlEntities(html), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "").toLowerCase(Locale.ROOT);
        if (normalized.contains("answer_analysis")) {
            return WimsError.HOOK_NOT_INSTALLED;
        }
        if (normalized.contains("etes-vous sur") || normalized.contains("are you sure")) {
            return WimsError.RETRY_REQUIRED;
        }
        return WimsError.NO_JSON_BLOCK;
    }

    private static GradeResult gradeResult(Object parsed) throws WimsException {
        if (!(parsed instanceof Map<?, ?> root)) {
            throw malformed("JSON block root must be an object");
        }
        Object gradeValue = root.get("grade");
        if (!(gradeValue instanceof BigDecimal grade)) {
            throw new WimsException(WimsError.INVALID_GRADE,
                    "WIMS grade must be a JSON number (integer 0/1 values are valid)");
        }
        if (grade.compareTo(BigDecimal.ZERO) < 0 || grade.compareTo(BigDecimal.ONE) > 0) {
            throw new WimsException(WimsError.INVALID_GRADE,
                    "WIMS grade must be between 0 and 1");
        }
        Object answersValue = root.get("answers");
        if (!(answersValue instanceof List<?> answerList) || answerList.size() > MAX_ANSWER_FIELDS) {
            throw malformed("JSON block answers must be an array of at most 100 items");
        }
        List<WimsAnswerResult> answers = new ArrayList<>(answerList.size());
        for (Object value : answerList) {
            if (!(value instanceof Map<?, ?> answer)) {
                throw malformed("Each JSON answers item must be an object");
            }
            String id = string(answer.get("id"), "answer id", true);
            Object correctValue = answer.get("correct");
            if (!(correctValue instanceof Boolean correct)) {
                throw malformed("Each answer's correct field must be a boolean");
            }
            Object scoreValue = answer.get("score");
            if (!(scoreValue instanceof BigDecimal score)) {
                throw malformed("Each answer's score field must be a JSON number");
            }
            answers.add(new WimsAnswerResult(id, correct, score,
                    string(answer.get("feedback"), "answer feedback", false),
                    string(answer.get("expected"), "expected answer", false),
                    string(answer.get("given"), "normalized given answer", false)));
        }
        Long seed = null;
        Object seedValue = root.get("seed");
        if (seedValue != null) {
            if (!(seedValue instanceof BigDecimal seedNumber)) {
                throw malformed("seed must be a JSON number when present");
            }
            try {
                seed = seedNumber.longValueExact();
            } catch (ArithmeticException exception) {
                throw malformed("seed must be an integer in the signed 64-bit range");
            }
        }
        return new GradeResult(grade, seed, answers,
                string(root.get("feedback"), "feedback", false));
    }

    private static String string(Object value, String field, boolean required) throws WimsException {
        if (value == null && !required) {
            return "";
        }
        if (value instanceof String text) {
            return text;
        }
        throw malformed(field + " must be a string");
    }

    private static WimsException malformed(String detail) {
        return new WimsException(WimsError.MALFORMED_JSON, detail);
    }

    private static boolean isReservedFormName(String name) {
        return "cmd".equals(name) || "module".equals(name) || "session".equals(name)
                || "special_parm".equals(name) || "lang".equals(name);
    }

    private static String decodeHtmlEntities(String value) {
        StringBuilder output = new StringBuilder(value.length());
        for (int index = 0; index < value.length();) {
            char current = value.charAt(index);
            if (current != '&') {
                output.append(current);
                index++;
                continue;
            }
            int semicolon = value.indexOf(';', index + 1);
            if (semicolon < 0 || semicolon - index > 12) {
                output.append(current);
                index++;
                continue;
            }
            String entity = value.substring(index + 1, semicolon);
            Character decoded = switch (entity) {
                case "amp" -> '&';
                case "quot" -> '"';
                case "apos" -> '\'';
                case "lt" -> '<';
                case "gt" -> '>';
                case "nbsp" -> '\u00a0';
                case "Ecirc" -> '\u00ca';
                case "ecirc" -> '\u00ea';
                case "ucirc" -> '\u00fb';
                case "eacute" -> '\u00e9';
                case "Eacute" -> '\u00c9';
                default -> numericEntity(entity);
            };
            if (decoded == null) {
                output.append(value, index, semicolon + 1);
            } else {
                output.append(decoded);
            }
            index = semicolon + 1;
        }
        return output.toString();
    }

    private static Character numericEntity(String entity) {
        try {
            if (entity.startsWith("#x") || entity.startsWith("#X")) {
                return (char) Integer.parseInt(entity.substring(2), 16);
            }
            if (entity.startsWith("#")) {
                return (char) Integer.parseInt(entity.substring(1));
            }
        } catch (NumberFormatException ignored) {
            // Preserve an invalid entity literally.
        }
        return null;
    }

    private static String firstNonNull(String... values) {
        for (String value : values) {
            if (value != null) {
                return value;
            }
        }
        return null;
    }

    private record FormFields(Map<String, String> hidden, Set<String> answerFields) {
    }

    private record Response(int statusCode, String contentType, byte[] body) {
    }

    private static final class ResponseTooLargeException extends IOException {
        private static final long serialVersionUID = 1L;
    }
}
