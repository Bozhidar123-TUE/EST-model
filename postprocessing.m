% Post-processing script for the EST Simulink model. This script is invoked
% after the Simulink model is finished running (stopFcn callback function).

close all;
figure;

%% Supply and demand
subplot(2,2,1);
plot(tout/unit("day"), PSupply/unit("W"));
hold on;
plot(tout/unit("day"), PDemand/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Supply and demand');
xlabel('Time [day]');
ylabel('Power [W]');
legend("Supply","Demand");

%% Stored energy
subplot(2,2,2);
plot(tout/unit("day"), EStorage/unit("J"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Storage');
xlabel('Time [day]');
ylabel('Energy [J]');

%% Energy losses
subplot(2,2,3);
plot(tout/unit("day"), D/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Losses');
xlabel('Time [day]');
ylabel('Dissipation rate [W]');

%% Load balancing
subplot(2,2,4);
plot(tout/unit("day"), PSell/unit("W"));
hold on;
plot(tout/unit("day"), PBuy/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Load balancing');
xlabel('Time [day]');
ylabel('Power [W]');
legend("Sell","Buy");

%% Pie charts

% integrate the power signals in time
EfromSupplyTransport = trapz(tout, PfromSupplyTransport);
EtoDemandTransport   = trapz(tout, PtoDemandTransport);
ESell                = trapz(tout, PSell);
EBuy                 = trapz(tout, PBuy);
EtoInjection         = trapz(tout, PtoInjection);
EfromExtraction      = trapz(tout, PfromExtraction);
EStorageDissipation  = trapz(tout, DStorage);
EDirect              = EfromSupplyTransport - ESell - EtoInjection;
ESurplus             = EtoInjection-EfromExtraction-EStorageDissipation;

figure;
tiles = tiledlayout(1,2);

ax = nexttile;
pie(ax, [EDirect, EtoInjection, ESell]/EfromSupplyTransport);
lgd = legend({"Direct to demand", "To storage", "Sold"});
lgd.Layout.Tile = "south";
title(sprintf("Received energy %3.2e [J]", EfromSupplyTransport/unit('J')));

ax = nexttile;
pie(ax, [EDirect, EfromExtraction, EBuy]/EtoDemandTransport);
lgd = legend({"Direct from supply", "From storage", "Bought"});
lgd.Layout.Tile = "south";
title(sprintf("Delivered energy %3.2e [J]", EtoDemandTransport/unit('J')));

fprintf('\n===== EST numerical summary =====\n');
fprintf('Bought energy:      %8.2f kWh\n', EBuy/unit("kWh"));
fprintf('Sold energy:        %8.2f kWh\n', ESell/unit("kWh"));
fprintf('To storage:         %8.2f kWh\n', EtoInjection/unit("kWh"));
fprintf('From storage:       %8.2f kWh\n', EfromExtraction/unit("kWh"));
fprintf('Injection/extraction losses: %8.2f kWh\n', EStorageDissipation/unit("kWh"));
fprintf('Minimum storage:    %8.2f kWh\n', min(EStorage)/unit("kWh"));
fprintf('Maximum storage:    %8.2f kWh\n', max(EStorage)/unit("kWh"));
fprintf('Final storage:      %8.2f kWh\n', EStorage(end)/unit("kWh"));
fprintf('Maximum buy power:  %8.2f kW\n', max(PBuy)/unit("kW"));
fprintf('Maximum sell power: %8.2f kW\n', max(PSell)/unit("kW"));
fprintf('Maximum injection:  %8.2f kW\n', max(PtoInjection)/unit("kW"));
fprintf('Maximum extraction: %8.2f kW\n', max(PfromExtraction)/unit("kW"));
fprintf('=================================\n\n');