function Demand = loadDemandData(demandFile, timeUnit, demandUnit)
global unit

fid = fopen(char(demandFile), 'r');

if fid == -1
    error('Could not open demand file: %s', char(demandFile));
end

raw = textscan(fid, '%f%f', ...
    'Delimiter', ',', ...
    'CommentStyle', '#', ...
    'CollectOutput', true);

fclose(fid);

demandData = raw{1};

if size(demandData, 2) < 2
    error('Demand file was not read as two columns.');
end

Demand = timeseries( ...
    unit(char(demandUnit)) * demandData(:,2), ...
    unit(char(timeUnit))   * demandData(:,1));

end