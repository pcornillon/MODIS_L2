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

global start_line_index
global Matlab_end_time
global print_diagnostics

global iProblem problem_list 

start_time = granule_start_time_guess;

% Initialize orbit_scan_line_times to 30 granules and 2040 scan lines. Will
% trim before returning. The problem is that some granules have 2030 scan
% lines on them and others have 2040 so will populate with nans to start.

% Loop over granules until the start of an orbit is found.

while granule_start_time_guess <= Matlab_end_time
    
    [status, granule_start_time_guess, metadata_file_list, data_file_list, indices] ...
        = find_next_granule_with_data( granule_start_time_guess);
 
    if ~isempty(start_line_index)
        return
    end
end

% If the start of an orbit was not found in the time range specified let
% the person running the program know.

if print_diagnostics 
    fprintf('*** No start of an orbit in the specified range %s to %s.\n', datestr(start_time), datestr(Matlab_end_time))
end

