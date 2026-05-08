package com.ntt.recon;

import com.ntt.recon.config.ReconciliationProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
@EnableConfigurationProperties(ReconciliationProperties.class)
public class ReconProducerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ReconProducerApplication.class, args);
    }
}
