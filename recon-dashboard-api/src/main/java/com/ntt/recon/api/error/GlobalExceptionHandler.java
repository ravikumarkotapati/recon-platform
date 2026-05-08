package com.ntt.recon.api.error;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jms.JmsException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.ServletWebRequest;
import org.springframework.web.context.request.WebRequest;

import java.time.Instant;

@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ApiErrorResponse> validation(MethodArgumentNotValidException ex, WebRequest request) {
        return response(HttpStatus.BAD_REQUEST, "Validation failed", request);
    }

    @ExceptionHandler(DataAccessException.class)
    ResponseEntity<ApiErrorResponse> database(DataAccessException ex, WebRequest request) {
        log.error("event=api_database_error", ex);
        return response(HttpStatus.SERVICE_UNAVAILABLE, "Database is temporarily unavailable", request);
    }

    @ExceptionHandler(JmsException.class)
    ResponseEntity<ApiErrorResponse> messaging(JmsException ex, WebRequest request) {
        log.error("event=api_messaging_error", ex);
        return response(HttpStatus.SERVICE_UNAVAILABLE, "Messaging service is temporarily unavailable", request);
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ApiErrorResponse> unexpected(Exception ex, WebRequest request) {
        log.error("event=api_unexpected_error", ex);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, "Unexpected server error", request);
    }

    private ResponseEntity<ApiErrorResponse> response(HttpStatus status, String message, WebRequest request) {
        return ResponseEntity.status(status).body(new ApiErrorResponse(
                Instant.now(),
                status.value(),
                status.getReasonPhrase(),
                message,
                path(request)
        ));
    }

    private String path(WebRequest request) {
        return request instanceof ServletWebRequest servletWebRequest
                ? servletWebRequest.getRequest().getRequestURI()
                : "unknown";
    }
}
