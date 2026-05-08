package com.ntt.recon.service;

import com.ntt.recon.config.ReconciliationProperties;
import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.support.MqExceptionClassifier;
import jakarta.jms.JMSException;
import jakarta.jms.Message;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jms.JmsException;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ReplayService {
    private static final Logger log = LoggerFactory.getLogger(ReplayService.class);

    private final JmsTemplate jmsTemplate;
    private final ReconciliationProperties properties;

    public ReplayService(JmsTemplate jmsTemplate, ReconciliationProperties properties) {
        this.jmsTemplate = jmsTemplate;
        this.properties = properties;
    }

    public String replay(ReconciliationTransaction transaction, String originalCorrelationId) {
        String replayCorrelationId = "replay-" + UUID.randomUUID();
        try {
            jmsTemplate.convertAndSend(properties.inputQueue(), transaction, message -> enrich(message, replayCorrelationId, originalCorrelationId));
        } catch (JmsException ex) {
            if (MqExceptionClassifier.isMqrc2035(ex)) {
                log.error("event=mq_authorization_failed mqrc=2035 action=verify_mq_user_channel_authentication replayCorrelationId={}",
                        replayCorrelationId, ex);
            }
            throw ex;
        }
        return replayCorrelationId;
    }

    private Message enrich(Message message, String replayCorrelationId, String originalCorrelationId) throws JMSException {
        message.setJMSCorrelationID(replayCorrelationId);
        message.setStringProperty("originalCorrelationId", originalCorrelationId);
        message.setStringProperty("replayed", "true");
        return message;
    }
}
