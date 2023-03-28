function [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = pirate_data( granules_directory, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, ...
    scan_seconds_from_start, granule_start_time_guess)
% pirate_data - reads data from next granule and puts it in orbit - PCC.
% 
% Increments the current start time by 5 minues and does a dir on the
% granules direcotry for a data granule within 30 seconds or so of the new
% guess. If it doesn't find a file it writes an error and returns. If it
% does find a granule it reads from the granule and completes the orbit it
% is working on.
% 
% INPTUT
%   status - 0 if all good, 122 if no data granule found.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   scan_seconds_from_start - seconds for from the start of the orbit.
%
% OUTPUT
%   granule_directory - the directory with the data files.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   scan_seconds_from_start - seconds for from the start of the orbit.
%   granule_start_time_guess - the matlab_time of the first scan line in
%    the current granule.
%

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global formatOut
global latlim
global amazon_s3_run

status = 0;

% Get file list for data granule at the next time step.

temp_time = granule_start_time_guess + 5 / (24 * 60);

if amazon_s3_run
    % Here for s3. May need to fix this; not sure I will have combined
    % in the name. Probably should set up to search for data or
    % metadata file as we did for the not-s3 run.
    % s3 data granule: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100619052000-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc
    
    data_file_list = dir( [granules_directory datestr(temp_time, formatOut.yyyy) '/' datestr(temp_time, formatOut.yyyymmddhhmm) '*-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc']);
else
    data_file_list = dir( [granules_directory datestr(temp_time, formatOut.yyyy) '/AQUA_MODIS.' datestr(temp_time, formatOut.yyyymmddThhmm) '*']);
end

if isempty(data_file_list)
    fprintf('*** No data granule found for %s but pirate_osscan is not empty. Should never get here. No scan lines added to the orbit.\n', datestr(temp_time))
    
    status = populate_problem_list( 122, oinfo(iOrbit).ginfo(1).metadata_name);
else        
    fi_granule = [data_file_list(1).folder '/' data_file_list(1).name];
    
    [ status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
        = add_granule_data_to_orbit( 'pirate', fi_granule, ...
        latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);
end

