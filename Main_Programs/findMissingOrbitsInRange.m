function findMissingOrbitsInRange(startYear, endYear)
% Define the base directory
baseDirectory = '/Volumes/MODIS_L2_Modified/OBPG/SST_Orbits/';

% Open file for list of duplicate files, files with the same date but a
% different orbit number.
fileID = fopen('/Users/petercornillon/Dropbox/Data/MODIS_L2/duplicate_list.txt', 'w');

% Check if the file opened successfully
if fileID == -1
    error('Failed to open the file for writing.');
end


Months = {'January' 'February' 'March' 'April' 'May' 'June' 'July' 'August' 'September' 'October' 'November' 'December'};
% Loop over each year in the specified range
for year = startYear:endYear

    % Loop over each month (1 to 12)
    for month = 1:12

        fprintf('\nWorking on %s of %i\n\n', Months{month}, year)

        iMissingThisMonth = 0;

        % Create the directory path for the current year and month
        directory = fullfile(baseDirectory, num2str(year), sprintf('%02d', month));

        % Check if the directory exists
        if ~isfolder(directory)
            fprintf('Directory %s does not exist. Skipping...\n', directory);
            continue;
        end

        % Find all files in the current directory
        files = dir(fullfile(directory, '*.nc4'));

        if isempty(files)
            fprintf('No files found in %s. Skipping...\n', directory);
            continue;
        end

        % Initialize a structure to store the parsed times
        orbitTimes = [];

        % Loop through the files and extract times
        for i = 1:length(files)
            % Extract the filename
            filename = files(i).name;

            % Extract the datetime portion from the filename
            datetimeStr = extractBetween(filename, '_20', '_L2');
            if isempty(datetimeStr)
                continue; % Skip if the format is not as expected
            end

            % Reconstruct the full datetime string
            datetimeStr = ['20' datetimeStr{1}]; % Add '20' back to the start

            % Convert the extracted datetime string to MATLAB datetime
            orbitTime = datetime(datetimeStr, 'InputFormat', 'yyyyMMdd''T''HHmmss');

            % Append the datetime to the list
            orbitTimes = [orbitTimes; orbitTime];
        end

        % If there are no valid times, continue to the next directory
        if isempty(orbitTimes)
            fprintf('No valid orbit times found in %s. Skipping...\n', directory);
            continue;
        end

        % Sort the times in ascending order
        orbitTimes = sort(orbitTimes);

        % Calculate the time differences between consecutive orbits
        timeDifferences = seconds(diff(orbitTimes));

        % Set the expected time difference range
        expectedTime = 5933;
        tolerance = 10;

        % Identify any deviations outside the tolerance
        missingOrbits = find(abs(timeDifferences - expectedTime) > tolerance);

        % Display the results for the current directory
        if isempty(missingOrbits)
            fprintf('No missing orbits found in %s within the given tolerance.\n', directory);
        else
            % fprintf('Potential missing orbits found in %s:\n', directory);
            for iMissing = 1:length(missingOrbits)
                iMissingThisMonth = iMissingThisMonth + 1;
                
                % Find the number of missing files.
                num_missing_orbits = round(timeDifferences(missingOrbits(iMissing)) / expectedTime);

                % If this number is zero means two files with the same
                % date. I will likely want to delete the first one in the
                % pair but for now, just them out to a new file. These
                % duplicates resulted when I changed to using the list of
                % files that correspond to the files from OBPG as opposed
                % to generating the file names on the fly. For some reason
                % this resulted in a different orbit number, which will
                % also need to be fixed.

                if num_missing_orbits == 0
                    fprintf(fileID, '%s duplicated %s\n', files(missingOrbits(iMissing)).name, files(missingOrbits(iMissing)+1).name);
                else

                    fprintf('%i) %.2f seconds (%i missing orbits) missing between %s and %s\n', iMissingThisMonth, ...
                        timeDifferences(missingOrbits(iMissing)), ...
                        num_missing_orbits, ...
                        files(missingOrbits(iMissing)).name(18:39), ...
                        files(missingOrbits(iMissing)+1).name(18:39))
                end
            end
        end
        fprintf('%i orbits missing for %i/%i\n\n', iMissingThisMonth, month, year)
    end
end

% Close the file
fclose(fileID);

end
