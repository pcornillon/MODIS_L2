function [ Years, granules_directory, missing_granules] = find_missing_granules( granules_directory, Years)
% find_missing_granules - sequence through all granules in a year to find missing ones - PCC
%
% INPUT
%   granules_directory - the base directory for the input files.
%   Years - a vector of the years to process.
%
% OUTPUT
%   Years - same as input, just so they are in workspace when done.
%   granules_directory - same as input for the same reason.
%   missing_granules - list of date/time of missing granules.
%

% Initialize return variables in case there is a problem.

missing_granules = [];

iYear = 0;
for Year=Years

    fprintf('\n\n Working on %i\n\n', Year)

    iYear = iYear + 1;

    if Year == 2002
        imatlab_time = datenum( Year, 7, 4, 0, 0, 0);
    else
        imatlab_time = datenum( Year, 1, 1, 0, 0, 0);
    end
    
    matlab_end_time = datenum( Year, 12, 31, 23, 59, 59);

    start_time = imatlab_time;

    % Loop over granules until the start of an orbit is found.

    tic_start = tic;
    num_to_print = 1000;

    iMissing = 0;
    iFile = 0;
    while imatlab_time <= matlab_end_time

        iFile = iFile + 1;

        [status, fi, ~, ~, missing_granules_temp] = ...
            build_metadata_filename( 0, nan, granules_directory, imatlab_time);

        if mod(iFile,num_to_print) == 0
            fprintf('Processed file #%i - %s - Elapsed time %6.0f seconds. \n', iFile, convertCharsToStrings(fi), toc(tic_start))
        end

        if ~isempty(missing_granules_temp)
            iMissing = iMissing + 1;
            missing_granules(iYear,iMissing) = missing_granules_temp;
        end

        if status ~= 0
            return  % Major problem with metadata files.
        end

        % Add 5 minutes to the previous value of time to get the time of the next granule.

        imatlab_time = imatlab_time + 5 / (24 * 60);
    end
end

fprintf('All done.\n')
