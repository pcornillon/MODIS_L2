function [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start, granule_start_time_guess] ...
    = build_orbit( granules_directory, metadata_directory, output_file_directory, granule_start_time_guess)
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
%    the reason for it being skipped (same codes as status):
%    problem_code: 0 - OK
%                : 1 - couldn't find the data granule.
%                : 2 - didn't find number_of_lines global attribute.
%                : 3 - number of pixels global attribute not equal to 1354.
%                : 4 - number of scan lines global attribute not between 2020 and 2050.
%                : 5 - couldn't find the metadata file copied from OBPG data.
%                : 6 - 1st detector in data granule not 1st detector in group of 10. 
%                : 10 - missing granule.
%                : 11 - more than 2 metadata files for a given time. 
%                : 100 - No granule with the start of an orbit found in time range. 
%   granules_directory - the base directory for the input files.
%   metadata_directory - the base directory for the location of the
%   output_file_directory - directory into which the results will be written. 
%   granule_start_time_guess - the matlab_time of the granule to start with.
%   orbit_start_time - matlab time of first scan line in the orbit to be built.
%   oinfo - structure with orbit information.
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
%   orbit_start_time - matlab time of first scan line of the next orbit.
%   granule - structure function with information about granules that went 
%    into this orbit. Fields:
%       metadata_name - name of input granule
%       start_time - time (GMT) of start of granule.
%       end_time - time (GMT) of end of granul (actually should be very
%        close to the start time of the next orbit.
%       data_granule_name - filename for the data granule.
%       osscan - the scan number corresponding to the first scan in the
%        orbit from this granule. This may not be the first scan in the 
%        granule if this is a new orbit.
%       oescan - the scan number corresponding to the last scan in the orbit
%        from this granule. 
%       gsscan - the first scan number in this granule copied to the orbit.
%       gescan - the last scan number in this granule copied to the orbit.
%       status - the return status associated with this granule. 
%   oinfo - updated structure wit orbit info.
%   scan_seconds_from_start - seconds since start of orbit to this granule.
%

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule sltimes_avg nlat_avg
global Matlab_start_time Matlab_end_time
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global print_diagnostics save_just_the_facts
global formatOut

% Initialize return variables.

latitude = single(nan);
longitude = single(nan);
SST_In = single(nan);
qual_sst = int8(nan);
flags_sst = int16(nan);
sstref = single(nan);

% Initialize parameters

iGranule = 1;

check_attributes = 1;

orbit_file_name = ['AQUA_MODIS_orbit_' return_a_string(oinfo(iOrbit).ginfo(1).metadata_name) '_' ...
    datestr(oinfo(iOrbit).start_time, formatOut.yyyymmddThhmmss) '_L2_SST'];

oinfo(iOrbit).name = [output_file_directory datestr(oinfo(iOrbit).start_time, formatOut.yyyy) '/' ...
    datestr(oinfo(iOrbit).start_time, formatOut.mm) '/' orbit_file_name '.nc4'];

%% Skip this orbit if it exist already.

if exist(oinfo(iOrbit).name) == 2
    
    fprintf('--- Have already processed %s. Going to the next orbit. \n', oinfo(iOrbit).name)
    
    [status, metadata_file_list, data_file_list, indices, granule_start_time_guess] = find_start_of_orbit( metadata_directory, granules_directory, granule_start_time_guess);
        
    scan_seconds_from_start = 0;
    
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

% Are we starting an orbit without having read a metadata granule for this
% orbit? If so, read the next metadata granule and begin populating this
% orbit. This could happen if the previous orbit ended with an empty
% granule; i.e., the loop over the orbit ended because the granule start
% time exceeded the end time of the orbit determined when the orbit first
% started.

if isempty(oinfo(iOrbit).ginfo(1).osscan)
    [status, granule_start_time_guess, metadata_file_list, data_file_list, indices] = find_next_granule_with_data( metadata_directory, granules_directory, granule_start_time_guess);
end

% Read the data for the first granule in this orbit.

osscan = oinfo(iOrbit).ginfo(iGranule).osscan;
oescan = oinfo(iOrbit).ginfo(iGranule).oescan;

gsscan = oinfo(iOrbit).ginfo(iGranule).gsscan;
gescan = oinfo(iOrbit).ginfo(iGranule).gescan;

scan_lines_to_read = gescan - gsscan + 1;

fi_granule = oinfo(iOrbit).ginfo(iGranule).data_name;

% Populate the orbit with data from this granule.

[status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = add_granule_data_to_orbit( fi_granule, osscan, oescan, gsscan, gescan, ...
    latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);

if status ~= 0
    return
end

% In the rare--I hope--event when the first granule found in a new orbit
% also contains the start of the next orbit, i.e., .pirate_osscan is not
% empty, pirate data from the next orbit and return.

if ~isempty(oinfo(iOrbit).ginfo(1).pirate_osscan)
    fprintf('Pirating data on the first call for orbit #%i, granule: \s\n', oinfo(iOrbit).orbit_number, oinfo(iOrbit).ginfo(iGranle).metadata_name)
    
    [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
        = pirate_data( granules_directory, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, ...
        scan_seconds_from_start, granule_start_time_guess);    
end
 
% % % % Increment the granule start date/time by 5 minutes and begin looping over
% % % % granules to populate the next orbit.
% % % 
% % % granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);

%% Loop over the remainder of granules in this orbit.

while granule_start_time_guess <= oinfo(iOrbit).end_time
    
    iGranule = iGranule + 1;
    
    % Get metadata information for the next granule-find_next... increments
    % granule_start_time... by 5 minutes.
        
    [status, granule_start_time_guess, metadata_file_list, data_file_list, indices] = find_next_granule_with_data( metadata_directory, granules_directory, granule_start_time_guess);

    % Status returned from find_next_granule_with_data is either 0 - all OK, 
    % 201 - granule start time exceeded the end of orbit time without
    % finding a granule with a start time in it or 901 end of run. If
    % status = 201 or 901 break out of this loop.
    
    if status ~= 0
        break
    else
        
        % Populate the orbit with data from this granule.
        
        fi_granule = oinfo(iOrbit).ginfo(iGranule).data_name;
        
        [ status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
            = add_granule_data_to_orbit( 'current', fi_granule, osscan, oescan, gsscan, gescan, ...
            latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);
        
        % And the data to pirate data if we need to do this.
        
        if ~isempty(oinfo(iOrbit).ginfo(iGranule).pirate_osscan)            
            [ status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
                = pirate_data( granules_directory, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, ...
                scan_seconds_from_start, granule_start_time_guess);
        end
    end
end

oinfo(iOrbit).time_to_build_orbit = toc(start_time_to_build_this_orbit);

if print_diagnostics
    fprintf('   Time to build this orbit: %6.1f seconds.\n', oinfo(iOrbit).time_to_build_orbit)
end
