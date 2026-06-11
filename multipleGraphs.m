%% 1. Run the Baseline Simulation
% (Make sure your preprocessing script is set to the baseline parameters)
% run('preprocessing.m'); 
sim('EST'); % Replace with your actual model name

% Extract the time and storage energy data (adjust variable names if needed)
time_days = tout/unit("day"); 
energy_baseline = EStorage/unit("kWh")/1000; % Use your actual workspace variable

%% 2. Run the Severe-Climate Simulation
% Change the variables in your workspace to trigger the extreme weather
demandScaleWinter = 1.5;   
supplyScaleWinter = 0.5;   
% Run your preprocessing script here to apply the transformation
run('preprocessing.m'); 

sim('EST'); 

% Extract the severe data
energy_severe = EStorage/unit("kWh")/1000; 

%% 3. Plot the Combined Graph
figure;
hold on; grid on;

% Plot Baseline in standard blue
plot(time_days, energy_baseline, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Baseline Climate');

% Plot Severe in dashed red to clearly distinguish it
plot(time_days, energy_severe, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Severe Climate (50% Variance)');

% Formatting
xlabel('Time [day]');
ylabel('Storage Energy [MWh]');
title('Zeolite 13X Storage Capacity: Baseline vs. Severe Climate');
legend('Location', 'best');
xlim([0 365]);
hold off;