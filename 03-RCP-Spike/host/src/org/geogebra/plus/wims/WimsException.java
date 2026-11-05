package org.geogebra.plus.wims;

import java.io.Serial;
import java.util.Objects;

/** Checked failure returned by the WIMS transport and response parser. */
public final class WimsException extends Exception {
    @Serial
    private static final long serialVersionUID = 1L;

    private final WimsError error;

    public WimsException(WimsError error, String message) {
        super(message);
        this.error = Objects.requireNonNull(error, "error");
    }

    public WimsException(WimsError error, String message, Throwable cause) {
        super(message, cause);
        this.error = Objects.requireNonNull(error, "error");
    }

    public WimsError getError() {
        return error;
    }
}
