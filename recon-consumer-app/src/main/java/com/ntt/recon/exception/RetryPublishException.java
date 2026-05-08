package com.ntt.recon.exception;

public class RetryPublishException extends RuntimeException {
    public RetryPublishException(String message, Throwable cause) {
        super(message, cause);
    }
}
