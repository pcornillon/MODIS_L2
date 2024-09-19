function checkOrbits(yearStart,yearEnd)

% This function processes satellite orbit data by year and month, determines the missing granules,
% and writes the results to a parquet file. It checks for missing granules in each orbit by analyzing
% the interval between granule start times. If a granule is missing, it estimates the start time of the
% missing granule and logs this information. The function also checks for missing granules at the end of the orbit.

% Set the following to true if you want to read in the list of good and missing granules.
buildLists = false; 

% Set up directories
data_dir = '/Volumes/MODIS_L2_Modified/OBPG/SST_Orbits/';
granule_list_dir = '/Users/petercornillon/Dropbox/Data/MODIS_L2/granule_lists/';
output_dir = '/Users/petercornillon/Dropbox/Data/MODIS_L2/check_orbits/';

% Open the file that will contain the filenames for bad files, files that couldn't be read.
fileID = fopen([output_dir '/bad_files.txt'], 'w');

% Check if the file opened successfully
if fileID == -1
    error('Failed to open the file for writing.');
end

% Define time constants

secPerday = 86400;

orbitStartTimeTolerance = 10;
orbitStartTimeExtremeTolerance = 250;

epoch = datenum(1970,1,1,0,0,0); % Epoch time for conversion

orbitDurationInitial = 5933; % seconds
orbitDurationTolerance = 10; % seconds

granuleDuration = 300; % seconds
granuleStartTimeTolerance = 2; % seconds

columnNames = {'Year', 'Month', 'Day', 'Hour', 'OrbitNumber1', 'OrbitNumber2', 'OrbitFilename', ...
    'OrbitStartTime', '# of Granules Used', '# of Missing Granules', '# of AWS Granules Missing'};

% List of files checked before starting to check any. The list was
% generated by subtracting 1* and 2* orbitDuration from the time of the
% first orbit in the archive, orbit #886. This information is stored in the
% Matlab file /Users/petercornillon/Git_repos/MODIS_L2/Data/Aqua_orbit_list
% in the variable checked_list. This file is updated after every 100 orbits
% have been processed. The first step is to actually read this list since
% it may have been updated since this script was last run and the
% information related to the orbits on the list is used to make sure that
% the proper orbit number is associated with each orbit.

orbitTime886 = 731401.0276504629;
checked_list = [884, orbitTime886-2*orbitDurationInitial/secPerday; 885, orbitTime886-orbitDurationInitial/secPerday];

load([granule_list_dir 'Aqua_orbit_list'])
                
orbitDuration = (checked_list(end,2) - checked_list(1,2)) / (checked_list(end,1) - checked_list(1,1)) * secPerday;

orbitsChecked = 0;

iBadFile = 0;

if buildLists
    iproblemGranules = 0;

    % Get the list of all OBPG granules

    tempNames = [];
    tempTimes = [];

    for year=2002:2023
        eval(['load ' granule_list_dir 'GoodGranuleList_' num2str(year) '.mat'])

        clear TempStartTimes filenames

        % % % TempStartTimes = [granuleList.first_scan_line_time];

        % Extract filenames from missingList
        for iGranule=1:length(granuleList)
            filenames(iGranule) = string(granuleList(iGranule).filename);
            TempStartTimes(iGranule) = granuleList(iGranule).first_scan_line_time;
        end

        % And combine them with the previous ones.
        tempNames = [tempNames filenames];
        tempTimes = [tempTimes TempStartTimes];
    end

    % % % nn = find(tempTimes > 100);

    % Get unique filenames and start times.
    OBPGgranuleList = unique(tempNames);
    OBPGgranuleStartTimes = unique(tempTimes);

    % Check the dates.
    for iGranule=1:length(OBPGgranuleList)
        start_time_str = extractBetween(OBPGgranuleList(iGranule), 'MODIS_', '_L2');
        orbitStartTime = datenum(start_time_str, 'yyyymmddTHHMMSS');
        
        dTime = (orbitStartTime - OBPGgranuleStartTimes(iGranule)) * secPerday;
        if abs(dTime) > orbitStartTimeExtremeTolerance
            fprintf('***  Start times for granule #%i (%s) differ by way too much %f\n', iGranule, OBPGgranuleList(iGranule), dTime)

            iproblemGranules = iproblemGranules + 1;
            problemGranules(iproblemGranules).filename = OBPGgranuleList(iGranule);
            problemGranules(iproblemGranules).start_time = OBPGgranuleStartTimes(iGranule);
            problemGranules(iproblemGranules).delta_time = dTime;
            problemGranules(iproblemGranules).whichlist = 'OBPG';
        elseif abs(dTime) > orbitStartTimeTolerance
            fprintf('***  Start times for granule #%i (%s) differ by %f\n', iGranule, OBPGgranuleList(iGranule), dTime)

            iproblemGranules = iproblemGranules + 1;
            problemGranules(iproblemGranules).filename = OBPGgranuleList(iGranule);
            problemGranules(iproblemGranules).start_time = OBPGgranuleStartTimes(iGranule);
            problemGranules(iproblemGranules).delta_time = dTime;
            problemGranules(iproblemGranules).whichlist = 'OBPG';
        end
    end

    % Get the list of all missing AWS granules

    tempNames = [];
    tempTimes = [];

    for year=2002:2023
        eval(['load ' granule_list_dir 'MissingGranuleList_' num2str(year) 'mat.mat'])

        clear TempStartTimes filenames

        % % % TempStartTimes = [missingList.first_scan_line_time];

        % Extract filenames from missingList
        for iGranule=1:length(missingList)
            filenames(iGranule) = string(missingList(iGranule).filename);
            TempStartTimes(iGranule) = missingList(iGranule).first_scan_line_time;
        end

        % And combine them with the previous ones.
        tempNames = [tempNames filenames];
        tempTimes = [tempTimes TempStartTimes];
    end

    % Get unique filenames and start times.
    AWSmissingGranuleList = unique(tempNames);
    AWSmissingStartTimes = unique(tempTimes);

    % Check the dates.
    for iGranule=1:length(AWSmissingGranuleList)
        start_time_str = extractBetween(AWSmissingGranuleList(iGranule), 'MODIS_', '_L2');
        orbitStartTime = datenum(start_time_str, 'yyyymmddTHHMMSS');
        
        dTime = (orbitStartTime - AWSmissingStartTimes(iGranule)) * secPerday;
        if abs(dTime) > orbitStartTimeExtremeTolerance
            fprintf('***  Start times for granule #%i (%s) differ by way too much %f\n', iGranule, AWSmissingGranuleList(iGranule), dTime)

            iproblemGranules = iproblemGranules + 1;
            problemGranules(iproblemGranules).filename = AWSmissingGranuleList(iGranule);
            problemGranules(iproblemGranules).start_time = AWSmissingStartTimes(iGranule);
            problemGranules(iproblemGranules).delta_time = dTime;
            problemGranules(iproblemGranules).whichlist = 'AWSmissing';
        elseif abs(dTime) > orbitStartTimeTolerance
            fprintf('***  Start times for granule #%i (%s) differ by %f\n', iGranule, AWSmissingGranuleList(iGranule), dTime)

            iproblemGranules = iproblemGranules + 1;
            problemGranules(iproblemGranules).filename = AWSmissingGranuleList(iGranule);
            problemGranules(iproblemGranules).start_time = AWSmissingStartTimes(iGranule);
            problemGranules(iproblemGranules).delta_time = dTime;
            problemGranules(iproblemGranules).whichlist = 'AWSmissing';
        end
    end

    % Save the list
    save([granule_list_dir 'granuleLists'], 'AWSmissingGranuleList', 'AWSmissingStartTimes', 'OBPGgranuleList', 'OBPGgranuleStartTimes', 'problemGranules')
else
    load([granule_list_dir 'granuleLists'])
end

fprintf('%i of the %i OBPG files are missing at AWS\n', length(AWSmissingGranuleList), length(OBPGgranuleList))

%% Now prepare to loop over all years/months/granules.

firstOrbitProcessed = true;

% Loop over years.
for year=yearStart:yearEnd

    for month = 1:12

        iMissingThisMonth = 0;
        iDuplicatesThisMonth = 0;
        iPartialThisMonth = 0;
        iAWSPartialThisMonth = 0;

        % Get the list of orbit files for the current year and month
        month_str = sprintf('%02d', month);
        orbit_files = dir(fullfile(data_dir, num2str(year), month_str, '*.nc4'));

        if ~isempty(orbit_files)

            parquet_data = {}; % Initialize an empty cell array to store parquet data

            % Process each orbit file
            for iOrbit = 1:length(orbit_files)

                orbitsChecked = orbitsChecked + 1;

                orbit_filename = orbit_files(iOrbit).name;

                % Get orbit number associated with filename.
                nn = strfind(orbit_filename, 'orbit');
                fileOrbitNumber = str2num(orbit_filename(nn+6:nn+11));

                % Extract the start time from the orbit filename
                start_time_str = orbit_filename(nn+13:nn+27);
                orbitStartTime = datenum(start_time_str, 'yyyymmddTHHMMSS');

                % Read contributing granules and their start times
                orbitFullFileName = fullfile(data_dir, num2str(year), month_str, orbit_filename);

                try
                    % Attempt to read the netCDF file
                    granule_filenames = ncread(orbitFullFileName, '/contributing_granules/filenames');

                catch ME
                    iBadFile = iBadFile + 1;
                    badFiles(iBadFile) = string(orbitFullFileName);
                    fprintf( fileID, '%s\n', string(orbitFullFileName));

                    % If an error occurs, catch it and flag the problem
                    warning(['Error reading file: ', orbit_files(iOrbit).name, '. Moving to next file.']);
                    % disp(['Error message: ', ME.message]);

                    % Continue to the next file
                    continue;
                end
                granule_start_times = ncread(orbitFullFileName, '/contributing_granules/start_time') / secPerday + epoch;

                % Get time of first scan line.
                DateTime = ncread( orbitFullFileName, 'DateTime');
                scanLineStartTime = datenum(DateTime/secPerday + datenum(1970,1,1,0,0,0));

                if abs(scanLineStartTime - orbitStartTime)*secPerday > orbitStartTimeTolerance
                    fprintf('%i) time if first scan line (%s) and time extracted from filename (%s) differ by more than 2 seconds for %s.\n', ...
                        orbitsChecked, datetime(scanLineStartTime), datetime(orbitStartTime), orbit_files(iOrbit).name)
                end

                % Are there any missing granules at the beginning of this orbit.
                num_missing_granules = round((scanLineStartTime - granule_start_times(1)) * secPerday / granuleDuration);

                if num_missing_granules < 0
                    num_missing_granules = 0;
                end

                % Calculate time differences between granules
                granule_diffs = diff(granule_start_times) * secPerday;
                % % % missing_indices = find(abs(granule_diffs - granuleDuration) > granuleStartTimeTolerance);
                % % % num_missing_granules = num_missing_granules + length(missing_indices);
                num_missing_granules = num_missing_granules + sum(round( (granule_diffs - granuleDuration) / granuleDuration));

                OBPGIndices = find( (OBPGgranuleStartTimes > (orbitStartTime-granuleDuration*secPerday)) & ((OBPGgranuleStartTimes+orbitDuration) < orbitStartTime));
                numOBPGGranulesInOrbit = length();
                % Check for missing granules at the end
                end_time_of_last_granule = granule_start_times(end) + granuleDuration / secPerday;
                time_from_start_to_end = (end_time_of_last_granule - orbitStartTime) * secPerday; % Convert to seconds
                
                if time_from_start_to_end < orbitDuration - orbitDurationTolerance
                    missing_granules_end = round((orbitDuration - time_from_start_to_end) / granuleDuration);
                else
                    missing_granules_end = 0;
                end

                % Check missing granules from the AWS missing granule list
                if ~isempty(AWSmissingGranuleList)
                    nn = find(orbitStartTime <= AWSmissingStartTimes & ...
                        (orbitStartTime + orbitDuration/24/3600) >= (AWSmissingStartTimes + 300/24/3600));
                    AWS_missing_in_orbit = length(nn);
                else
                    AWS_missing_in_orbit = 0;
                end

                % Get the actual orbit number for this orbit. To do this,
                % find the last orbit checked, i.e., processed by this
                % script, with a start time before the start time of the
                % current orbit, determine the mean duration of all orbits
                % prior to the last one before this one and use this and
                % the orbit number of the last one to determine the current
                % orbit number.

                % Find the last checked orbit before this one.
                nn = find(checked_list(:,2) < orbitStartTime);
                
                previousOrbitNumber = checked_list(nn(end),1);
                previousOrbitStartTime = checked_list(nn(end),2);

                % Get the mean length (in time) of an orbit prior to this
                % one and make sure that it is less than the acceptable
                % tolerance, nominally 2 s.

                orbitDuration = (previousOrbitStartTime - checked_list(1,2)) / (previousOrbitNumber - checked_list(1,1)) * secPerday;
                
                if abs(orbitDuration - orbitDurationInitial) > orbitDurationTolerance
                    fprintf('Mean orbit duration calculated for orbit #%\i (%f) is more than %i s from the nominal time of %f.\n', ...
                        previousOrbitNumber, orbitDuration, orbitDurationTolerance, orbitDurationInitial)
                    keyboard
                end

                % Now calculate the orbit number
                
                dtime = (orbitStartTime - previousOrbitStartTime) * secPerday;
                OrbitNumber = round(dtime / orbitDuration) + previousOrbitNumber;

                % Handle missing orbits

                if OrbitNumber > previousOrbitNumber +1
                    next_orbit_start_time = previousOrbitStartTime;
                    for iFillOrbitNumber=previousOrbitNumber+1:OrbitNumber-1

                        next_orbit_start_time = next_orbit_start_time + orbitDuration;
                        [tempYear, tempMonth, tempDay, tempHour, ~] = datevec(datenum(now));

                        parquet_data{end+1,1} = tempYear;
                        parquet_data{end,2} = tempMonth;
                        parquet_data{end,3} = tempDay;
                        parquet_data{end,4} = tempHour;
                        parquet_data{end,5} = iFillOrbitNumber;
                        parquet_data{end,6} = nan;
                        parquet_data{end,7} = '';
                        parquet_data{end,8} = nan;
                        parquet_data{end,9} = nan;
                        parquet_data{end,10} = nan;
                        parquet_data{end,11} = AWS_missing_in_orbit;

                        checked_list(end+1,2) = next_orbit_start_time;
                        checked_list(end,1) = iFillOrbitNumber;
                    end
                end
                previousOrbitNumber = OrbitNumber;

                % Append data to parquet
                parquet_data{end+1,1} = year;
                parquet_data{end,2} = month;
                parquet_data{end,3} = day(orbitStartTime);
                parquet_data{end,4} = hour(orbitStartTime);
                parquet_data{end,5} = OrbitNumber;
                parquet_data{end,6} = fileOrbitNumber;
                parquet_data{end,7} = orbit_filename;
                parquet_data{end,8} = orbitStartTime;
                parquet_data{end,9} = size(granule_filenames,1);
                parquet_data{end,10} = num_missing_granules;
                parquet_data{end,11} = AWS_missing_in_orbit;


                checked_list(end+1,2) = orbitStartTime;
                checked_list(end,1) = OrbitNumber;

                % If more than 10 orbits have been processed since the last
                % save of the check list, save it.

                if mod(orbitsChecked, 10)
                    save('/Users/petercornillon/Git_repos/MODIS_L2/Data/Aqua_orbit_list', 'checked_list')
                end

            end

            % Convert the data to a table and write to parquet
            parquet_table = cell2table(parquet_data, 'VariableNames', columnNames);
            parquet_filename = sprintf([output_dir '/orbit_data_%04d_%02d.parquet', year, month]);
            parquetwrite(parquet_filename, parquet_table);

            summary_array(year-2001,month,1) = length(orbit_files);
            summary_array(year-2001,month,2) = iMissingThisMonth;
            summary_array(year-2001,month,3) = iDuplicatesThisMonth;

            fprintf('%i orbits found. %i orbits missing and %i duplicates for %i/%i\n\n', length(files), iMissingThisMonth, iDuplicatesThisMonth, month, year)

        end
    end
end

% Close the file
fclose(fileID);

end
