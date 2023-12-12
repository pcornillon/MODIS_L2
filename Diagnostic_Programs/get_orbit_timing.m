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
%    including this time specified as: 
%       [2010 1 1 0 0 0; 2010 4 1 0 0 0] to do first 100 orbits of January
%    and April 2010.
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

latlim = -78;

for iStartTime=1:size(start_date_time,1)
    
    Matlab_start_time = datenum(start_date_time(iStartTime,:));
    
    % Arbitrarily define and end time for the initial searches to be 1 day.
    % after the specified start time.
    
    Matlab_end_time = Matlab_start_time + 1;
        
    iMatlab_time = Matlab_start_time;
    
    %% Find first granule in time range.
    
    while iMatlab_time <= Matlab_end_time
        
        [status, fi, start_line_index, scan_line_times, missing_granules_temp, num_scan_lines_in_granule, imatlab_time] ...
            = check_for_latlim_crossing( 0, nan, metadata_directory, iMatlab_time);
        
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
        
    [status, fi_metadata, start_line_index, iMatlab_time, orbit_scan_line_times, orbit_start_timeT, num_scan_lines_in_granule] ...
        = find_start_of_orbit( latlim, metadata_directory, iMatlab_time, Matlab_end_time);
    
    % Abort this run if a major problem occurs at this point.
    
    if (status ~= 0) | isempty(start_line_index)
        fprintf('*** Major problem with metadata file %s at date/time %s or no start of an orbit in the specified range %s to %s.\n', ...
            fi_metadata, datestr(iMatlab_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
        keyboard
    end
    
    iOrbit = 1;
    
    orbit_start_time(iOrbit) = orbit_start_timeT;
    
    number_of_scans(iOrbit) = num_scan_lines_in_granule - start_line_index + 1;

    NASA_orbit_number(iOrbit) = ncreadatt( fi_metadata,'/','orbit_number');
    
    iMatlab_time = iMatlab_time + 5 / (24 * 60);
    
    %% Now loop over orbits.
    
    % Loop over granules until the start of an orbit is found. It may be
    % the next orbit or more than one orbit after the current one if there
    % are missing granules for the next orbit(s).
        
    while iOrbit <= number_of_orbits
        
        [status, fi, start_line_index, scan_line_timesT, missing_granule, num_scan_lines_in_granule, imatlab_time] ...
            = check_for_latlim_crossing( 1, latlim, metadata_directory, iMatlab_time);
        
        if ~isempty(missing_granule)
            fprintf('Missing granule for orbit #\i at time %s.\n', iOrbit, datestr(iMatlab_time))
        end
        
        if status ~= 0
            fprintf('Major problem for granule on orbit #%i at time %s; status returned as %i. Aborting.\n', iOrbit, datestr(iMatlab_time), status)
            keyboard  % Major problem with metadata files.
        end
        
        if isempty(start_line_index)
            number_of_scans(iOrbit) = number_of_scans(iOrbit) + num_scan_lines_in_granule;
        else
            number_of_scans(iOrbit) = number_of_scans(iOrbit) + start_line_index - 1;
            
            time_for_this_orbit(iOrbit) = scan_line_timesT(start_line_index) - orbit_start_time(iOrbit);
            
            % Found the start of the next orbit, save the time and return.
            
            iOrbit = iOrbit + 1;
            
            orbit_start_time(iOrbit) = scan_line_timesT(start_line_index);
            number_of_scans(iOrbit) = num_scan_lines_in_granule - start_line_index + 1;
            
            NASA_orbit_number(iOrbit) = ncreadatt( fi,'/','orbit_number');
        end
        
        % Add 5 minutes to the previous value of time to get the time of the
        % next granule and continue searching.
        
        iMatlab_time = iMatlab_time + 5 / (24 * 60);
    end
    
    time_for_this_orbit = time_for_this_orbit * 86400;
    
    % Print out some stats. First get all orbits with a reasonable duration.
    
    nn = find(time_for_this_orbit>5000 & time_for_this_orbit<7000);
    
    % Then print stats.
    
    fprintf('\n\nFor orbits between %s and %s\n', datestr(orbit_start_time(1)), datestr(orbit_start_time(end)))
    
    fprintf('\nMin, max, mean and sigma of number of scans: %i, %i, %i and %i\n', ...
        min(number_of_scans(nn)), max(number_of_scans(nn)), mean(number_of_scans(nn)), std(number_of_scans(nn)))
    fprintf('\nMin, max, mean and sigma of orbit time in seconds: %f, %f, %f and %f\n', ...
        min(time_for_this_orbit(nn)), max(time_for_this_orbit(nn)), mean(time_for_this_orbit(nn)), std(time_for_this_orbit(nn)))
    
    save([metadata_directory 'orbit_times_' strrep(datestr(Matlab_start_time), ' ', '_')], 'NASA_orbit_number', 'number_of_scans', 'orbit_start_time', 'time_for_this_orbit')
    
    clear NASA_orbit_number number_of_scans orbit_start_time time_for_this_orbit
end
