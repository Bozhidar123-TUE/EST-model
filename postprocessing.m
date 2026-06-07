% Post-processing script for the EST Simulink model. This script is invoked
% after the Simulink model is finished running (stopFcn callback function).

close all;
figure;

%% Supply and demand
subplot(2,2,1);
plot(tout/unit("day"), PSupply/unit("kW"));
hold on;
plot(tout/unit("day"), PDemand/unit("kW"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Supply and demand');
xlabel('Time [day]');
ylabel('Power [kW]');
legend("Supply","Demand");

%% Stored energy
subplot(2,2,2);
plot(tout/unit("day"), EStorage/unit("kWh")/1000);
xlim([0 tout(end)/unit("day")]);
grid on;
title('Storage');
xlabel('Time [day]');
ylabel('Energy [MWh]');

%% Energy losses
subplot(2,2,3);
plot(tout/unit("day"), D/unit("kW"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Losses');
xlabel('Time [day]');
ylabel('Dissipation rate [kW]');

%% Load balancing
subplot(2,2,4);
plot(tout/unit("day"), PSell/unit("kW"));
hold on;
plot(tout/unit("day"), PBuy/unit("kW"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Load balancing');
xlabel('Time [day]');
ylabel('Power [kW]');
legend("Sell","Buy");

%% Pie charts

% integrate the power signals in time
EfromSupplyTransport = trapz(tout, PfromSupplyTransport);
EtoDemandTransport   = trapz(tout, PtoDemandTransport);
ESell                = trapz(tout, PSell);
EBuy                 = trapz(tout, PBuy);
EtoInjection         = trapz(tout, PtoInjection);
ESteamRecovered      = trapz(tout, PSteamRecovered);
EfromExtraction      = trapz(tout, PfromExtraction);
ESupplyTransportLoss = trapz(tout, DSupplyTransport);
EDemandTransportLoss = trapz(tout, DDemandTransport);
EInjectionLoss       = trapz(tout, DInjection);
EStorageDissipation  = trapz(tout, DStorageOnly);
EExtractionLoss      = trapz(tout, DExtraction);
EStorageSystemLoss   = trapz(tout, DStorageSystemLoss);

ETotalLoss = ESupplyTransportLoss + EDemandTransportLoss + EInjectionLoss + EStorageDissipation + EExtractionLoss;

EDirect = EfromSupplyTransport - ESell - EtoInjection;

ESupplyTotal = trapz(tout, PSupply);
EDemandTotal = trapz(tout, PDemand);

selfSufficiency = 1 - EBuy/EtoDemandTransport;
soldFraction = ESell/EfromSupplyTransport;
storageUtilisation = (max(EStorage) - min(EStorage))/(EStorageMax - EStorageMin);

if EtoInjection > 0
    injectionEfficiencyActual = 1 - EInjectionLoss/EtoInjection;
else
    injectionEfficiencyActual = 0;
end

if (EfromExtraction + EExtractionLoss) > 0
    extractionEfficiencyActual = EfromExtraction/(EfromExtraction + EExtractionLoss);
else
    extractionEfficiencyActual = 0;
end

storageRoundTrip = injectionEfficiencyActual * extractionEfficiencyActual;

EtoStorageUseful = EtoInjection - EInjectionLoss + ESteamRecovered;

storageEnergyRatio = EfromExtraction/EtoStorageUseful;
steamRecoveryFraction = ESteamRecovered/EtoStorageUseful;
chargingEffectiveness = EtoStorageUseful/EtoInjection;

% Energy balance checks
EStorageStart = EStorage(1);
EStorageEnd = EStorage(end);
EStorageDelta = EStorageEnd - EStorageStart;

EToStorageNet = EtoInjection - EInjectionLoss + ESteamRecovered;
EfromStorageGross = EfromExtraction + EExtractionLoss;

storageBalanceResidual = EStorageDelta - (EToStorageNet - EfromStorageGross - EStorageDissipation);

supplyBalanceResidual = EfromSupplyTransport - (EDirect + EtoInjection + ESell);
demandBalanceResidual = EtoDemandTransport - (EDirect + EfromExtraction + EBuy);

figure;
tiles = tiledlayout(1,2);

ax = nexttile;
pie(ax, [EDirect, EtoInjection, ESell]/EfromSupplyTransport);
lgd = legend({"Direct to demand", "To storage", "Sold"});
lgd.Layout.Tile = "south";
title(sprintf("Received energy %.1f [MWh]", EfromSupplyTransport/unit("kWh")/1000));

ax = nexttile;
pie(ax, [EDirect, EfromExtraction, EBuy]/EtoDemandTransport);
lgd = legend({"Direct from supply", "From storage", "Bought"});
lgd.Layout.Tile = "south";
title(sprintf("Delivered energy %.1f [MWh]", EtoDemandTransport/unit("kWh")/1000));

fprintf('\n===== EST numerical summary =====\n');
fprintf('Bought energy:      %8.2f kWh\n', EBuy/unit("kWh"));
fprintf('Sold energy:        %8.2f kWh\n', ESell/unit("kWh"));
fprintf('To storage:         %8.2f kWh\n', EtoInjection/unit("kWh"));
fprintf('From storage:       %8.2f kWh\n', EfromExtraction/unit("kWh"));
fprintf('Supply transport losses: %8.2f kWh\n', ESupplyTransportLoss/unit("kWh"));
fprintf('Demand transport losses: %8.2f kWh\n', EDemandTransportLoss/unit("kWh"));
fprintf('Injection losses:        %8.2f kWh\n', EInjectionLoss/unit("kWh"));
fprintf('Steam recovered energy: %.2f kWh\n', ESteamRecovered/unit("kWh"));
fprintf('Storage dissipation:     %8.2f kWh\n', EStorageDissipation/unit("kWh"));
fprintf('Extraction losses:       %8.2f kWh\n', EExtractionLoss/unit("kWh"));
fprintf('Total system losses:     %8.2f kWh\n', ETotalLoss/unit("kWh"));
fprintf('Minimum storage:    %8.2f kWh\n', min(EStorage)/unit("kWh"));
fprintf('Maximum storage:    %8.2f kWh\n', max(EStorage)/unit("kWh"));
fprintf('Final storage:      %8.2f kWh\n', EStorage(end)/unit("kWh"));
fprintf('Maximum buy power:  %8.2f kW\n', max(PBuy)/unit("kW"));
fprintf('Maximum sell power: %8.2f kW\n', max(PSell)/unit("kW"));
fprintf('Maximum injection:  %8.2f kW\n', max(PtoInjection)/unit("kW"));
fprintf('Maximum extraction: %8.2f kW\n', max(PfromExtraction)/unit("kW"));
fprintf('Self-sufficiency:    %8.2f %%\n', selfSufficiency*100);
fprintf('Sold supply fraction:%8.2f %%\n', soldFraction*100);
fprintf('Storage utilisation: %8.2f %%\n', storageUtilisation*100);
fprintf('Injection efficiency:%8.2f %%\n', injectionEfficiencyActual*100);
fprintf('Extraction efficiency:%7.2f %%\n', extractionEfficiencyActual*100);
fprintf('Round-trip efficiency:%7.2f %%\n', storageRoundTrip*100);
fprintf('Storage energy ratio: %.2f %%\n', storageEnergyRatio*100);
fprintf('Storage balance residual:%8.4f kWh\n', storageBalanceResidual/unit("kWh"));
fprintf('Supply balance residual: %8.4f kWh\n', supplyBalanceResidual/unit("kWh"));
fprintf('Demand balance residual: %8.4f kWh\n', demandBalanceResidual/unit("kWh"));
fprintf('Useful energy to storage: %.2f kWh\n', EtoStorageUseful/unit("kWh"));
fprintf('Steam recovery fraction: %.2f %%\n', steamRecoveryFraction*100);
fprintf('Charging effectiveness: %.2f %%\n', chargingEffectiveness*100);
fprintf('Cable efficiency:       %8.2f %%\n', etaCable*100);
fprintf('Injection efficiency:   %8.2f %%\n', etaInjection*100);
fprintf('Storage efficiency:     %8.2f %%\n', etaStorage*100);
fprintf('Heat converter eff.:    %8.2f %%\n', etaHeatConverter*100);
fprintf('Piping efficiency:      %8.2f %%\n', etaPiping*100);
fprintf('Extraction before pipe: %8.2f %%\n', etaExtraction*100);
fprintf('Total extraction chain: %8.2f %%\n', etaExtractionToDemand*100);
fprintf('=================================\n\n');