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

%% Add supply demand fluctuation

% 1. Adjustable Parameters
daysHalfDecay = 20.1;      % (h) Days it takes for the fluctuation to decay to half
demandScaleWinter = 1.0;   % Winter demand multiplier (e.g., 1.5 = 50% increase at winter peak)
supplyScaleWinter = 1.0;   % Winter supply multiplier (e.g., 0.5 = 50% decrease at winter peak)

% 2. Convert time vector to days (CSV time is in seconds)
time_days = Supply.Time / (24 * 3600);

% 3. Base Formula (Exactly as provided, peaks at ~0.01 at day 0 and day 365)
fluctuation_base = exp(-time_days ./ daysHalfDecay .* (2/3)) + ...
                   exp((time_days - 365) ./ daysHalfDecay .* (2/3));

% 4. Add more demand over winter
% Correction: Multiply base by 100 to normalize the 0.01 peak to 1.0. 
% Subtract 1 from scale so the summer baseline remains unmodified (* 1.0).
Demand.Data = Demand.Data .* (1 + (demandScaleWinter - 1) .* fluctuation_base);

% 5. Reduce supply over winter
% Correction: Use 1 - (1 - scale) so winter drops to your scale (0.5), while summer stays at 1.0.
Supply.Data = Supply.Data .* (1 - (1 - supplyScaleWinter) .* fluctuation_base);
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

% Parameter to increase the dissipation rates for testing
testing_dissaption = 1.0;

% Injection: heater + fan losses
aInjection = (1 - etaInjection)*testing_dissaption;

% Extraction: storage recovery + heat converter losses
% Piping is NOT included here, because piping is already handled by
% the demand transport block.
etaExtraction = etaStorage * etaHeatConverter;
aExtraction = (1 - etaExtraction)*testing_dissaption;

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
steamRecoveryGain1 = 1 + steamRecoveryStrength*(steamRecoveryGainFull - 1);


%  Storage system


EStorageMax = 138283*unit("kWh");      % 921.8 m^3 * 150 kWh/m^3
EStorageMin = 0.10*EStorageMax;        % 20% reserve level
EStorageInitial = 64880.87*unit("kWh");

% Standing storage dissipation is kept at zero.
% Storage efficiency is already included in aExtraction.
bStorage = 0/unit("s");


%  Useful combined efficiency values for checking/post-processing

etaSupplyToInjection = etaCable;
etaInjectionNoSteam = etaInjection;
etaExtractionToDemand = etaStorage * etaHeatConverter * etaPiping;

etaFullChainNoSteam = etaCable * etaInjection * etaStorage * etaHeatConverter * etaPiping;