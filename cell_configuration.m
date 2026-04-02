
function cell_configuration
clc

%Cell data
C_nom = 4.5*3600; %in A
E_nom_total = 54*1000*3600; %in J
V_nom = 3.6; %in V
V_min = 2.5; %in V
V_max = 4.2; %in V
I_dis = 45; %in A
I_ch = 4.5; %in A
R = 15*10^(-3); %at 50% SOC, in Ohms
r = 0.8484252; %in in 
L = 2.761811; %in in 
mass = 0.07; %in kg

%Other data
eff = 0.95; %inverter efficiency

%Constraints
V_pack_max = 600; %in volts
P_pack_max = 80*1000; %in W
volume_limit = 2400; %in in3
I_motor_max = 150*2; % in A (for two motors)

%Parameters/inputs
s = 10;
p = 5;
volume_tolerance = 0.05; %fraction, not %
s_num = [];  p_num = []; pack_volt= []; pack_curr = []; pack_energy = []; pack_power = []; motor_current = []; OCV = [];
V_pack = s*V_max;
P_pack = 0;
I_motor = 20;
pack_volume = [];
volume = 0;
pack_mass = [];
pack_resistance = [];


while I_motor < I_motor_max %&& volume<volume_limit*(1+volume_tolerance)
    
    motor_current = [motor_current, I_motor];
    I_pack = I_motor/(2-eff); %inverter steps up current keeping power the same
    pack_curr = [pack_curr, I_pack]; 
    p = floor(I_pack/I_dis); %# cells in parallel to supply the current I_motor demanded by two motors
    p_num = [p_num, p];

    V_pack_max = P_pack_max/I_pack; %OCV (in V)
    OCV = [OCV, V_pack_max];
    s = floor(V_pack_max/V_max); %# cells in series to supply the power of 80kWh
    s_num = [s_num, s];
    
    %Actual pack parameters
    R_pack = s/p*R; %actual pack resistance when current I_motor is drawn (in Ohms)
    pack_resistance = [pack_resistance, R_pack];
    V_pack = s*V_max-I_pack*R_pack; %actual pack voltage (in V)
    pack_volt = [pack_volt, V_pack];
    P_pack = V_pack*I_pack - I_pack^2*R_pack; %actual pack power when current I_motor is drawn at V_pack (in W)
    pack_power = [pack_power, P_pack/1000]; 
    E_pack = p*C_nom*s*V_max/(1000*3600); %max energy stored in the pack (in kWh)
    pack_energy = [pack_energy, E_pack];
    total_cells = p*s;
    pack_volume = [pack_volume, total_cells*(L*pi*r^2)];
    volume = pack_volume(end);
    pack_mass = [pack_mass, total_cells*mass];
    p = p+1;
    s = s+1;
    I_motor = I_motor+1;
end

cell_config = [s_num', p_num', pack_volt', pack_curr', pack_energy', pack_power', pack_resistance', motor_current', pack_volume', pack_mass', OCV'];
max_power = 0;
max_current = 0;
max_voltage = 0;
i_optimal = 0;

for i=1:length(s_num)
    if (cell_config(i,6) > max_power)
        max_power = cell_config(i, 6);
        s_p_config_E = [cell_config(i,1), cell_config(i,2)];
        i_optimal = i;
        
        
    end
    if (cell_config(i,8) > max_current)
        max_current = cell_config(i, 4);
        s_p_config_I = [cell_config(i,1), cell_config(i,2)];
        
    end
    if (cell_config(i,3) > max_voltage)
        max_voltage = cell_config(i, 3);
        s_p_config_V = [cell_config(i,1), cell_config(i,2)];
        
    end
end

T = array2table(cell_config, "VariableNames", ["s", "p", "V_{max pack}, V", "I_{max pack}, A", "E_{max_pack}, kWh", "P_{max pack}, kW", "R_{max pack}, Ohm" "I_{max motor}, A", "Pack volume, in^3", "Pack mass, kg",  "OCV_max, V"])

fprintf('Max energy: %.2f\n', max_power);
disp('s-p for max energy: ' + string(s_p_config_E(1,1)) + '-' + string(s_p_config_E(1,2)))
fprintf('Max current: %.2f\n', max_current)
disp('s-p for max current: ' + string(s_p_config_I(1,1)) + '-' + string(s_p_config_I(1,2)))
fprintf('Max voltage: %.2f\n', max_voltage)
disp('s-p for max voltage: ' + string(s_p_config_V(1,1)) + '-' + string(s_p_config_V(1,2)))
disp('Parameters of optimal configuration: ')
T(i_optimal,:)
%disp(['Pack volume (battery only, no gaps): ' sprintf('%.2f', total_volume) ' in^3'])
%disp(['Pack mass: ' sprintf('%.2f', total_mass) ' kg'])

segmentation_options = [];
for j=1:50
    if (mod(s_p_config_E(1,1),j) == 0)
        segmentation_options = [segmentation_options, j];
    end
end
segmentation_options
n_segments = median(segmentation_options);
len_segment = s_p_config_E(1,1)/n_segments; %in # of cells
height_segment = s_p_config_E(1,2); %in # of cells
disp('Pack configuration: ' + string(n_segments) + ' X ' + string(len_segment) + ' X ' + string(height_segment))
segment_length = len_segment*L;
segment_height = height_segment*2*r;
segment_mass = len_segment*height_segment*mass;
disp(['Segment dimensions: ' sprintf('%.2f', segment_length) ' (length, in), ' sprintf('%.2f', segment_height) ' (height, in), ' sprintf('%.2f', segment_mass) ' (mass, kg) '])
