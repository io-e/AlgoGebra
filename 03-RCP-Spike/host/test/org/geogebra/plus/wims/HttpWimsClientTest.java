package org.geogebra.plus.wims;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.math.BigDecimal;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

/** No-framework contract tests for the WA-9 WIMS HTTP client. */
public final class HttpWimsClientTest {
    private static final Charset WINDOWS_1252 = Charset.forName("windows-1252");
    private static int testNumber;
    private static int failures;

    private HttpWimsClientTest() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 1 || args.length > 2) {
            throw new IllegalArgumentException(
                    "Pass the tests/fixtures/wims-live directory and optional unit|cycle mode");
        }
        Path fixtures = Path.of(args[0]);
        String mode = args.length == 2 ? args[1] : "all";
        if (!List.of("all", "unit", "cycle").contains(mode)) {
            throw new IllegalArgumentException("mode must be all, unit, or cycle");
        }
        byte[] new00006 = fixture(fixtures, "00006_right_new.html");
        if (mode.equals("all") || mode.equals("cycle")) {
            testCapturedRightAnswer(new00006, fixture(fixtures, "00006_right_reply.html"));
            testCapturedWrongIntegerGrade(new00006, fixture(fixtures, "00006_wrong_reply.html"));
            testCapturedCheckboxValues(fixture(fixtures, "00076_right_new.html"),
                    fixture(fixtures, "00076_right_reply.html"));
            byte[] newAccent = fixture(fixtures, "w8acc_right_cp1252_new.html");
            byte[] replyAccent = fixture(fixtures, "w8acc_right_cp1252_reply.html");
            testCp1252Accent(newAccent, replyAccent);
            testUnrepresentableCharacter(newAccent, replyAccent);
            testFormInjectionEncoded(new00006, fixture(fixtures, "00006_right_reply.html"));
            testUnknownAndInventedFields(new00006, fixture(fixtures, "00006_right_reply.html"));
        }
        if (mode.equals("all") || mode.equals("unit")) {
            testThreeWayHtmlClassification(new00006);
            testMalformedJsonAndGradeTypes(new00006);
            testHttpStatusAndResponseLimit(new00006);
            testTimeout(new00006);
            testInputValidation();
        }

        System.out.println("# WIMS client tests: " + (testNumber - failures)
                + " PASS, " + failures + " FAIL");
        if (failures > 0) {
            System.exit(1);
        }
    }

    private static void testCapturedRightAnswer(byte[] newPage, byte[] replyPage) throws Exception {
        try (FixtureServer server = new FixtureServer(newPage, replyPage, "text/html; charset=windows-1252")) {
            HttpWimsClient client = server.client();
            WimsSession session = client.createSession(server.exercise("00006"), Locale.FRENCH);
            check("W1-cmd-new-session", !session.getSessionId().isBlank()
                    && session.getAnswerFields().contains("reply1"));
            GradeResult result = client.submitAnswers(session, Map.of("reply1", "2"));
            check("W2-integer-grade-one", result.grade().compareTo(BigDecimal.ONE) == 0);
            check("W2-per-answer-data", result.answers().size() == 1
                    && result.answers().getFirst().correct()
                    && result.answers().getFirst().normalizedGiven().equals("2"));
            check("W1-W2-real-capture-cycle", server.requests.size() == 2
                    && "new".equals(server.requests.get(0).first("cmd"))
                    && "reply".equals(server.requests.get(1).first("cmd")));
            Request create = server.requests.get(0);
            Request reply = server.requests.get(1);
            check("W1-new-does-not-send-json-hook", create.first("special_parm") == null);
            check("W2-reply-hook-only", "algogebra_json".equals(reply.first("special_parm")));
            check("W1-session-carried-forward", session.getSessionId().equals(reply.first("session")));
            check("W2-no-invented-ansN", reply.first("ans1") == null
                    && "2".equals(reply.first("reply1")));
            check("W1-form-post-windows1252", "POST".equals(reply.method)
                    && reply.contentType.toLowerCase(Locale.ROOT).contains("charset=windows-1252"));
        }
    }

    private static void testCapturedWrongIntegerGrade(byte[] newPage, byte[] replyPage) throws Exception {
        try (FixtureServer server = new FixtureServer(newPage, replyPage, "text/html; charset=windows-1252")) {
            HttpWimsClient client = server.client();
            GradeResult result = client.submitAnswers(
                    client.createSession(server.exercise("00006"), Locale.FRENCH), Map.of("reply1", "wrong"));
            check("W5-integer-grade-zero", result.grade().compareTo(BigDecimal.ZERO) == 0);
        }
    }

    private static void testCapturedCheckboxValues(byte[] newPage, byte[] replyPage) throws Exception {
        try (FixtureServer server = new FixtureServer(newPage, replyPage, "text/html; charset=windows-1252")) {
            HttpWimsClient client = server.client();
            WimsSession session = client.createSession(server.exercise("00076"), Locale.FRENCH);
            check("W1-checkbox-field-discovered", session.getAnswerFields().contains("reply1"));
            GradeResult result = client.submitAnswers(session, WimsAnswerSubmission.builder()
                    .add("reply1", "3").add("reply1", "5").build());
            Request reply = server.requests.get(1);
            check("W1-checkbox-values-repeat-form-name", reply.values("reply1").equals(List.of("3", "5")));
            check("W6-given-is-normalized-not-keystrokes", result.answers().getFirst()
                    .normalizedGiven().equals("3, 5"));
            check("W5-checkbox-grade-number", result.grade().compareTo(BigDecimal.ONE) == 0);
        }
    }

    private static void testCp1252Accent(byte[] newPage, byte[] replyPage) throws Exception {
        try (FixtureServer server = new FixtureServer(newPage, replyPage, "text/html; charset=windows-1252")) {
            HttpWimsClient client = server.client();
            WimsSession session = client.createSession(server.exercise("gbw8acc"), Locale.FRENCH);
            GradeResult result = client.submitAnswers(session, Map.of("reply1", "été"));
            Request reply = server.requests.get(1);
            check("W4-ete-percent-encoded-as-cp1252", reply.rawBody.contains("reply1=%E9t%E9"));
            check("W4-response-decoded-as-cp1252", result.answers().getFirst().expected().equals("été"));
            check("W4-accented-live-capture-grade", result.grade().compareTo(BigDecimal.ONE) == 0);
        }
    }

    private static void testUnrepresentableCharacter(byte[] newPage, byte[] replyPage) throws Exception {
        try (FixtureServer server = new FixtureServer(newPage, replyPage, "text/html; charset=windows-1252")) {
            HttpWimsClient client = server.client();
            WimsSession session = client.createSession(server.exercise("gbw8acc"), Locale.FRENCH);
            WimsException error = expectWims(() -> client.submitAnswers(session, Map.of("reply1", "→")));
            check("W4-unrepresentable-character-rejected", error.getError() == WimsError.ENCODING_ERROR);
            check("W4-rejected-before-network", server.requests.size() == 1);
        }
    }

    private static void testUnknownAndInventedFields(byte[] newPage, byte[] replyPage) throws Exception {
        try (FixtureServer server = new FixtureServer(newPage, replyPage, "text/html; charset=windows-1252")) {
            HttpWimsClient client = server.client();
            WimsSession session = client.createSession(server.exercise("00006"), Locale.FRENCH);
            WimsException invented = expectWims(() -> client.submitAnswers(session, Map.of("ans1", "2")));
            check("W1-ansN-rejected", invented.getError() == WimsError.UNKNOWN_ANSWER_FIELD);
            WimsException unknown = expectWims(() -> client.submitAnswers(session, Map.of("reply99", "2")));
            check("W1-unsignalled-field-rejected", unknown.getError() == WimsError.UNKNOWN_ANSWER_FIELD);
            check("W1-invalid-fields-never-post", server.requests.size() == 1);
        }
    }

    private static void testThreeWayHtmlClassification(byte[] newPage) throws Exception {
        expectReplyError(newPage, html("<div id=answer_analysis>answer_analysis</div>"), WimsError.HOOK_NOT_INSTALLED,
                "W3-answer-analysis-means-hook-off");
        expectReplyError(newPage, html("<p>Êtes-vous sûr de vouloir soumettre cette réponse ?</p>"),
                WimsError.RETRY_REQUIRED, "W3-sure-retry-page-distinguished");
        expectReplyError(newPage, html("<html><body>generic page</body></html>"),
                WimsError.NO_JSON_BLOCK, "W3-generic-html-not-misclassified");
    }

    private static void testMalformedJsonAndGradeTypes(byte[] newPage) throws Exception {
        expectReplyError(newPage, html("<!-- ALGOGEBRA_JSON_BEGIN {\"grade\":1, ALGOGEBRA_JSON_END -->"),
                WimsError.MALFORMED_JSON, "W2-malformed-json-error");
        expectReplyError(newPage, html("<!-- ALGOGEBRA_JSON_BEGIN {\"grade\":1,\"answers\":[]} -->"),
                WimsError.MALFORMED_JSON, "W2-incomplete-marker-pair-is-malformed");
        expectReplyError(newPage, html("<!-- ALGOGEBRA_JSON_BEGIN {\"grade\":\"1\",\"answers\":[]} ALGOGEBRA_JSON_END -->"),
                WimsError.INVALID_GRADE, "W5-string-grade-rejected");
        expectReplyError(newPage, html("<!-- ALGOGEBRA_JSON_BEGIN {\"grade\":1.1,\"answers\":[]} ALGOGEBRA_JSON_END -->"),
                WimsError.INVALID_GRADE, "W5-grade-range-enforced");
        try (FixtureServer server = new FixtureServer(newPage,
                html("<!-- ALGOGEBRA_JSON_BEGIN {\"grade\":0.75,\"answers\":[],\"feedback\":\"partial\"} ALGOGEBRA_JSON_END -->"),
                "text/html; charset=windows-1252")) {
            HttpWimsClient client = server.client();
            WimsSession session = client.createSession(server.exercise("00006"), Locale.FRENCH);
            GradeResult result = client.submitAnswers(session, Map.of("reply1", "partial"));
            check("W5-decimal-grade-accepted", result.grade().compareTo(new BigDecimal("0.75")) == 0);
        }
    }

    private static void testFormInjectionEncoded(byte[] newPage, byte[] replyPage) throws Exception {
        try (FixtureServer server = new FixtureServer(newPage, replyPage,
                "text/html; charset=windows-1252")) {
            HttpWimsClient client = server.client();
            WimsSession session = client.createSession(server.exercise("00006"), Locale.FRENCH);
            String injected = "2&cmd=new&ans1=not-a-field";
            client.submitAnswers(session, Map.of("reply1", injected));
            Request reply = server.requests.get(1);
            check("W4-form-control-characters-escaped", reply.values("reply1").equals(List.of(injected)));
            check("W4-form-answer-cannot-inject-fields", reply.values("cmd").equals(List.of("reply"))
                    && reply.first("ans1") == null);
        }
    }

    private static void testHttpStatusAndResponseLimit(byte[] newPage) throws Exception {
        for (int status : List.of(413, 500, 503, 302)) {
            try (FixtureServer server = new FixtureServer(newPage,
                    "CGI unavailable".getBytes(WINDOWS_1252),
                    "text/html; charset=windows-1252", status, false)) {
                HttpWimsClient client = server.client();
                WimsSession session = client.createSession(server.exercise("00006"), Locale.FRENCH);
                WimsException error = expectWims(
                        () -> client.submitAnswers(session, Map.of("reply1", "2")));
                check("W7-http-" + status + "-is-explicit",
                        error.getError() == WimsError.HTTP_ERROR);
                check("W7-http-" + status + "-not-followed",
                        server.requests.size() == 2);
            }
        }
        byte[] large = new byte[4096];
        java.util.Arrays.fill(large, (byte) 'x');
        byte[] smallNewPage = html("<form><input type=hidden name=session value=TEST.1>"
                + "<input type=hidden name=module value=H6/test/oef2html.fr>"
                + "<input type=text name=reply1></form>");
        try (FixtureServer server = new FixtureServer(smallNewPage, large,
                "text/html; charset=windows-1252")) {
            HttpWimsClient client = new HttpWimsClient(server.httpClient(), Duration.ofSeconds(2), 1024);
            WimsSession session = client.createSession(server.exercise("00006"), Locale.FRENCH);
            WimsException error = expectWims(() -> client.submitAnswers(session, Map.of("reply1", "2")));
            check("W7-response-size-bounded", error.getError() == WimsError.RESPONSE_TOO_LARGE);
        }
    }

    private static void testTimeout(byte[] newPage) throws Exception {
        try (FixtureServer server = new FixtureServer(newPage, html("<html>late</html>"),
                "text/html; charset=windows-1252", 200, true)) {
            HttpWimsClient client = new HttpWimsClient(server.httpClient(), Duration.ofMillis(100), 1_048_576);
            WimsSession session = client.createSession(server.exercise("00006"), Locale.FRENCH);
            WimsException error = expectWims(() -> client.submitAnswers(session, Map.of("reply1", "2")));
            check("W7-timeout-has-explicit-error", error.getError() == WimsError.TIMEOUT);
        }
    }

    private static void testInputValidation() throws Exception {
        boolean queryRejected = false;
        try {
            new WimsExerciseRef(URI.create("http://127.0.0.1/wims.cgi?job=unsafe"),
                    "H6/test/oef2html.fr", "00006", Locale.FRENCH);
        } catch (IllegalArgumentException exception) {
            queryRejected = true;
        }
        check("W1-endpoint-query-not-accepted", queryRejected);
        boolean traversalRejected = false;
        try {
            new WimsExerciseRef(URI.create("http://127.0.0.1/wims.cgi"),
                    "H6/../admin", "00006", Locale.FRENCH);
        } catch (IllegalArgumentException exception) {
            traversalRejected = true;
        }
        check("W1-module-traversal-rejected", traversalRejected);
        boolean remoteHttpRejected = false;
        try {
            new WimsExerciseRef(URI.create("http://wims.example.invalid/wims.cgi"),
                    "H6/test/oef2html.fr", "00006", Locale.FRENCH);
        } catch (IllegalArgumentException exception) {
            remoteHttpRejected = true;
        }
        check("W4-remote-http-requires-tls", remoteHttpRejected);
        boolean remoteHttpsAccepted = true;
        try {
            new WimsExerciseRef(URI.create("https://wims.example.invalid/wims.cgi"),
                    "H6/test/oef2html.fr", "00006", Locale.FRENCH);
        } catch (IllegalArgumentException exception) {
            remoteHttpsAccepted = false;
        }
        check("W4-remote-https-accepted", remoteHttpsAccepted);
    }

    private static void expectReplyError(byte[] newPage, byte[] replyBody, WimsError expected,
            String testId) throws Exception {
        try (FixtureServer server = new FixtureServer(newPage, replyBody,
                "text/html; charset=windows-1252")) {
            HttpWimsClient client = server.client();
            WimsSession session = client.createSession(server.exercise("00006"), Locale.FRENCH);
            WimsException error = expectWims(() -> client.submitAnswers(session, Map.of("reply1", "x")));
            check(testId, error.getError() == expected);
        }
    }

    private static WimsException expectWims(ThrowingRunnable operation) throws Exception {
        try {
            operation.run();
        } catch (WimsException exception) {
            return exception;
        }
        throw new AssertionError("Expected WimsException");
    }

    private static byte[] fixture(Path directory, String name) throws IOException {
        return Files.readAllBytes(directory.resolve(name));
    }

    private static byte[] html(String value) {
        return value.getBytes(WINDOWS_1252);
    }

    private static void check(String id, boolean condition) {
        testNumber++;
        if (condition) {
            System.out.println("ok " + testNumber + " - " + id);
        } else {
            failures++;
            System.out.println("not ok " + testNumber + " - " + id);
        }
    }

    @FunctionalInterface
    private interface ThrowingRunnable {
        void run() throws Exception;
    }

    private static final class FixtureServer implements AutoCloseable {
        private final byte[] newPage;
        private final byte[] replyBody;
        private final String replyContentType;
        private final int replyStatus;
        private final boolean delayReply;
        private final HttpServer server;
        private final List<Request> requests = new CopyOnWriteArrayList<>();

        private FixtureServer(byte[] newPage, byte[] replyBody, String contentType) throws IOException {
            this(newPage, replyBody, contentType, 200, false);
        }

        private FixtureServer(byte[] newPage, byte[] replyBody, String contentType,
                int replyStatus, boolean delayReply) throws IOException {
            this.newPage = newPage;
            this.replyBody = replyBody;
            this.replyContentType = contentType;
            this.replyStatus = replyStatus;
            this.delayReply = delayReply;
            server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
            server.createContext("/wims.cgi", this::handle);
            server.start();
        }

        private HttpWimsClient client() {
            return new HttpWimsClient(httpClient(), Duration.ofSeconds(3), 4 * 1024 * 1024);
        }

        private java.net.http.HttpClient httpClient() {
            return java.net.http.HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(2)).build();
        }

        private WimsExerciseRef exercise(String id) {
            return new WimsExerciseRef(URI.create("http://127.0.0.1:" + server.getAddress().getPort()
                    + "/wims.cgi"), "H6/test/oef2html.fr", id, Locale.FRENCH);
        }

        private void handle(HttpExchange exchange) throws IOException {
            byte[] body = exchange.getRequestBody().readAllBytes();
            String raw = new String(body, StandardCharsets.US_ASCII);
            Request request = new Request(exchange.getRequestMethod(),
                    exchange.getRequestHeaders().getFirst("Content-Type"), raw, decodeForm(raw));
            requests.add(request);
            boolean create = "new".equals(request.first("cmd"));
            if (!create && delayReply) {
                try {
                    Thread.sleep(600);
                } catch (InterruptedException exception) {
                    Thread.currentThread().interrupt();
                }
            }
            byte[] response = create ? newPage : replyBody;
            int status = create ? 200 : replyStatus;
            String type = create ? "text/html; charset=windows-1252" : replyContentType;
            exchange.getResponseHeaders().set("Content-Type", type);
            if (!create && replyStatus == 302) {
                exchange.getResponseHeaders().set("Location", "http://127.0.0.1:1/redirect-target");
            }
            exchange.sendResponseHeaders(status, response.length);
            try (var output = exchange.getResponseBody()) {
                output.write(response);
            }
        }

        @Override
        public void close() {
            server.stop(0);
        }
    }

    private record Request(String method, String contentType, String rawBody,
            Map<String, List<String>> values) {
        private String first(String name) {
            List<String> found = values.get(name);
            return found == null || found.isEmpty() ? null : found.getFirst();
        }

        private List<String> values(String name) {
            return values.getOrDefault(name, List.of());
        }
    }

    private static Map<String, List<String>> decodeForm(String body) {
        Map<String, List<String>> result = new LinkedHashMap<>();
        if (body.isEmpty()) {
            return result;
        }
        for (String pair : body.split("&")) {
            int separator = pair.indexOf('=');
            String key = separator < 0 ? pair : pair.substring(0, separator);
            String value = separator < 0 ? "" : pair.substring(separator + 1);
            String decodedKey = URLDecoder.decode(key, WINDOWS_1252);
            String decodedValue = URLDecoder.decode(value, WINDOWS_1252);
            result.computeIfAbsent(decodedKey, ignored -> new ArrayList<>()).add(decodedValue);
        }
        return result;
    }
}
