package com.ntt.recon.config;

import jakarta.jms.ConnectionFactory;
import org.junit.jupiter.api.Test;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.support.converter.MappingJackson2MessageConverter;
import org.springframework.jms.support.converter.MessageConverter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class JmsConfigTest {
    private final JmsConfig config = new JmsConfig();

    @Test
    void createsJacksonTextMessageConverter() {
        assertThat(config.jacksonJmsMessageConverter()).isInstanceOf(MappingJackson2MessageConverter.class);
    }

    @Test
    void createsTransactedJmsTemplateWithConfiguredConverter() {
        ConnectionFactory connectionFactory = mock(ConnectionFactory.class);
        MessageConverter converter = config.jacksonJmsMessageConverter();

        JmsTemplate template = config.jmsTemplate(connectionFactory, converter);

        assertThat(template.getConnectionFactory()).isSameAs(connectionFactory);
        assertThat(template.getMessageConverter()).isSameAs(converter);
        assertThat(template.isSessionTransacted()).isTrue();
    }
}
