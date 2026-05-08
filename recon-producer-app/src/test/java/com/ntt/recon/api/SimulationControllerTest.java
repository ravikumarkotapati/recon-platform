package com.ntt.recon.api;

import com.ntt.recon.domain.SimulationMode;
import com.ntt.recon.service.SimulationState;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class SimulationControllerTest {
    private final SimulationState state = new SimulationState();
    private final SimulationController controller = new SimulationController(state);

    @Test
    void exposesAndChangesSimulationMode() {
        assertThat(controller.current()).containsEntry("mode", SimulationMode.NORMAL);

        assertThat(controller.set(SimulationMode.DB_DEADLOCK)).containsEntry("mode", SimulationMode.DB_DEADLOCK);
        assertThat(state.current()).isEqualTo(SimulationMode.DB_DEADLOCK);

        assertThat(controller.reset()).containsEntry("mode", SimulationMode.NORMAL);
    }
}
