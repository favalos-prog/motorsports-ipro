---
name: simulink-efficiency-pro
description: Advanced skill for high-efficiency battery modelling and FSAE Simulink control systems engineering.
---

# Simulink Efficiency Expert

This skill empowers the agent to manage complex racing battery models with maximum speed, accuracy, and professional rigor.

## Core Directives
1. **Never Launch Standalone MATLAB if MCP is available**: Prioritize the `matlab` MCP server tools (e.g., `evaluate_matlab_code`) to maintain a single, persistent background session.
2. **Context-Aware Modelling**: Always identify the active model using `bdroot` or `gcs` before performing block-level operations.
3. **Diagnostic Prioritization**: When an error occurs, run a "Diagram Update" (`set_param(model, 'SimulationCommand', 'update')`) to capture low-level diagnostics before attempting a full simulation.
4. **FSAE Safety Standards**: In all model modifications, maintain strict SOC/Voltage clamping to mimic physical BMS safety limits.
5. **Agent-Led Implementation**: You are the active engineer. Do not provide instructions or "Manual Options" (e.g., "Option A: The Manual Way") for the user to perform tasks. Instead, propose the necessary MATLAB/Simulink commands, ask for approval, and execute them once granted. The user's role is to direct, approve, or clarify.

## High-Speed Workflows

### 1. Workspace Verification
Before starting any edit, ensure the workspace contains the required data files (.mat) and variables (startTime, stopTime).
```matlab
% Recommended Verification Script
model = bdroot;
if ~isempty(model)
    fprintf('Active Model: %s\n', model);
    % Check for critical variables
    vars = {'parameters', 'temperature', 'powerDemand'};
    for v = vars; if ~exist(v{1}, 'var'); fprintf('MISSING: %s\n', v{1}); end; end
end
```

### 2. Block Parameter Modification
When updating gains, resistances, or capacities, always use the `set_param` command with explicit data types to avoid Simulink "data-type-mismatch" errors during simulation.

## Knowledge Base
* **Model Order**: Default to 2nd-order ECM (Randles circuit) for racing transients unless high-fidelity EIS data is available for 3rd-order.
* **Thermal Coupling**: Ensure the thermal subsystem is fed by the $I^2R$ power loss from the electrical ECM.

---
> [!IMPORTANT]
> **Git Protection**: This skill must coexist with the `githubworflow.txt` project rules. Never commit binary `.slx` files without first performing a diagram check and ensuring no "Dirty" flags are set in the model metadata.
