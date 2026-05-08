package com.ntt.recon.service;

import com.ntt.recon.domain.SimulationMode;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicReference;

@Component
public class SimulationState {
    private final AtomicReference<SimulationMode> mode = new AtomicReference<>(SimulationMode.NORMAL);

    public SimulationMode current() {
        return mode.get();
    }

    public SimulationMode set(SimulationMode next) {
        mode.set(next);
        return next;
    }
}

