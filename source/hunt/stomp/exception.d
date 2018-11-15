module hunt.stomp.exception;

import hunt.lang.exception;

class StompConversionException : NestedRuntimeException {
    mixin BasicExceptionCtors;
}

class InvalidMimeTypeException : IllegalArgumentException {
    mixin BasicExceptionCtors;
}

class ConnectionLostException : RuntimeException {
    mixin BasicExceptionCtors;
}
