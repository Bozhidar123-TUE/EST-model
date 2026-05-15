function Supply = loadSupplyData(supplyFile, timeUnit, supplyUnit)
global unit

fid = fopen(char(supplyFile), 'r');

if fid == -1
    error('Could not open supply file: %s', char(supplyFile));
end

raw = textscan(fid, '%f%f', ...
    'Delimiter', ',', ...
    'CommentStyle', '#', ...
    'CollectOutput', true);

fclose(fid);

supplyData = raw{1};

if size(supplyData, 2) < 2
    error('Supply file was not read as two columns.');
end

Supply = timeseries( ...
    unit(char(supplyUnit)) * supplyData(:,2), ...
    unit(char(timeUnit))   * supplyData(:,1));

end