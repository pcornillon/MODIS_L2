function [status, indices] = get_osscan_etc_with_sli
% get_osscan_etc_with_sli - determine the starting and ending indices for orbit and granule data - PCC
%
% The function will get the starting and ending locations of scanlines in
% the granule most recently read to be copied to the current orbit. It will
% also get the location at which these scanlines are to be written in the
% current orbit.
%
% The function should be called after the end of an orbit has been found in
% the granule just read.
%
% The function will calculate the starting and ending indices for the data
% from the current granule in the current orbit and in the next orbit. It
% will also determine whether or not data is needed from the next granule
% to complete the current orbit. If so, it will determine the start and end
% indices for that orbit. It will also determine the corresponding
% locations from which to copy the data in the current granule.
%
% INPUT
% % % %   continue_orbit - 1 to get the indices to complete the current orbit and
% % % %    begin building the next one, 0 to get the indices to begin building
% % % %    the next orbit only.
% % % %   temp_filename - name of metadata file on which we are working.
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
global print_diagnostics

status = 0;

% Get the possible location of this granule in the orbit. If it starts in
% the 101 scanline overlap region, two possibilities will be returned. We
% will choose the earlier, smaller scanline, of the two; choosing the later
% of the two would mean that we would only use the last few scanlines in
% the orbit, which should have already been done if nadir track of the
% previous granule crossed 78 S.

target_lat_1 = nlat_t(5);
target_lat_2 = nlat_t(11);

temp_filename = oinfo(iOrbit).ginfo(iGranule).metadata_name;
nnToUse = get_scanline_index( target_lat_1, target_lat_2, temp_filename);

% Check to see if the location of this granule results in the same start
% time for the orbit if that has already been determined.

if ~isempty(oinfo(iOrbit).start_time)
    temp_start_time = scan_line_times(1) - sltimes_avg(nnToUse(1)) / secs_per_day;
    
    start_time_difference = (temp_start_time - oinfo(iOrbit).start_time) * secs_per_day; 
    if abs(start_time_difference) > 1.5
        fprintf('Start times differ by more than 1.5 s. The start time for the orbit based on this granule minus that for the 1st granule found in the orbit is %f s\n', ...
            start_time_difference)
        
        status = populate_problem_list( 119, 'Start times don''t agree.');
    end
end

indices.current.osscan = nnToUse(1);

% This case is the simplest, the number of scanlines required to complete
% this orbit--go to the start of the next orbit + 101 scanlines for overlap
% with next orbit--exist in this granule. Generate the relevant information
% for the location of scanlines in the current and next orbits and where to
% extract them from the current granule.

indices.case = 1;

% The following is a snippet of code to generate osscan using the start
% time of this granule and the end time of the previous granule and to
% compare the result obtained above using the canonical orbit. This
% snippet is also used in get_osscan_etc_NO_sli.

alternate_calculation_of_osscan

% Add 101 to osscan + sli to get 100 scanline overlap of this orbit
% with the next one plus an additional line, hence 101, to allow
% for the scanline correction. Also, gescan is sli-2 since sli is
% the index of the start line for the next orbit so, instead of
% sli-1 need an extra -1.

indices.current.oescan = indices.current.osscan + start_line_index + 101 - 1;

indices.current.gsscan = 1;
indices.current.gescan = start_line_index + 101 - 1;

if indices.current.oescan ~= orbit_length
    fprintf('Calculated end of orbit is %i, which does no agree with the mandated orbit length, %i. Forcing it to agree.\n', indices.current.oescan, orbit_length)
    indices.current.oescan = orbit_length;
    indices.current.gescan = indices.current.oescan - indices.current.osscan + 1;
    
    status = populate_problem_list( 114, temp_filename);
end

% Determine how many scan lines are needed to bring the length of this
% orbit to orbit_length, nominally 40,271 scan lines. This should
% result in about 100 lines of overlap with the next orbit--it varies
% from orbit to orbit because some orbits are 40,160 and some are
% 40,170. Plus we want 1 extra scan line at the end to allow for the
% bow-tie correction. If the number of scan lines remaining to be
% filled exceed the number of scan lines in this granule, default to
% reading the entire granule and set a flag to tell the function to get
% the remaining lines to complete the orbit from the next granule.

if (indices.current.oescan + 1 - indices.current.osscan) > num_scan_lines_in_granule
    
    % This case is arises if the additional 101 scanlines need to
    % complete the current orbit result in more scanlines being
    % required from the current granule than are available in it. In
    % this case, scanlines will need to be pirated from the next
    % granule, if it exists. This section gets the starting and ending
    % scanlines to be filled from the next granule as well as the
    % starting and ending scanlines to use from that granule.
    
    indices.case = 2;
    
    indices.current.oescan = indices.current.osscan + num_scan_lines_in_granule - 1;
    indices.current.gescan = num_scan_lines_in_granule;
    
    % The .pirate. group is for the scanlines to be read from the
    % next orbit to complete this orbit since adding 100 scanlines
    % resulting in going past the end of this granule (with the
    % start of an orbit in it).
    
    indices.pirate.osscan = indices.current.oescan + 1;
    indices.pirate.oescan = orbit_length;
    indices.pirate.gsscan = 1;
    indices.pirate.gescan = orbit_length - indices.pirate.osscan + 1;
end

indices.next.osscan = 1;
indices.next.oescan = num_scan_lines_in_granule - start_line_index + 1;
indices.next.gsscan = start_line_index;
indices.next.gescan = num_scan_lines_in_granule;
