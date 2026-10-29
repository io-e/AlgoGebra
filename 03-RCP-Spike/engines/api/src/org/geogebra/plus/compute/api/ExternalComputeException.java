package org.geogebra.plus.compute.api;

/** A rejected request, unavailable executable, timeout, or failed engine call. */
public final class ExternalComputeException extends Exception {

    public enum Code {
        INVALID_REQUEST,
        COMMAND_REJECTED,
        ENGINE_UNAVAILABLE,
        PROCESS_START_FAILED,
        PROCESS_TIMEOUT,
        PROCESS_FAILED,
        INVALID_OUTPUT
    }

    private final Code code;

    public ExternalComputeException(Code code, String message) {
        super(message);
        this.code = code;
    }

    public ExternalComputeException(Code code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }

    public Code code() {
        return code;
    }
}
