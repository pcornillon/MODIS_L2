function [scan_line_times, start_line_index, num_scan_lines_in_granule, temp_granule_start_time] = get_start_of_first_full_orbit( metadata_directory, Matlab_start_time)
% get_start_of_first_full_orbit - search from the start time for build_and_fix_orbits for the start of the first full orbit - PCC
%   
% This function starts by searching for the first metadata granule at or
% after the start time passed into build_and_fix_orbits. It then searches
% for the first granule for which the descending nadir track of the
% satellite passes latlim, nominally 78 S.
%
% INPUT
%   metadata_directory - directory with the input files
%   temp_granule_start_time - the time to start searching for exisitng metadata granules.
%
% OUTPUT
%   scan_line_times - vector for the start of each scan line in the last
%    granule read in find_start_of_orbit. 
%   start_line_index - the index of the scan line in this granule with the
%    start of a new orbit.
%   num_scan_lines_in_granule - number of scan lines in the last granule
%    read in find_start_of_orbit. 
%   temp_granule_start_time - time of the start of the granule with the
%    start of the next orbit.
%

global iOrbit orbit_info iGranule
global print_diagnostics save_just_the_facts
global formatOut
global latlim secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global Matlab_end_time
global sst_range sst_range_grid_size
global med_op
global amazon_s3_run

% temp_granule_start_time is the time, a dummy variable, for the approximate
% start time of a granule. It will be incremented by 5 minutes/granule as
% this script loops through granules. Need to find the first granule in the
% range. Since there has to be a metadata granule corresponding to the
% first data granule, search for the first metadata granule. Note that
% build_metadata_filename will upgrade temp_granule_start_time to the
% actual time of the 1st scan when called with 1 for the 1st argument. This
% effectively syncs the start times to avoid any drifts.

% Because the time input to build_and_fix_orbits may not be at a minute
% when the first metadata file exists start with a broader search; search
% for a granule in the given hour. Remove minutes and seconds from the
% specified start time.

file_list = [];

temp_granule_start_time = floor(Matlab_start_time*24) / 24 - 1 / 24;

while isempty(file_list)
    temp_granule_start_time = temp_granule_start_time + 1/24;
    
    if temp_granule_start_time > Matlab_end_time
        fprintf('Didn''t find a metadata granule between %f and %f.\n', Matlab_start_time, Matlab_end_time)
        status = 100;
        return
    end
    
    index_offset = 1;
    if amazon_s3_run
        index_offset = 0;
        % Here for s3. May need to fix this; not sure I will have combined 
        % in the name. Probably should set up to search for data or
        % metadata file as we did for the not-s3 run.
        file_list = dir( [metadata_directory datestr(Matlab_start_time, formatOut.yyyy) '/AQUA_MODIS_' datestr(Matlab_start_time, formatOut.yyyymmddThh) '*']);
        file_list = dir( [metadata_directory datestr(Matlab_start_time, formatOut.yyyy) '/AQUA_MODIS_' datestr(Matlab_start_time, formatOut.yyyymmdd) '*']);
    elseif isempty(strfind(metadata_directory,'combined'))
        % Here if looking for a metadata file - notice the underscore after MODIS.
        file_list = dir( [metadata_directory datestr(Matlab_start_time, formatOut.yyyy) '/AQUA_MODIS_' datestr(Matlab_start_time, formatOut.yyyymmddThh) '*']);
    else
        % Here if looking for a data file - notice the period after MODIS.
        file_list = dir( [metadata_directory datestr(Matlab_start_time, formatOut.yyyy) '/AQUA_MODIS.' datestr(Matlab_start_time, formatOut.yyyymmddThh) '*']);
    end
end

% Found an hour with at least one metadata file in it. Get the Matlab time
% corresponding to this file (yyyy mm dd T hh mm ss is good enough) and
% starting with the time of this file, search for a granule with the start
% of an orbit, defined as the point at which the descending satellite crosses 
% latlim, nominally 78 S.

% fi_metadata: AQUA_MODIS_20030101T002505_L2_SST_OBPG_extras.nc4

nn = strfind( file_list(1).name, 'AQUA_MODIS_');
yyyy = str2num(file_list(1).name(nn+11:nn+14));
mm = str2num(file_list(1).name(nn+15:nn+16));
dd = str2num(file_list(1).name(nn+17:nn+18));
HH = str2num(file_list(1).name(nn+19+index_offset:nn+20+index_offset));
MM = str2num(file_list(1).name(nn+21+index_offset:nn+22+index_offset));

temp_granule_start_time = datenum(yyyy,mm,dd,HH,MM,0);

% Next, find the ganule at the beginning of the first complete orbit
% starting with the first granule found in the time range.

[status, start_line_index, temp_granule_start_time, orbit_scan_line_times, num_scan_lines_in_granule] ...
    = find_start_of_orbit( metadata_directory, temp_granule_start_time);

% Abort this run if a major problem occurs at this point.

if status ~= 0
    fprintf('*** Major problem with metadata file %s at date/time %s or no start of an orbit in the specified range %s to %s. Aborting.\n', ...
        orbit_info(iOrbit).granule_info(iGranule).metadata_name, datestr(temp_granule_start_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
    
    % See explanation at end of this section for setting iOrbit to 0.
    
    iOrbit = 0;
    return
end

% Load the scan line times for the last granule found, the first
% granule in a new orbit.

scan_line_times = orbit_scan_line_times(end,1:num_scan_lines_in_granule);

% Note that we used num_scan_lines_in_granule in the above since there
% could be nans for the last scan lines since the orbit_scan_line_times
% array was inialized with nans for the longest expected granule, 2050 scan
% lines; actually never expect more than 2040 but, just in case...

% Save the start time for this orbit.
    
orbit_info(iOrbit).orbit_start_time = scan_line_times(start_line_index);

% Need to set iOrbit to 0, it should be 1 here but the next step is to
% loop over all granule times in the time range and we start by
% incrementing iOrbit by one so that it increments properly from
% orbit-to-orbit but for this the first one we will already have loaded
% orbit_info stuff so decrementing by 1 here means that the remainder of
% the orbit_info stuff will be stored for orbit #1.

iOrbit = 0;

% Note that find_start_of_orbit does not increment iGranule so no need to
% mess with orbit_info(iOrbit).granule_info.

end

