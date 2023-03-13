function [status, granule_start_time_guess] = find_start_of_orbit( metadata_directory, granule_start_time_guess)
% % % function [status, start_line_index, granule_start_time_guess, orbit_scan_line_times, num_scan_lines_in_granule] = ...
% % %     find_start_of_orbit( metadata_directory, granule_start_time_guess)
% find_start_of_orbit - Does this granule cross the start of an orbit on descent - PCC
%
% Loop over granules starting at imlat_time in steps of 5 minutes until the
% start of a new granule is found or the granule time exceeds the end time
% passed in. 
%
% INPUT
%   metadata_directory - the directory with the OBPG metadata files.
%   granule_start_time_guess - the matlab_time of the granule to start with.
%
% OUTPUT
%   status  : 0 - OK
%           : 6 - 1st detector in data granule not 1st detector in group of 10. 
%           : 10 - missing granule.
%           : 11 - more than 2 metadata files for a given time. 
%           : 100 - No granule with the start of an orbit found in time range. 
% % %   start_line_index - the index in fi for the start of the orbit.
%   granule_start_time_guess - the matlab_time of the granule to start with.
% % %   orbit_scan_line_times - a 2d array of matlab times for each scan line for
% % %    each granule for which there is data.
% % %   num_scan_lines_in_granule - the number of scan lines in the granule
% % %    for which the nadir track crosses latlim.
%

global iOrbit orbit_info iGranule
global scan_line_times start_line_index num_scan_lines_in_granule
global Matlab_end_time

start_time = granule_start_time_guess;

% % % start_line_index = [];

% Initialize orbit_scan_line_times to 30 granules and 2040 scan lines. Will
% trim before returning. The problem is that some granules have 2030 scan
% lines on them and others have 2040 so will populate with nans to start.

% % % orbit_scan_line_timesT = nan(30,2050);

% Loop over granules until the start of an orbit is found.

% % % jGranule = 0;

while granule_start_time_guess <= Matlab_end_time
        
% % %     [status, start_line_index, scan_line_timesT, missing_granule, num_scan_lines_in_granule, granule_start_time_guess] ...
% % %         = get_granule_metadata( metadata_directory, granule_start_time_guess);
    [status, missing_granule, granule_start_time_guess] = get_granule_metadata( metadata_directory, granule_start_time_guess);
    
% % %     if isempty(missing_granule)
% % %         jGranule = jGranule + 1;
% % %         
% % %         orbit_scan_line_timesT(jGranule,1:num_scan_lines_in_granule) = scan_line_timesT;
% % %     end
    
    if status ~= 0
        return  % Major problem with metadata files.
    end
       
    if isempty(start_line_index)
        
        % Not a new orbit granule; add 5 minutes to the previous value of 
        % time to get the time of the next granule and continue searching.
        
        granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);
    else
        
        % Found the start of the next orbit, save the time and return.
        
% % %         orbit_info(iOrbit).orbit_start_time = scan_line_timesT(start_line_index);
        orbit_info(iOrbit).orbit_start_time = scan_line_times(start_line_index);
%         orbit_info(iOrbit).granule_info(jGranule).metadata_name = 
% % %         % Trim the scan line times array to only the number of granules
% % %         % actually read.
% % % 
% % %         orbit_scan_line_times = orbit_scan_line_timesT(1:jGranule,:);
        return
    end
end

% If the start of an orbit was not found in the time range specified let
% the calling program know.

status = 100;

scan_line_times = [];
orbit_info(iOrbit).orbit_start_time = [];

fprintf('*** No start of an orbit in the specified range %s to %s.\n', datestr(start_time), datestr(Matlab_end_time))


