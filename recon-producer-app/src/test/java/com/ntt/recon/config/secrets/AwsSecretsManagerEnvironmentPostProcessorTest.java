package com.ntt.recon.config.secrets;

import org.junit.jupiter.api.Test;
import org.springframework.core.Ordered;
import org.springframework.mock.env.MockEnvironment;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AwsSecretsManagerEnvironmentPostProcessorTest {
    private final AwsSecretsManagerEnvironmentPostProcessor processor = new AwsSecretsManagerEnvironmentPostProcessor();

    @Test
    void leavesEnvironmentUntouchedWhenSecretsLoadingIsDisabled() {
        MockEnvironment environment = new MockEnvironment()
                .withProperty("aws.secrets.enabled", "false");

        processor.postProcessEnvironment(environment, null);

        assertThat(environment.getPropertySources().contains("aws-secrets-manager")).isFalse();
        assertThat(processor.getOrder()).isEqualTo(Ordered.HIGHEST_PRECEDENCE + 10);
    }

    @Test
    void failsFastWhenSecretNameIsMissing() {
        MockEnvironment environment = new MockEnvironment()
                .withProperty("aws.secrets.enabled", "true")
                .withProperty("aws.secrets.region", "ap-southeast-1");

        assertThatThrownBy(() -> processor.postProcessEnvironment(environment, null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Missing required property: aws.secrets.name");
    }

    @Test
    void failsFastWhenRegionIsMissing() {
        MockEnvironment environment = new MockEnvironment()
                .withProperty("aws.secrets.enabled", "true")
                .withProperty("aws.secrets.name", "recon/test");

        assertThatThrownBy(() -> processor.postProcessEnvironment(environment, null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Missing required property: aws.secrets.region");
    }
}
