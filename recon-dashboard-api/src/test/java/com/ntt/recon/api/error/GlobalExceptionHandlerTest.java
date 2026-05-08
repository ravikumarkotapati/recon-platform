package com.ntt.recon.api.error;

import org.junit.jupiter.api.Test;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.jms.JmsException;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.context.request.ServletWebRequest;
import org.springframework.web.context.request.WebRequest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class GlobalExceptionHandlerTest {
    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void mapsDatabaseFailureToServiceUnavailableWithoutLeakingDetails() {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/reconciliation/status");

        var response = handler.database(new DataAccessResourceFailureException("db password invalid"), new ServletWebRequest(request));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().message()).isEqualTo("Database is temporarily unavailable");
        assertThat(response.getBody().path()).isEqualTo("/api/reconciliation/status");
    }

    @Test
    void mapsMessagingFailureToServiceUnavailable() {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/reconciliation/replay");

        var response = handler.messaging(new JmsException("mq unavailable") { }, new ServletWebRequest(request));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().message()).isEqualTo("Messaging service is temporarily unavailable");
        assertThat(response.getBody().path()).isEqualTo("/api/reconciliation/replay");
    }

    @Test
    void mapsUnexpectedFailureToInternalServerErrorAndHandlesUnknownPath() {
        WebRequest request = mock(WebRequest.class);

        var response = handler.unexpected(new RuntimeException("boom"), request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().message()).isEqualTo("Unexpected server error");
        assertThat(response.getBody().path()).isEqualTo("unknown");
    }
}
