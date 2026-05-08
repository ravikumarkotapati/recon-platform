package com.ntt.recon;

import com.ntt.recon.config.ReconciliationProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(ReconciliationProperties.class)
public class ReconDashboardApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(ReconDashboardApiApplication.class, args);
    }
}
