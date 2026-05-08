package com.ntt.recon.exception;

public class ProducerPublishException extends RuntimeException {
    public ProducerPublishException(String message, Throwable cause) {
        super(message, cause);
    }
}
