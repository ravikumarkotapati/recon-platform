package com.ntt.recon.config.secrets;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;

import java.util.HashMap;
import java.util.Map;

public class AwsSecretsManagerEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        boolean enabled = environment.getProperty("aws.secrets.enabled", Boolean.class, false);
        if (!enabled) {
            return;
        }

        String secretName = required(environment, "aws.secrets.name");
        String regionName = required(environment, "aws.secrets.region");

        try (SecretsManagerClient client = SecretsManagerClient.builder()
                .region(Region.of(regionName))
                .build()) {
            String secretJson = client.getSecretValue(GetSecretValueRequest.builder()
                    .secretId(secretName)
                    .build()).secretString();

            Map<String, String> secretValues = OBJECT_MAPPER.readValue(secretJson, new TypeReference<>() {});
            Map<String, Object> properties = new HashMap<>();
            secretValues.forEach((key, value) -> {
                properties.put(key, value);
                properties.put(toRelaxedPropertyName(key), value);
            });

            environment.getPropertySources().addFirst(new MapPropertySource("aws-secrets-manager", properties));
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to load application secrets from AWS Secrets Manager: " + secretName, ex);
        }
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 10;
    }

    private static String required(ConfigurableEnvironment environment, String propertyName) {
        String value = environment.getProperty(propertyName);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("Missing required property: " + propertyName);
        }
        return value;
    }

    private static String toRelaxedPropertyName(String key) {
        return key.toLowerCase().replace('_', '.');
    }
}
