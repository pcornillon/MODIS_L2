function missing_granules = find_missing_granules( granules_directory, Year)
% find_missing_granules - sequence through all granules in a year to find missing ones - PCC
%
% INPUT
%   granules_directory - the base directory for the input files.
%   Year - year to process.
%
% OUTPUT
%   missing_granules - list of date/time of missing granules.
%

imatlab_time = datenum( Year, 1, 1, 0, 0, 0);
matlab_end_time = datenum( Year, 12, 31, 23, 59, 59);

start_time = imatlab_time;

% Initialize return variables in case there is a problem.

missing_granules = '';

% Loop over granules until the start of an orbit is found.

tic_start = tic;
num_to_print = 10000;

iFile = 0;
while imatlab_time <= matlab_end_time
    
    iFile = iFile + 1;
    
    [status, fi, start_line_index, imatlab_time, missing_granules{iFile}] = ...
        build_metadata_filename( 0, nan, granules_directory, imatlab_time);
    
    if mod(iFile,num_to_print) == 0
        fprintf('Processed file #%i - %s - Elapsed time %6.0f seconds. \n', iFile, convertCharsToStrings(fi), toc(tic_start))
    end
    
    if status ~= 0
        return  % Major problem with metadata files.
    end
    
    % Add 5 minutes to the previous value of time to get the time of the next granule.
    
    imatlab_time = imatlab_time + 5 / (24 * 60);
    
end

