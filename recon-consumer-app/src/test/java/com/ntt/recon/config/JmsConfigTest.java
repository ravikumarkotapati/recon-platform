package com.ntt.recon.config;

import jakarta.jms.ConnectionFactory;
import org.junit.jupiter.api.Test;
import org.springframework.jms.config.DefaultJmsListenerContainerFactory;
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

    @Test
    void createsListenerContainerFactory() {
        ConnectionFactory connectionFactory = mock(ConnectionFactory.class);
        MessageConverter converter = config.jacksonJmsMessageConverter();
        ReconciliationProperties properties = new ReconciliationProperties(
                "RECON.IN", "RECON.RETRY", "RECON.BACKOUT", "SYSTEM.DEAD.LETTER.QUEUE", "RECON.REPLAY",
                1, 0, 2, 8, 3, 1);

        DefaultJmsListenerContainerFactory factory = config.jmsListenerContainerFactory(connectionFactory, converter, properties, true);

        assertThat(factory).isNotNull();
    }
}
