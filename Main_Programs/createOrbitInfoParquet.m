function createOrbitInfoParquet(yearStart, yearEnd)
    % Define the directory paths
    orbitDir = '/Volumes/MODIS_L2_Modified/OBPG/SST_Orbits/';
    granuleDir = '/Users/petercornillon/Dropbox/Data/MODIS_L2/granule_lists/';

    % Create an empty table to store the orbit information
    orbitInfo = table('Size', [0 8], 'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'string', 'datetime', 'double'}, ...
        'VariableNames', {'Year', 'Month', 'Day', 'Hour', 'OrbitNumber', 'OrbitFilename', 'OrbitStartTime', 'NumGranules'});

    % Loop through the years
    for year = yearStart:yearEnd
        % Load the granule list file of missing granules fo rthis year.
        granuleListFile = fullfile(granuleDir, sprintf('MissingGranuleList_%dmat.mat', year));
        load(granuleListFile)

        % Extract the start times from the missingList structure
        granuleStartTimes = [missingList.filename_time];

        % Loop through the months

        for month = 1:12
            % Create the month folder path
            monthDir = fullfile(orbitDir, num2str(year), sprintf('%02d', month));

            % Get the list of files in the month folder
            files = dir(fullfile(monthDir, '*.nc4'));

            % Loop through the files
            for i = 1:numel(files)
                % Get the file name and orbit start time
                filename = files(i).name;

                % find location of date/time in the filename.
                nn = strfind(filename, '_L2_');

                orbitStartTime = datenum(datetime([filename(nn-15:nn-8) filename(nn-6:nn-1)], 'InputFormat', 'yyyyMMddHHmmss'));

                % Find missing granules at AWS that fall within the orbit start time if any.
                granules = find(granuleStartTimes >= orbitStartTime & granuleStartTimes < orbitStartTime + 5933/86400);

                % Calculate the number of missing granules
                numMissingGranules = sum(granuleList.missingList.filename_time >= orbitStartTime & granuleList.missingList.filename_time < orbitStartTime + 5933/86400);

                % Calculate the orbit number
                orbitNumber = fix((orbitStartTime - datetime(year, 1, 1)) / days(1) * 5933);

                % Add the orbit information to the table
                orbitInfo = [orbitInfo; table(year, month, orbitStartTime.Day, orbitStartTime.Hour, orbitNumber, filename, orbitStartTime, numel(granules), numMissingGranules)];
            end
        end
    end

    % Write the orbit information to a parquet file
    parquetwrite('orbit_info.parquet', orbitInfo);
end