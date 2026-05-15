% Pre-processing script for the EST Simulink model. This script is invoked
% before the Simulink model starts running (initFcn callback function).

%% Load the supply and demand data
addpath(genpath(fileparts(mfilename("fullpath"))));

global unit
run(fullfile(fileparts(mfilename("fullpath")), "scripts", "constants.m"));

timeUnit   = 's';

supplyFile = "Team56_supply.csv";
supplyUnit = 'kW';

% load the supply data
Supply = loadSupplyData(supplyFile, timeUnit, supplyUnit);

demandFile = "Team56_demand.csv";
demandUnit = 'kW';

% load the demand data
Demand = loadDemandData(demandFile, timeUnit, demandUnit);

%% Simulation settings

deltat = 5*unit("min");
stopt  = min([Supply.Timeinfo.End, Demand.Timeinfo.End]);

%% System parameters

% transport from supply
aSupplyTransport = 0.01; % Dissipation coefficient

% injection system
aInjection = 0.1; % Dissipation coefficient
PInjectionMax  = 100*unit("kW");   % Maximum charging power into zeolite storage

% storage system
EStorageMax     = 138283*unit("kWh");  % 921.8 m³ × 150 kWh/m³
EStorageMin     = 0.0*unit("kWh");
EStorageInitial = EStorageMax;  % start full (best case)
bStorage        = 0/unit("s");  % Storage dissipation coefficient

% extraction system
aExtraction = 0.1; % Dissipation coefficient
PExtractionMax = 100*unit("kW");   % Maximum discharging power from zeolite storage

% transport to demand
aDemandTransport = 0.01; % Dissipation coefficient