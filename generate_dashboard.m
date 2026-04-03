% generate_dashboard.m
% Professional 6-Panel Molicel Dashboard (Design Review Ready)

try
    % 1. DATA EXTRACTION (Hybrid-Aware)
    if exist('out', 'var')
        t = out.tout;
        v_soc = out.esSOC; v_volt = out.esVoltage; v_pwr = out.esPower; v_cur = out.esCurrent;
        v_soh = out.cellCapacity; v_act_pwr = out.actualPowerDrawn;
    else
        t = tout; v_soc = esSOC; v_volt = esVoltage; v_pwr = esPower; v_cur = esCurrent;
        v_soh = cellCapacity; v_act_pwr = actualPowerDrawn;
    end
    
    % Get power demand for baseline
    load('powerDemand.mat', 'powerDemand');
    t_vec = [0:10:1430]/60;
    
    % 2. FIGURE INITIALIZATION
    f = figure('Name', 'Consolidated Battery Dashboard', 'NumberTitle', 'off', 'Color', 'white');
    clf(f);
    
    % --- PERFORMANCE ROW (Top) ---
    subplot(2,3,1); 
    stairs(t_vec, powerDemand/1e3, 'k-', 'linewidth', 2); hold on;
    if exist('v_act_pwr','var'), stairs(t/3600, v_act_pwr/1e3, 'r-'); end
    grid on; title('Power Flux [kW]'); xlabel('Time [h]'); ylabel('P [kW]');
    
    subplot(2,3,2); 
    if exist('v_soc','var'), stairs(t/3600, v_soc*100, 'color', [0.929 0.694 0.125], 'linewidth', 2); end
    grid on; title('Pack SOC [%]'); xlabel('Time [h]'); ylabel('% SOC'); ylim([0 110]);
    
    subplot(2,3,3); 
    if exist('v_soh','var'), stairs(t/3600, v_soh./v_soh(1)*100, 'k-', 'linewidth', 2); end
    grid on; title('State of Health [%]'); xlabel('Time [h]'); ylabel('% SOH');
    
    % --- ELECTRIFIED ROW (Bottom) ---
    subplot(2,3,4); 
    if exist('v_volt','var'), stairs(t/3600, v_volt, 'b-', 'linewidth', 2); end
    grid on; title('Terminal Voltage [V]'); xlabel('Time [h]'); ylabel('V [V]');
    
    subplot(2,3,5); 
    if exist('v_pwr','var'), stairs(t/3600, v_pwr/1e3, 'r-', 'linewidth', 2); end
    grid on; title('Regulated Power [kW]'); xlabel('Time [h]'); ylabel('P [kW]');
    
    subplot(2,3,6); 
    if exist('v_cur','var'), stairs(t/3600, v_cur, 'm-', 'linewidth', 2); end
    grid on; title('Pack Current [A]'); xlabel('Time [h]'); ylabel('I [A]');

catch ME
    fprintf('DESIGN REVIEW WARNING: Dashboard failed to generate (%s)\n', ME.message);
end
