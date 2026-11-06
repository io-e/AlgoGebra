package org.geogebra.plus.wims;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetEncoder;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

/** Strict application/x-www-form-urlencoded encoding using WIMS's observed Windows-1252. */
final class WimsFormEncoding {
    static final Charset CHARSET = Charset.forName("windows-1252");
    private static final char[] HEX = "0123456789ABCDEF".toCharArray();

    private WimsFormEncoding() {
    }

    static byte[] encode(Map<String, String> values) throws WimsException {
        List<FormField> fields = values.entrySet().stream()
                .map(entry -> new FormField(entry.getKey(), entry.getValue())).toList();
        return encode(fields);
    }

    static byte[] encode(List<FormField> fields) throws WimsException {
        StringBuilder body = new StringBuilder();
        for (FormField field : fields) {
            if (body.length() > 0) {
                body.append('&');
            }
            appendComponent(body, field.name());
            body.append('=');
            appendComponent(body, field.value());
        }
        return body.toString().getBytes(StandardCharsets.US_ASCII);
    }

    private static void appendComponent(StringBuilder target, String value) throws WimsException {
        CharsetEncoder encoder = CHARSET.newEncoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT);
        ByteBuffer bytes;
        try {
            bytes = encoder.encode(CharBuffer.wrap(value));
        } catch (CharacterCodingException exception) {
            throw new WimsException(WimsError.ENCODING_ERROR,
                    "A form field contains a character that WIMS's Windows-1252 endpoint cannot represent",
                    exception);
        }
        while (bytes.hasRemaining()) {
            int unsigned = bytes.get() & 0xFF;
            if (isFormSafe(unsigned)) {
                target.append((char) unsigned);
            } else if (unsigned == 0x20) {
                target.append('+');
            } else {
                target.append('%').append(HEX[unsigned >>> 4]).append(HEX[unsigned & 0x0F]);
            }
        }
    }

    private static boolean isFormSafe(int value) {
        return value >= 'a' && value <= 'z'
                || value >= 'A' && value <= 'Z'
                || value >= '0' && value <= '9'
                || value == '*' || value == '-' || value == '.' || value == '_';
    }

    record FormField(String name, String value) {
    }
}
