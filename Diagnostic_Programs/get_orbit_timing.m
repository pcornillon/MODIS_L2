function [ orbit_start_time, time_for_this_orbit, number_of_scans, NASA_orbit_number] = get_orbit_timing( metadata_directory, start_date_time, number_of_orbits)
% get_orbit_timing - determine time for an orbit, for a scan and # scans/orbit - PCC
%  
% This function will read sequential granules obtaining their length in
% time and scan lines. It starts by finding the granule with the start of 
% the first orbit after the input time. Once found, it determines the time
% of the first scan, then searches for the start of the next orbit counting
% scans for all granules in between. It continues this way until the
% specified number of orbits have been found. It requires that all orbits
% be compete and will stop if a granule is missing.
%
% INPUT
%   metadata_directory - the base directory for the location of the
%    metadata files used in this function.
%   start_date_time - build orbits with the first orbit to be built
%    including this time specified as: [YYYY, MM, DD, HH, Min, 00].
%   number_of_orbits - the number of orbits to process starting at
%    start_date_time.
%
% OUTPUT
%   orbit_start_time - the start time of this orbit.
%   time_for_this_orbit - time from beginning of this orbit to the
%    beginning of the next orbit.
%   number_of_scans - number of scans/orbit.
%   NASA_orbit_number - orbit number read from the file.
%

Matlab_start_time = datenum(start_date_time);

% Arbitrarily define and end time for the initial searches to be 1 day.
% after the specified start time.

Matlab_end_time = Matlab_start_time + 1; 

latlim = -78;

iMatlab_time = Matlab_start_time;

%% Find first granule in time range.

while iMatlab_time <= Matlab_end_time
    
    
    [status, fi, start_line_index, scan_line_times, missing_granules_temp] ...
        = build_metadata_filename( 0, nan, metadata_directory, iMatlab_time);
    
    if ~isempty(fi)
        fprintf('First granule in the specified range (%s, %s) is: %s\n', datestr(Matlab_start_time), datestr(Matlab_end_time), fi)
        break
    end
    
    % Add 5 minutes to the previous value of time to get the time of the next granule.
    
    iMatlab_time = iMatlab_time + 5 / (24 * 60);
    
end

if iMatlab_time > Matlab_end_time
    fprintf('****** Could not find a granule in the specified range (%s, %s) is: %s\n', datestr(Matlab_start_time), datestr(Matlab_end_time), fi)
    keyboard
end

%% Find start of first orbit.

% Next, find the ganule at the beginning of the first complete orbit
% defined as starting at descending latlim, nominally 78 S.

start_line_index = [];

[status, fi_metadata, start_line_index, iMatlab_time, orbit_scan_line_times, orbit_start_timeT] ...
    = find_start_of_orbit( latlim, metadata_directory, iMatlab_time, Matlab_end_time);

% Abort this run if a major problem occurs at this point. 

if (status ~= 0) | isempty(start_line_index)
    fprintf('*** Major problem with metadata file %s at date/time %s or no start of an orbit in the specified range %s to %s.\n', ...
        fi_metadata, datestr(iMatlab_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
    keyboard
end

iOrbit = 1;

orbit_start_time(iOrbit) = orbit_start_timeT;

iMatlab_time = iMatlab_time + 5 / (24 * 60);

%% Now loop over orbits.

% Loop over granules until the start of an orbit is found.

iGranule = 0;

number_of_scans(iOrbit) = size(orbit_scan_line_times,2) - start_line_index + 1;
NASA_orbit_number(iOrbit) = ncreadatt( fi_metadata,'/','orbit_number');

while iOrbit <= number_of_orbits
        
    [status, fi, start_line_index, scan_line_timesT, missing_granule] ...
        = build_metadata_filename( 1, latlim, metadata_directory, iMatlab_time);
    
    if ~isempty(missing_granule)
        fprintf('Missing granule for orbit #\i at time %s. Aborting.\n', iOrbit, datestr(iMatlab_time))
        keyboard
    end
    
    if status ~= 0
        fprintf('Major problem for granule on orbit #%i at time %s; status returned as %i. Aborting.\n', iOrbit, datestr(iMatlab_time), status)
        keyboard  % Major problem with metadata files.
    end
        
    if isempty(start_line_index)
        number_of_scans(iOrbit) = number_of_scans(iOrbit) + length(scan_line_timesT);        
    else
        number_of_scans(iOrbit) = number_of_scans(iOrbit) + start_line_index - 1; 
        
        time_for_this_orbit(iOrbit) = scan_line_timesT(start_line_index) - orbit_start_time(iOrbit);

        % Found the start of the next orbit, save the time and return.

        iOrbit = iOrbit + 1;

        orbit_start_time(iOrbit) = scan_line_timesT(start_line_index);
        number_of_scans(iOrbit) = length(scan_line_timesT) - start_line_index + 1;

        NASA_orbit_number(iOrbit) = ncreadatt( fi_metadata,'/','orbit_number');
    end

    % Add 5 minutes to the previous value of time to get the time of the
    % next granule and continue searching.

    iMatlab_time = iMatlab_time + 5 / (24 * 60);
end

save([metadata_directory 'orbit_times_' strrep(datestr(start_date_time), ' ', '_')], 'number_of_scans', 'NASA_orbit_number', 'orbit_start_time', 'time_for_this_orbit')