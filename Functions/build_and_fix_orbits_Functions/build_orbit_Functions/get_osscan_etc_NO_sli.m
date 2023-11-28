function [status, indices] = get_osscan_etc_NO_sli(indices)
% get_osscan_etc_NO_sli - determine the starting and ending indices for orbit and granule data - PCC
%
% The function will get the starting and ending locations of scanlines in
% the granule most recently read to be copied to the current orbit. It will
% also get the location at which these scanlines are to be written in the
% current orbit.
%
% The function should be called after the metadata of a granule has been
% read and NO end of orbit, empty(start_line_index), has been found.
%
% The function will calculate the starting and ending indices for the data
% from the current granule in the current orbit and in the next orbit. It
% will also determine whether or not data is needed from the next granule
% to complete the current orbit. If so, it will determine the start and end
% indices for that orbit. It will also determine the corresponding
% locations from which to copy the data in the current granule.
%
% INPUT
%
% OUTPUT
%   status - if 65 do not populate orbit for this granule.
%   indices - a structure with the discovered indices.
%

% globals for the run as a whole.

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
global print_diagnostics print_times debug
global npixels

% globals for build_orbit part.

global save_just_the_facts amazon_s3_run
global formatOut
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length secs_per_granule_minus_10 
global index_of_NASA_orbit_change possible_num_scan_lines_skip
global sltimes_avg nlat_orbit nlat_avg orbit_length
global latlim
global sst_range sst_range_grid_size

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t
global Matlab_start_time Matlab_end_time

% globals used in the other major functions of build_and_fix_orbits.

global med_op

% time for 2030 and 2040 scans from 5 to end-5: 298.3760  299.8540
% 2040 scan line granule every 10 or 11 granules. 

status = 0;

indices.case = 0;
    
% And for the rest of oescan, gsscan and gescan.

indices.current.oescan = indices.current.osscan + num_scan_lines_in_granule - 1;

indices.current.gsscan = 1;
indices.current.gescan = num_scan_lines_in_granule;

% Is the length of the orbit correct? If not force it to be so.

if indices.current.oescan > orbit_length
    % The number of scan lines between descending crossings of 78 S should
    % be 40,170, to which we add 1 to allow for bow-tie correction and 100
    % for orbit overlap. If indices.current.oescan is greater than this we
    % have moved beyond the end of an orbit and, because we are in this
    % function, without finding descending equatorial crossing. This means
    % that there was a serious problem. I don't think that it should
    % happen. 

    if print_diagnostics
        fprintf('***** Calcualted length of orbit for %s is %i, which is greater than %i. This should not happen.\n', oinfo(iOrbit).ginfo(iGranule).metadata_name, indices.current.oescan, orbit_length);
    end
    
    indices.current.oescan = orbit_length;
    indices.current.gescan = indices.current.oescan - indices.current.osscan + 1;
    
    status = populate_problem_list( 415, ['***** Calcualted length of orbit for ' oinfo(iOrbit).ginfo(iGranule).metadata_name ' is ' num2str(indices.current.oescan) ', which is greater than ' num2str(orbit_length) '. This should NEVER happen.']);
end
