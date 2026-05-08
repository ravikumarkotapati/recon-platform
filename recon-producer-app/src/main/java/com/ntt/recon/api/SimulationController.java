package com.ntt.recon.api;

import com.ntt.recon.domain.SimulationMode;
import com.ntt.recon.service.SimulationState;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.Map;

@RestController
@RequestMapping("/api/simulation")
public class SimulationController {
    private final SimulationState simulationState;

    public SimulationController(SimulationState simulationState) {
        this.simulationState = simulationState;
    }

    @GetMapping
    public Map<String, Object> current() {
        return response(simulationState.current());
    }

    @PutMapping("/{mode}")
    public Map<String, Object> set(@PathVariable SimulationMode mode) {
        return response(simulationState.set(mode));
    }

    @PostMapping("/reset")
    public Map<String, Object> reset() {
        return response(simulationState.set(SimulationMode.NORMAL));
    }

    private static Map<String, Object> response(SimulationMode mode) {
        return Map.of(
                "mode", mode,
                "availableModes", Arrays.asList(SimulationMode.values())
        );
    }
}
