% saveResults.m
% ---------------------------------------------------------
% 1. Change this filename for each run! 
% Example: 'baseline_results.mat' or 'severe_results.mat'
% To run after the script open Property Inspector of the SimuLink add
% saveData; in StopFcn callback
filename = 'test_results.mat'; 
% ---------------------------------------------------------

% Convert the raw workspace data into standard plotting units
time_days = tout / unit("day");
energy_MWh = EStorage / unit("kWh") / 1000;

% Save only the converted plotting variables to the .mat file
save(filename, 'time_days', 'energy_MWh');

fprintf('Successfully saved plotting data to: %s\n', filename);