package org.geogebra.plus.wims;

/** Stable error categories for connected WIMS grading. */
public enum WimsError {
    INVALID_REQUEST,
    NETWORK_ERROR,
    TIMEOUT,
    HTTP_ERROR,
    RESPONSE_TOO_LARGE,
    ENCODING_ERROR,
    SESSION_NOT_FOUND,
    ANSWER_FIELDS_NOT_FOUND,
    UNKNOWN_ANSWER_FIELD,
    NO_JSON_BLOCK,
    HOOK_NOT_INSTALLED,
    RETRY_REQUIRED,
    MALFORMED_JSON,
    INVALID_GRADE
}
