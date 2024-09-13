function process_orbits(yearStart,yearEnd)

% This function processes satellite orbit data by year and month, determines the missing granules,
% and writes the results to a parquet file. It checks for missing granules in each orbit by analyzing
% the interval between granule start times. If a granule is missing, it estimates the start time of the
% missing granule and logs this information. The function also checks for missing granules at the end of the orbit.

% Set up directories
data_dir = '/Volumes/MODIS_L2_Modified/OBPG/SST_Orbits/';
granule_list_dir = '/Users/petercornillon/Dropbox/Data/MODIS_L2/granule_lists/';
output_dir = '/Users/petercornillon/Dropbox/Data/MODIS_L2/check_orbits/';

% Open the file that will contain the filenames for bad files, files that couldn't be read. 
fileID = fopen([check_orbits '/bad_files.txt'], 'w');

% Check if the file opened successfully
if fileID == -1
    error('Failed to open the file for writing.');
end

secPerday = 86400;

% Define time constants
orbit_duration_initial = 5933; % seconds
granule_interval = 300; % seconds
tolerance_orbit = 10; % seconds
tolerance_granule = 2; % seconds
epoch = datenum(1970,1,1,0,0,0); % Epoch time for conversion

columnNames = {'Year', 'Month', 'Day', 'Hour', 'OrbitNumber1', 'OrbitNumber2', 'OrbitFilename', ...
               'OrbitStartTime', '# of Granules Used', '# of Missing Granules', '# of AWS Granules Missing'};
 
% firstOrbit = 886;
% startTimeFirstOrbit =  731401.02765981;
% 
% referenceOrbit = firstOrbit;
% referenceStartTime = startTimeFirstOrbit;
% referenceoOrbitDuration = orbit_duration_initial;
% orbit_duration = orbit_duration_initial;
% 
% previous_orbit_number = referenceOrbit - 1;

orbitsChecked = 0;

iBadFile = 0;

% Load all AWS missing granules first to avoid possible seams between years.


firstOrbitProcessed = true;

% Loop over years.
for year = yearStart:yearEnd

    % Load the missing granules list for the current year
    missing_granules_file = fullfile(granule_list_dir, sprintf('MissingGranuleList_%04dmat.mat', year));
    
    if exist(missing_granules_file, 'file')
        load(missing_granules_file); % Load the missing granules list
    else
        missingList = '';
    end

    for month = 1:12
        clear parquet_data

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
                start_time_str = extractBetween(orbit_filename, '_20', '_L2');
                start_time = datenum(start_time_str, 'yyyymmddTHHMMSS');

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
                scanLineStartTime = datenum(DateTime/86400 + datenum(1970,1,1,0,0,0));

                if abs(scanLineStartTime - start_time)*86400 > 2
                    fprintf('%i) time if first scan line (%s) and time extracted from filename (%s) differ by more than 2 seconds for %s.\n', ...
                        orbitsChecked, datetime(scanLineStartTime), datetime(start_time), orbit_files(iOrbit).name)
                end

                % Calculate time differences between granules
                granule_diffs = diff(granule_start_times) * 86400;
                missing_indices = find(abs(granule_diffs - granule_interval) > tolerance_granule);
                num_missing_granules = length(missing_indices);

                % Check for missing granules at the end
                end_time_of_last_granule = granule_start_times(end) + granule_interval / secPerday;
                time_from_start_to_end = (end_time_of_last_granule - start_time) * secPerday; % Convert to seconds
                if time_from_start_to_end < orbit_duration - tolerance_orbit
                    missing_granules_end = round((orbit_duration - time_from_start_to_end) / granule_interval);
                else
                    missing_granules_end = 0;
                end

                % Check missing granules from the MissingGranuleList
                if ~isempty(missingList)
                    nn = find(start_time <= [missingList.first_scan_line_time] & ...
                        (start_time + orbit_duration/24/3600) >= ([missingList.first_scan_line_time] + 300/24/3600));
                    AWS_missing_in_orbit = length(nn);
                else
                    AWS_missing_in_orbit = 0;
                end

                % Calculate the orbit number
                orbit_number = round((start_time - startTimeFirstOrbit) * secPerday / orbit_duration) + firstOrbit;


                % Initialize variables if this is first orbit being processed.
                
                if firstOrbitProcessed
                    firstOrbit = orbit_number;
                    startTimeFirstOrbit =  start_time;

                    referenceOrbit = firstOrbit;
                    referenceStartTime = startTimeFirstOrbit;
                    referenceoOrbitDuration = orbit_duration_initial;
                    orbit_duration = orbit_duration_initial;

                    previous_orbit_number = firstOrbit - 1;
                    previousStartTime = startTimeFirstOrbit - orbit_duration_initial;

                    firstOrbitProcessed = false;
                end

                % Handle gaps between orbits
                
                for iFill=previous_orbit_number:orbit_number-1
                    next_orbit_start_time = datenum(extractBetween(orbit_files(i+1).name, '_20', '_L2'), 'yyyymmddTHHMMSS');
                    if (next_orbit_start_time - start_time) * secPerday > orbit_duration + tolerance_orbit
                        parquet_data{end+1,1} = year;
                        parquet_data{end,2} = month;
                        parquet_data{end,3} = day(next_orbit_start_time);
                        parquet_data{end,4} = hour(next_orbit_start_time);
                        parquet_data{end,5} = orbit_number + 1;
                        parquet_data{end,6} = nan;
                        parquet_data{end,7} = '';
                        parquet_data{end,8} = nan;
                        parquet_data{end,9} = nan;
                        parquet_data{end,10} = nan;
                        parquet_data{end,11} = AWS_missing_in_orbit;
                    end
                end

                previous_orbit_number = orbit_number;

                % If more than 10 orbits have been processed recalibrate orbit_duration.

                % if orbitsChecked > 10
                %     referenceoOrbitDuration = (start_time - referenceStartTime) *84600 / (referenceOrbit - orbit_number);
                %     if abs(referenceoOrbitDuration - orbit_duration_initial) > 5
                %         fprintf('orbit_duration (%f) has changed by more than 5 s form the initial value of (%f) for orbit %s/n', ...
                %             orbit_duration, orbit_duration_initial, orbit_files(iOrbit).name)
                %     end
                % 
                %     orbit_duration = referenceoOrbitDuration;
                %     referenceStartTime = start_time;
                %     referenceOrbit = orbit_number;
                % end

                % Append data to parquet
                parquet_data{end+1,1} = year;
                parquet_data{end,2} = month;
                parquet_data{end,3} = day(start_time);
                parquet_data{end,4} = hour(start_time);
                parquet_data{end,5} = orbit_number;
                parquet_data{end,6} = fileOrbitNumber;
                parquet_data{end,7} = orbit_filename;
                parquet_data{end,8} = start_time;
                parquet_data{end,9} = size(granule_filenames,1);
                parquet_data{end,10} = num_missing_granules;
                parquet_data{end,11} = AWS_missing_in_orbit;

            end

            % Convert the data to a table and write to parquet
            parquet_table = cell2table(parquet_data, 'VariableNames', columnNames);
            parquet_filename = sprintf([check_orbits '/orbit_data_%04d_%02d.parquet', year, month]);
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
