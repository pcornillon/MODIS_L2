function [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = pirate_data_here(metadata_directory, granules_directory, granule_start_time_guess, check_attributes, ...
    latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start)
% pirate_from_next_granule - fill remainder of an orbit from the next granule - PCC
%
% This occurs when the additional 100 line buffer added to an orbit goes
% beyond the granule with the start of a new orbit.
%

global iOrbit oinfo iGranule problem_list
global scan_line_times start_line_index num_scan_lines_in_granule sltimes_avg nlat_avg
global Matlab_end_time 
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global print_diagnostics save_just_the_facts
global formatOut

status = 0;

% Save scan_line_times... because they will be changed in call to 
% get_granule_metadata and we want to keep the old values.

save_scan_line_times = scan_line_times;
save_start_line_index = start_line_index;
save_num_scan_lines_in_granule = num_scan_lines_in_granule;

iGranule = iGranule + 1;

% Get the metadata for the next granule.

[statusT, missing_granuleT, temp_granule_start_time] = get_granule_metadata( metadata_directory, granule_start_time_guess + 5 / (24 * 60));

% Check to make sure that there is data in the next granule. If not, skip.

if isempty(missing_granuleT)
    status = 80;
end

oinfo(iOrbit).ginfo(iGranule).start_time = scan_line_times(1) * secs_per_day;
oinfo(iOrbit).ginfo(iGranule).end_time = scan_line_times(end) * secs_per_day + secs_per_scan_line * 10;

oinfo(iOrbit).ginfo(iGranule).status = statusT;

lines_to_skip = floor( abs((temp_granule_start_time * secs_per_day - oinfo(iOrbit).ginfo(iGranule-1).end_time) + 0.05) / secs_per_scan_line);

% Done building this orbit if the next granule is missing, go to
% processing. Otherwise read data from next granule into this orbit.

if (lines_to_skip > 11) | statusT~=0
    
    % Decrement iGranule; we want to set up for the next orbit
    % and we had to add a granule to this one because it
    % extended past the end when we added the extra 100 lines.
    
    iGranule = iGranule - 1;
    
    % Retrieve the old version fo scan_line_times, ...
    
    scan_line_times = save_scan_line_times;
    start_line_index = save_start_line_index;
    num_scan_lines_in_granule = save_num_scan_lines_in_granule;
else
    oinfo(iOrbit).ginfo(iGranule).osscan = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1;
    oinfo(iOrbit).ginfo(iGranule).oescan = orbit_length;
    
    oinfo(iOrbit).ginfo(iGranule).gsscan = 1;
    oinfo(iOrbit).ginfo(iGranule).gescan = oinfo(iOrbit).ginfo(iGranule).oescan - oinfo(iOrbit).ginfo(iGranule).osscan + 1;
    
    [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
        = add_granule_data_to_orbit( granules_directory, check_attributes, ...
        latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);
    
    % Decrement iGranule; we want to set up for the next orbit
    % and we had to add a granule to this one because it
    % extended past the end when we added the extra 100 lines.
    
    iGranule = iGranule - 1;
    
    % Retrieve the old version fo scan_line_times, ...
    
    scan_line_times = save_scan_line_times;
    start_line_index = save_start_line_index;
    num_scan_lines_in_granule = save_num_scan_lines_in_granule;
end

