function [status, fi, start_line_index, imatlab_time, orbit_scan_line_times, orbit_start_time, num_scan_lines_in_granule] = ...
    find_start_of_orbit( latlim, metadata_directory, imatlab_time, matlab_end_time)
% find_start_of_orbit - Does this granule cross the start of an orbit on descent - PCC
%
% Loop over granules starting at imlat_time in steps of 5 minutes until the
% start of a new granule is found or the granule time exceeds the end time
% passed in. 
%
% INPUT
%   latlim - the latitude defining the start of an orbit.
%   metadata_directory - the directory with the OBPG metadata files.
%   imatlab_time - the matlab_time of the granule to start with.
%   matlab_end_time - check granules until this time.
%
% OUTPUT
%   status - 0 if success, 1 if problem with detectors.
%   fi - the completely specified filename of the 1st granule for the orbit found.
%   start_line_index - the index in fi for the start of the orbit.
%   imatlab_time - the matlab_time of the granule to start with.
%   orbit_scan_line_times - a 2d array of matlab times for each scan line for
%    each granule for which there is data.
%   orbit_start_time - matlab time of first scan line in the found orbit.
%   num_scan_lines_in_granule - the number of scan lines in the granule
%    for which the nadir track crosses latlim.
%

start_time = imatlab_time;

start_line_index = [];

% Initialize orbit_scan_line_times to 30 granules and 2040 scan lines. Will
% trim before returning. The problem is that some granules have 2030 scan
% lines on them and others have 2040 so will populate with nans to start.

orbit_scan_line_timesT = nan(30,2050);

% Loop over granules until the start of an orbit is found.

iGranule = 0;

while imatlab_time <= matlab_end_time
        
    [status, fi, start_line_index, scan_line_timesT, missing_granule, num_scan_lines_in_granule, imatlab_time] ...
        = build_metadata_filename( 1, latlim, metadata_directory, imatlab_time);
    
    if isempty(missing_granule)
        iGranule = iGranule + 1;
        
        orbit_scan_line_timesT(iGranule,1:num_scan_lines_in_granule) = scan_line_timesT;
    end
    
    if status ~= 0
        return  % Major problem with metadata files.
    end
       
    if isempty(start_line_index)
        
        % Not a new orbit granule; add 5 minutes to the previous value of 
        % time to get the time of the next granule and continue searching.
        
        imatlab_time = imatlab_time + 5 / (24 * 60);
    else
        
        % Found the start of the next orbit, save the time and return.
        
        orbit_start_time = scan_line_timesT(start_line_index);
 
        % Trim the scan line times array to only the number of granules
        % actually read.

        orbit_scan_line_times = orbit_scan_line_timesT(1:iGranule,:);
        return
    end
end

% If the start of an orbit was not found in the time range specified let
% the calling program know.

scan_line_times = [];
orbit_start_time = [];

fprintf('*** No start of an orbit in the specified range %s to %s.\n', datestr(start_time), datestr(matlab_end_time))


