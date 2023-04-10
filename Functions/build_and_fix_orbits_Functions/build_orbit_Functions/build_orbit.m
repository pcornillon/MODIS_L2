function [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start, granule_start_time_guess] = build_orbit( granule_start_time_guess)
% build_orbit - build the next unprocessed orbit from data granules - PCC
%
% Starting with OBPG metadata file for a granule that includes the start of
% a new orbit--crosses latlim, nomally 78S as the satellite descends--build
% the file name for the orbit, check if it exists, if it does, search for
% the next granule that contains the start of an orbit, continuing until it
% finds one that has not been processed. Then populate lat, lon, SST_In,
% sstref and the flag arrays for the orbit checking along the way for the
% start of a new orbit or for a granule that is clearly beyond the end of
% the current orbit for cases where the granule with the start of the next
% orbit is missing.
%
% INPUT
%   granule_start_time_guess - estimated start time for the next granule.
%
% OUTPUT
%   status  : 0 - OK
%           : 1 - couldn't find the data granule.
%           : 2 - didn't find number_of_lines global attribute.
%           : 3 - number of pixels global attribute not equal to 1354.
%           : 4 - number of scan lines global attribute not between 2020 and 2050.
%           : 5 - couldn't find the metadata file copied from OBPG data.
%           : 6 - 1st detector in data granule not 1st detector in group of 10.
%           : 10 - missing granule.
%           : 11 - more than 2 metadata files for a given time.
%           : 100 - No granule with the start of an orbit found in time range.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   start_time - matlab time of first scan line of the next orbit.
%   scan_seconds_from_start - seconds since start of orbit to this granule.
%   granule_start_time_guess - estimated start time for the next granule.
%

% globals for the run as a whole.

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
global print_diagnostics print_times debug
global npixels

% globals for build_orbit part.

global save_just_the_facts amazon_s3_run
global formatOut
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length secs_per_granule_minus_10 
global index_of_NASA_orbit_change possible_num_scan_lines_skip
global sltimes_avg nlat_orbit nlat_avg orbit_length
global latlim
global sst_range sst_range_grid_size

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t
global Matlab_start_time Matlab_end_time

% globals used in the other major functions of build_and_fix_orbits.

global med_op

status = 0;

% Initialize return variables to simple nans; will return to calling
% program when the start of the next orbit is found.

latitude = single(nan);
longitude = single(nan);
SST_In = single(nan);
qual_sst = int8(nan);
flags_sst = int16(nan);
sstref = single(nan);

scan_seconds_from_start = 0;% Initialize parameters

iGranule = 1;

% Are we starting an orbit without having read a metadata granule for it?
% If so, read the next metadata granule and begin populating this orbit. 
% This could happen if the previous orbit ended with an empty granule; i.e., 
% the loop over the orbit ended because the granule start time exceeded the
% end time of the orbit determined when the orbit first started.

if length(oinfo) < iOrbit
    iGranule = 0;
    
    [status, metadata_file_list, data_file_list, indices, granule_start_time_guess] = find_next_granule_with_data( granule_start_time_guess);
    
    % Return if end of run.
    
    if status > 900
        fprintf('End of run.\n')
        return
    end
end

% Is there an orbit name for this orbit. If not, very bad, quit.

if isempty(oinfo(iOrbit).name)
    if print_diagnostics
        fprintf('No orbit name for iOrbit = %i.\n', iOrbit)
    end
    
    status = populate_problem_list( 241, ['No orbit name for orbit ' num2str(iOrbit)], granule_start_time_guess);
    return
end

%% Skip this orbit if it exist already.

if exist(oinfo(iOrbit).name) == 2
    
    fprintf('--- Have already processed %s. Going to the next orbit. \n', oinfo(iOrbit).name)
    
    start_line_index = [];
        
    while granule_start_time_guess <= oinfo(iOrbit).end_time
        
        [status, metadata_file_list, data_file_list, indices, granule_start_time_guess] = find_next_granule_with_data( granule_start_time_guess);
        
        if ~isempty(start_line_index)
            break
        end
    end
    
    % If no problems set status to 251 ==> this orbit already built.
    if status == 0
        status = 251;
    end
    
    return
end

%% Now build this orbit from its granules; a granule has been found with the start of this orbit.

fprintf('Working on orbit #%i: %s.\n', iOrbit, oinfo(iOrbit).name)

start_time_to_build_this_orbit = tic;

% Initialize orbit arrays.

latitude = single(nan(1354,orbit_length));
longitude = single(nan(1354,orbit_length));
SST_In = single(nan(1354,orbit_length));
qual_sst = int8(nan(1354,orbit_length));
flags_sst = int16(nan(1354,orbit_length));
sstref = single(nan(1354,orbit_length));

scan_seconds_from_start = single(nan(1,orbit_length));

granule_start_time_guess_save = granule_start_time_guess;

fi_granule = oinfo(iOrbit).ginfo(iGranule).data_name;

% Populate the orbit with data from this granule.

[status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = add_granule_data_to_orbit( 'current', fi_granule, latitude, longitude, SST_In, ...
    qual_sst, flags_sst, sstref, scan_seconds_from_start);

if status ~= 0
    return
end

% In the rare--I hope--event when the first granule found in a new orbit
% also contains the start of the next orbit, i.e., .pirate_osscan is not
% empty, pirate data from the next orbit and return.

if isfield(oinfo(iOrbit).ginfo(iGranule), 'pirate_osscan')
    if print_diagnostics
        fprintf('Pirating data on the first call for orbit #%i, granule: \s\n', oinfo(iOrbit).orbit_number, oinfo(iOrbit).ginfo(iGranule).metadata_name)
    end
    
    [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
        = pirate_data( granules_directory, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, ...
        scan_seconds_from_start, granule_start_time_guess);
end

%% Loop over the remainder of granules in this orbit.

while granule_start_time_guess <= oinfo(iOrbit).end_time
    
    %     iGranule = iGranule + 1;
    
    % Get metadata information for the next granule-find_next... increments
    % granule_start_time... by 5 minutes.
    
    [status, metadata_file_list, data_file_list, indices, granule_start_time_guess] = find_next_granule_with_data( granule_start_time_guess);
    
    % Status returned from find_next_granule_with_data is either 0 - all OK,
    % 201 - granule start time exceeded the end of orbit time without
    % finding a granule with a start time in it or 901 end of run. If
    % status = 201 or 901 break out of this loop.
    
    if sum(status == [231 901])
        return
    else
        
        % Populate the orbit with data from this granule.
        
        fi_granule = oinfo(iOrbit).ginfo(iGranule).data_name;
        
        [ status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
            = add_granule_data_to_orbit( 'current', fi_granule, ...
            latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);
        
        % And the data to pirate data if we need to do this.
        
        if isfield(oinfo(iOrbit).ginfo(iGranule), 'pirate_osscan')
            [ status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
                = pirate_data( granules_directory, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, ...
                scan_seconds_from_start, granule_start_time_guess);
        end
    end
end

oinfo(iOrbit).time_to_build_orbit = toc(start_time_to_build_this_orbit);

if print_times
    fprintf('   Time to build this orbit: %6.1f seconds.\n', oinfo(iOrbit).time_to_build_orbit)
end
