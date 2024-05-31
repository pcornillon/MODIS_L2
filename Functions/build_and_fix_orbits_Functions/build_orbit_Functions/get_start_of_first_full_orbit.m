function [status, granule_start_time] = get_start_of_first_full_orbit(search_start_time)
% get_start_of_first_full_orbit - search from the start time for build_and_fix_orbits for the start of the first full orbit - PCC
%   
% This function starts by searching for the first metadata granule at or
% after the start time passed into build_and_fix_orbits. It then searches
% for the first granule for which the descending nadir track of the
% satellite passes latlim, nominally 78 S.
%
% INPUT
%   search_start_time - the Matlab time at which the search for data
%   granules is to start.
%
% OUTPUT
%   status  : 911 - end of run.
%           : Value returnd from find_start_of_orbit.
% % % %   metadata_file_list - result of a dir function on the metadata directory
% % % %    returning at least one filename.
% % % %   data_file_list - result of a dir function on the data directory
% % % %    returning at least one filename.
%   indices - a structure with osscan, oescan, gsscan and gescan for the
%    current orbit, data to be pirated from the next orbit if relevant and,
%    also if relevant, values for the next orbit. 
%   granule_start_time - the matlab_time of the granule to start with.
%
%  CHANGE LOG 
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/6/2024 - Initial version - PCC
%   1.0.1 - 5/7/2024 - Arguments to search_for_file modified. - PCC
%   1.1.0 - 5/7/2024 - Commented out search for metadata granules for s3
%           separately from the search for URI. Hopeully, there is no
%           difference between the two. - PCC  
%   1.1.1 - 5/12/2024 - Return if status=921 after call to find_next_full...
%   2.0.0 - 5/17/2024 - Modified code for switch to list of granules/times.
%           As part of that replaces granule_start_time_guess with
%           granule_start_time. Updated for new way of handling errors - PCC

global version_struct
version_struct.get_start_of_first_full_orbit = '2.0.0';

local_debug = 0;

% globals for the run as a whole.

global metadata_directory
global print_diagnostics

% globals for build_orbit part.

global amazon_s3_run
global formatOut

global oinfo iOrbit iGranule
global start_line_index
global Matlab_end_time

global granuleList iGranuleList filenamePrefix filenameEnding numGranules

% globals used in the other major functions of build_and_fix_orbits.

global iProblem problem_list 

if local_debug; fprintf('In get_start_of_first_full_orbit.\n'); end

file_list(1).name  = granuleList(iGranuleList).filename;

% Found an hour with at least one metadata file in it. Get the Matlab time
% corresponding to this file. Search for the next granule with the start of
% an orbit, defined as the point at which the descending satellite crosses
% latlim, nominally 78 S. 

granule_start_time = granuleList(iGranuleList).first_scan_line_time;

if local_debug; fprintf('Following while loop. granule_start_time: %s\n', datestr(granule_start_time)); end

start_line_index = [];

while granule_start_time <= Matlab_end_time
    
    % % % iGranuleList = iGranuleList + 1;

    % Zero out iGranule since this is the start of the job and this script
    % is looking for the first granule with a descending 78 S crossing.
    
    iGranule = 0;

    if local_debug; fprintf('In 2nd while loop.\n'); end

    [status, granule_start_time] = find_next_granule_with_data( 1, granule_start_time);

    % if status == 921
    if status >= 900
        return
    end
    
    % find_next_granule_with_data, used in the loop above, looks for the next
    % granule with data in it and it looks to see if the nadir track of the
    % granule crosses 78 S while descending. It if does, it finds the pixel at
    % which this occurs and returns the location of this pixel in the granule
    % in start_line_index.

    if local_debug; fprintf('After call to find_nex_granule_with_data. granule_start_time: %s, start_line_index: %i\n', datestr(granule_start_time), start_line_index); end
    
    % Return if end of run.
    
    % % % % % if status == 201 %%%*** This may require special attention.
    % % % % %     fprintf('*** This should really never happen, but if it does, end the run.\n')
    % % % % %     status = 901;
    % % % % % end
    % % % % % 
    % % % % % if status >= 900 %%%*** I think that this is redunant; same check on line 93.
    % % % % %     fprintf('End of run.\n')
    % % % % %     return
    % % % % % end
    
    if ~isempty(start_line_index)
        break
    end
end

% So, the nadir track of the last granule read crossed 79 S moving northward.
% The way find_next_granule_with_data works is that it populates oinfo(iOrbit) 
% corresponding to the data prior to this crossing and it populates
% oinfor(iOrbit+1) for the portion of the granule after crossing 79 S. When
% build_orbit is called it will be working on iOrbit+1 but it should really
% be iOrbit, so oinfo will be rewritten at this point to address this.

clear temp_oinfo
for iOrb=1:iOrbit-2
    temp_oinfo(iOrb) = oinfo(iOrb);
end
temp_oinfo(iOrbit-1) = oinfo(iOrbit);
oinfo = temp_oinfo;
iOrbit = iOrbit - 1;

% If the start of an orbit was not found in the time range specified let
% the person running the program know.

% % % % % if (status == 201) | (status == 231) | (status > 900) %%%*** Do we need this? I'm guessing that it has already been said.
% % % % %     if print_diagnostics
% % % % %         fprintf('No start of an orbit in the specified range %s to %s.\n', datestr(search_start_time), datestr(Matlab_end_time))
% % % % %     end
% % % % % end

