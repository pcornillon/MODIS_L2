function [status, fi, start_line_index, imatlab_time] = find_start_of_orbit( latlim, metadata_directory, imatlab_time, matlab_end_time)
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

start_time = imatlab_time;

start_line_index = [];

% Loop over granules until the start of an orbit is found.

while imatlab_time <= matlab_end_time
        
    [status, fi, start_line_index, imatlab_time, missing_granule] = build_metadata_filename( 1, latlim, metadata_directory, imatlab_time);
    
    if status ~= 0
        return  % Major problem with metadata files.
    end
    
    % Exit while loop if satellite crosses starting point for an orbit in this granule.
    
    if isempty(start_line_index) == 0
        return
    end
    
    % Add 5 minutes to the previous value of time to get the time of the next granule.
    
    imatlab_time = imatlab_time + 5 / (24 * 60);
end

if isempty(start_line_index)
    fprintf('*** No start of an orbit in the specified range %s to %s.\n', datestr(start_time), datestr(matlab_end_time))
    return
end


