function [status, metadata_file_list, data_file_list, indices, granule_start_time_guess] = find_start_of_orbit( granule_start_time_guess)
% find_start_of_orbit - Does this granule cross the start of an orbit on descent - PCC
%
% Loop over granules starting at imlat_time in steps of 5 minutes until the
% start of a new granule is found or the granule time exceeds the end time
% passed in.
%
% INPUT
%   granule_start_time_guess - the matlab_time of the granule to start with.
%
% OUTPUT
%   status - returned from find_next_granule_with_data 
%   metadata_file_list - result of a dir function on the metadata directory
%    returning at least one filename.
%   metadata_file_list - result of a dir function on the data directory
%    returning at least one filename.
%   indices - a structure with osscan, oescan, gsscan and gescan for the
%    current orbit, data to be pirated from the next orbit if relevant and,
%    also if relevant, values for the next orbit. 
%   granule_start_time_guess - the matlab_time of the granule to start with.
%

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global Matlab_end_time
global latlim secs_per_day secs_per_orbit secs_per_scan_line orbit_length

start_time = granule_start_time_guess;

% Initialize orbit_scan_line_times to 30 granules and 2040 scan lines. Will
% trim before returning. The problem is that some granules have 2030 scan
% lines on them and others have 2040 so will populate with nans to start.

% Loop over granules until the start of an orbit is found.

while granule_start_time_guess <= Matlab_end_time
    
    [status, granule_start_time_guess, metadata_file_list, data_file_list, indices] ...
        = find_next_granule_with_data( granule_start_time_guess);  
    
    % If this granule contains the start of a new orbit save the info.
    
    if ~isempty(start_line_index)
        % Found the start of the next orbit, save the time and return.
        
        oinfo(iOrbit).start_time = scan_line_times(start_line_index);
        oinfo(iOrbit).end_time = oinfo(iOrbit).orbit_start_time + secs_per_orbit;
        return
    end
    
    % If this granule is past the end of the previous orbit determine an
    % approximate start and end time for the orbit and save them.
    
    if status == 201
        % Get the possible location of this granule in the orbit. If the starts in
        % the 101 scanline overlap region, two possibilities will be returned. We
        % will choose the earlier, smaller scanline, of the two; choosing the later
        % of the two would mean that we would only use the last few scanlines in
        % the orbit, which should have already been done if nadir track of the
        % previous granule crossed 78 S.
        
        target_lat_1 = nlat_t(5);
        target_lat_2 = nlat_t(11);
        
        nnToUse = get_scanline_index( target_lat_1, target_lat_2, oinfo(iOrbit).ginfo(iGranule).metadata_name);
        
        oinfo(iOrbit).start_time = sltimes_avg(nnToUse(1));
        oinfo(iOrbit).end_time = oinfo(iOrbit).orbit_start_time + secs_per_orbit;
        return
    end
end

% If the start of an orbit was not found in the time range specified let
% the person running the program know.

fprintf('*** No start of an orbit in the specified range %s to %s.\n', datestr(start_time), datestr(Matlab_end_time))


