package com.ntt.recon.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.jms.ConnectionFactory;
import org.junit.jupiter.api.Test;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.support.converter.MappingJackson2MessageConverter;
import org.springframework.jms.support.converter.MessageConverter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class JmsConfigTest {
    private final JmsConfig config = new JmsConfig();
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Test
    void createsJacksonTextMessageConverter() {
        MessageConverter converter = config.jacksonJmsMessageConverter(objectMapper);

        assertThat(converter).isInstanceOf(MappingJackson2MessageConverter.class);
    }

    @Test
    void createsTransactedJmsTemplateWithConfiguredConverter() {
        ConnectionFactory connectionFactory = mock(ConnectionFactory.class);
        MessageConverter converter = config.jacksonJmsMessageConverter(objectMapper);

        JmsTemplate template = config.jmsTemplate(connectionFactory, converter);

        assertThat(template.getConnectionFactory()).isSameAs(connectionFactory);
        assertThat(template.getMessageConverter()).isSameAs(converter);
        assertThat(template.isSessionTransacted()).isTrue();
    }
}
