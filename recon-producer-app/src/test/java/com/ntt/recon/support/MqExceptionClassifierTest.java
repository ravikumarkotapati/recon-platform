package com.ntt.recon.support;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class MqExceptionClassifierTest {
    @Test
    void detectsMqrc2035AuthorizationFailures() {
        RuntimeException exception = new RuntimeException("JMSCMQ0001: IBM MQ call failed with compcode '2' reason '2035'");

        assertThat(MqExceptionClassifier.isMqrc2035(exception)).isTrue();
    }

    @Test
    void ignoresOtherFailures() {
        assertThat(MqExceptionClassifier.isMqrc2035(new RuntimeException("connection refused"))).isFalse();
    }
}
