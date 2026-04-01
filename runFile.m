clear all; close all; clc

%% Load parameters:
    load('parameters.mat')      % Kokam battery parameters
    load('temperature.mat')     % Temperature affects aging model
    load('powerDemand.mat')     % +ve: demand -ve:charge
    ES.SoE_init = 0.5;

%% Simulation setup:
      startTime = 0;   
       stopTime = 24*3600-1;        % 1 day in seconds
    simOut = sim('BatteryModel',[startTime stopTime]);

%% Visualize results:
figure
% Power Demanded & Supplied
subplot(1,3,1)
    stairs([0:10:1430]/60,powerDemand/1e3,'k-','linewidth',2,'DisplayName','Power Demand')
    hold on
    stairs(simOut.tout/3600,simOut.actualPowerDrawn/1e3,'r-','LineWidth',1,'DisplayName','Actual Power Drawn from the Battery') 
    xlim([startTime stopTime/3600]);   
    xlabel('Time [h]')
    ylabel('Power [kW]')
    grid on;
    legend('location','best')
    title('Power Demand')

% SOC Evolution
subplot(1,3,2)
    stairs(simOut.tout/3600, ...
           simOut.esSOC*100, ...
           'color',[0.9290 0.6940 0.1250],'linewidth',2)
    hold on
    xlim([startTime stopTime/3600]);
    xlabel('Time [h]')
    ylim([0 110]);    
    ylabel('% SOC')
    yticks([20 50 90 100]); 
    grid on;
    title('Energy Storage SOC [%]')

% True Cell Capacity Evolution (Aging)
subplot(1,3,3)
    stairs(simOut.tout/3600, ...    
           simOut.cellCapacity./simOut.cellCapacity(1)*100 ...
          ,'k-','linewidth',2)
    hold on
    xlim([startTime stopTime/3600]);
    xlabel('Time [h]')
    ylabel(' [%]')
    grid on;
    title('State of Health [Aging]')