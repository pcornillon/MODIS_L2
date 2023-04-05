function [status, indices] = get_osscan_etc_NO_sli
% get_osscan_etc_NO_sli - determine the starting and ending indices for orbit and granule data - PCC
%
% The function will get the starting and ending locations of scanlines in
% the granule most recently read to be copied to the current orbit. It will
% also get the location at which these scanlines are to be written in the
% current orbit.
%
% The function should be called after a the metadata of a granule has been
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

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global Matlab_start_time Matlab_end_time
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length time_of_NASA_orbit_change
global latlim
global print_diagnostics

status = 0;

indices.case = 0;

% Get the possible location of this granule in the orbit. If it starts in
% the 101 scanline overlap region, two possibilities will be returned. The
% earlier one of the two, smaller scanline, will be chosen; choosing the 
% later of the two would mean that only the last few scanlines of the orbit
% would be used in the orbit, which should have already been done if nadir
% track of the previous granule crossed 78 S. 

target_lat_1 = nlat_t(5);
target_lat_2 = nlat_t(11);

nnToUse = get_scanline_index( target_lat_1, target_lat_2);

indices.current.osscan = nnToUse(1);

% alternate_calculation_of_osscan will update the starting location of
% scan lines for this granule in the current orbit if a starting time for
% the orbit has already been found. It will also make that the two
% different ways of determining the location of the scan lines from this
% granule agree with each other within limits. The snippet of code also
% calculates the lines to skip and does various tests on this value. If
% this is the 1st granule found for this orbit, no need to determine
% missing lines from a previous granule, the value above will be used.

alternate_calculation_of_osscan
    
% And for the rest of oescan, gsscan and gescan.

indices.current.oescan = indices.current.osscan + num_scan_lines_in_granule - 1;

indices.current.gsscan = 1;
indices.current.gescan = num_scan_lines_in_granule;

% Is the length of the orbit correct? If not force it to be so.

if indices.current.oescan > orbit_length
    fprintf('Calculated end of orbit is %i, which does not agree with the mandated orbit length, %i. Forcing it to agree.\n', indices.current.oescan, orbit_length)
    indices.current.oescan = orbit_length;
    indices.current.gescan = indices.current.oescan - indices.current.osscan + 1;
    
    status = populate_problem_list( 115, oinfo(iOrbit).ginfo(iGranule).metadata_name);
end
