% combineResults.m

% 1. Define the filenames
file1 = 'baseline_results.mat';
file2 = 'severe_results.mat';
file3 = 'dissipation_results.mat';

% 2. Load the datasets
data1 = load(file1);
data2 = load(file2);
data3 = load(file3);

% 3. Create the comparative graph
figure;
hold on; grid on;

% Plot Baseline (Solid Blue)
plot(data1.time_days, data1.energy_MWh, 'b-', 'LineWidth', 1.5, ...
    'DisplayName', 'Baseline System');

% Plot Severe Climate (Dashed Red)
plot(data2.time_days, data2.energy_MWh, 'r--', 'LineWidth', 1.5, ...
    'DisplayName', 'Severe Climate (+50% Demand, -50% Supply)');

% Plot High Dissipation (Dash-Dot Black)
plot(data3.time_days, data3.energy_MWh, 'k-.', 'LineWidth', 1.5, ...
    'DisplayName', 'High Dissipation (+30% Thermal Losses)');

% 4. Formatting
xlabel('Time [day]');
ylabel('Storage Energy [MWh]');
title('Zeolite 13X Storage Capacity: Sensitivity Analysis');
legend('Location', 'best');
xlim([0 365]);
hold off;