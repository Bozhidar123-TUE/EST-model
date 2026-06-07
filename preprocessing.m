% Pre-processing script for the EST Simulink model. This script is invoked
% before the Simulink model starts running (initFcn callback function).

%% Load the supply and demand data

addpath(genpath(fileparts(mfilename("fullpath"))));

global unit
run(fullfile(fileparts(mfilename("fullpath")), "scripts", "constants.m"));

timeUnit = 's';

supplyFile = "Team56_supply.csv";
supplyUnit = 'kW';

% Load the supply data
Supply = loadSupplyData(supplyFile, timeUnit, supplyUnit);

demandFile = "Team56_demand.csv";
demandUnit = 'kW';

% Load the demand data
Demand = loadDemandData(demandFile, timeUnit, demandUnit);

%% Simulation settings

deltat = 15*unit("min");
stopt  = min([Supply.Timeinfo.End, Demand.Timeinfo.End]);

%  Component efficiencies from SSA values

% Supply transport
etaCable = 0.9922;                 % Cable efficiency = 99.22%

% Injection system
etaHeater = 0.98;                  % Heater efficiency = 98%
etaFan = 0.56;                     % Fan efficiency = 56%

heaterElectricityShare = 0.9833;   % 98.33% of injection electricity goes to heater
fanElectricityShare = 0.0167;      % 1.67% of injection electricity goes to fan

% Weighted injection efficiency including heater and fan contribution
etaInjection = heaterElectricityShare*etaHeater + fanElectricityShare*etaFan;

% More conservative alternative if the fan power should not be counted as
% useful stored heat. Keep this commented unless you specifically want it.
% etaInjection = heaterElectricityShare*etaHeater;

% Storage and extraction side
etaStorage = 0.7892;               % Storage efficiency = 78.92%
etaHeatConverter = 0.85;           % Heat converter efficiency = 85%

% Demand transport
etaPiping = 0.97;                  % Piping efficiency = 97%


%  Dissipation coefficients used by the Simulink blocks


% The Simulink blocks use a-values, where:
% a = 1 - eta

% Transport from supply: cable losses
aSupplyTransport = 1 - etaCable;

% Injection: heater + fan losses
aInjection = 1 - etaInjection;

% Extraction: storage recovery + heat converter losses
% Piping is NOT included here, because piping is already handled by
% the demand transport block.
etaExtraction = etaStorage * etaHeatConverter;
aExtraction = 1 - etaExtraction;

% Transport to demand: piping losses
aDemandTransport = 1 - etaPiping;


%  Injection and extraction power limits


% Final model keeps the conservative 100 kW limits
PInjectionMax = 100*unit("kW");    % Maximum charging power into zeolite storage
PExtractionMax = 100*unit("kW");   % Maximum discharging power from zeolite storage

% Validation-scaled sensitivity values, kept only for reference
% PInjectionMax  = 296000*unit("kW");
% PExtractionMax = 296000*unit("kW");


%  Steam recovery system


% 0 = no steam recovery
% 1 = full theoretical steam recovery from Stef's calculation
% 0.50 = partial recovery, less optimistic and more realistic for testing
steamRecoveryStrength = 0.50;

% Based on Stef's calculation:
% original electrical charging input = 143,684 kWh
% electrical charging input with steam recovery = 73,428 kWh
steamRecoveryGainFull = 143684 / 73428;

% Final gain used by the Injection block
steamRecoveryGain = 1 + steamRecoveryStrength*(steamRecoveryGainFull - 1);


%  Storage system


EStorageMax = 138283*unit("kWh");      % 921.8 m^3 * 150 kWh/m^3
EStorageMin = 0.20*EStorageMax;        % 20% reserve level
EStorageInitial = 76880.87*unit("kWh");

% Standing storage dissipation is kept at zero.
% Storage efficiency is already included in aExtraction.
bStorage = 0/unit("s");

%  Useful combined efficiency values for checking/post-processing

etaSupplyToInjection = etaCable;
etaInjectionNoSteam = etaInjection;
etaExtractionToDemand = etaStorage * etaHeatConverter * etaPiping;

etaFullChainNoSteam = etaCable * etaInjection * etaStorage * etaHeatConverter * etaPiping;