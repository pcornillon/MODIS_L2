function [status, indices] = get_osscan_etc_with_sli(indices)
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
%
% OUTPUT
%   status - if 65 do not populate orbit for this granule.
%   indices - a structure with the discovered indices.
%

% globals for the run as a whole.

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory_local output_file_directory_remote
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

status = 0;

% Add 101 to osscan + sli to get 100 scanline overlap of this orbit
% with the next one plus an additional line, hence 101, to allow
% for the scanline correction. Also, gescan is sli-2 since sli is
% the index of the start line for the next orbit so, instead of
% sli-1 need an extra -1.

% And for the rest of oescan, gsscan and gescan.

indices.current.oescan = indices.current.osscan + start_line_index - 1 + 101 - 1;

indices.current.gsscan = 1;
indices.current.gescan = start_line_index + 101 - 1;

% Is the length of the orbit correct? If not force it to be so.

if indices.current.oescan ~= orbit_length

    kk = strfind(oinfo(iOrbit).name, 'AQUA_MODIS_');
    if (indices.current.oescan ~= orbit_length - 10) & (indices.current.oescan ~= orbit_length - 11) & (indices.current.oescan ~= orbit_length - 1)

        if print_diagnostics
            fprintf('...Calculated length of %s is %i scans, forcing to %i scans.\n', oinfo(iOrbit).name(kk+11:end-11), indices.current.oescan, orbit_length);
        end
    end

    indices.current.oescan = orbit_length;
    indices.current.gescan = indices.current.oescan - indices.current.osscan + 1;

    status = populate_problem_list( 416, ['Calculated length of ' oinfo(iOrbit).name ' is ' num2str(indices.current.oescan) ' scans. Forcing to ' num2str(orbit_length) '.']);

    if iOrbit == 1
        fprintf('In general you can ignore this ''error'' since this is the first orbit but be careful.\n')
    end
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
    
    % This case arises if the additional 101 scan lines need to complete
    % the current orbit result in more scan lines being required from
    % the current granule than are available in it. In this case, scan
    % lines will need to be pirated from the next granule, if it
    % exists. This section gets the starting and ending scanlines to be
    % filled from the next granule as well as the starting and ending
    % scanlines to use from that granule.
    
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
