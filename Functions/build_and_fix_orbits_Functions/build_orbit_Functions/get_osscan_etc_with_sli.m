function [status, indices] = get_osscan_etc_with_sli( continue_orbit)
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
%   continue_orbit - 1 to get the indices to complete the current orbit and
%    begin building the next one, 0 to get the indices to begin building
%    the next orbit only.
% OUTPUT
%   status - if 65 do not populate orbit for this granule.
%   indices - a structure with the discovered indices.
%

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global Matlab_start_time Matlab_end_time
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global print_diagnostics

% Get the possible location of this granule in the orbit. If the starts in
% the 101 scanline overlap region, two possibilities will be returned. We
% will choose the earlier, smaller scanline, of the two; choosing the later
% of the two would mean that we would only use the last few scanlines in
% the orbit, which should have already been done if nadir track of the
% previous granule crossed 78 S. 

target_lat_1 = nlat_t(5);
target_lat_2 = nlat_t(11);

nnToUse = get_scanline_index( target_lat_1, target_lat_2, input_filename);

indices.current.osscan = nnToUse(1);

% This case is the simplest, the number of scanlines required to complete
% this orbit--go to the start of the next orbit + 101 scanlines for overlap
% with next orbit--exist in this granule. Generate the relevant information
% for the location of scanlines in the current and next orbits and where to
% extract them from the current granule.

indices.case = 1;

if continue_orbit
    
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
    
    indices.current.oescan = indices.current.osscan + (start_line_index - 2) + 101;
    
    indices.current.gsscan = 1;
    indices.current.gescan = start_line_index - 1;
    
    if indices.current.oescan ~= orbit_length
        fprintf('Calculated end of orbit is %i, which does no agree with the mandated orbit length, %i. Forcing it to agree.\n', indices.current.oescan, orbit_length)
        indices.current.oescan = orbit_length;
        indices.current.gescan = indices.current.oescan - indices.current.osscan + 1;
        
        status = populate_problem_list( 114, oinfo(iOrbit).ginfo(iGranule));
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
        
        indices.pirate.osscan = indices.oescan + 1;
        indices.pirate.oescan = orbit_length;
        indices.pirate.gsscan = 1;
        indices.pirate.gescan = orbit_length - indices.pirate.osscan + 1;
    end
end

indices.next.osscan = 1;
indices.next.oescan = num_scan_lines_in_granule - start_line_index + 1;
indices.next.gsscan = start_line_index;
indices.next.gescan = num_scan_lines_in_granule;

% Write ossan, oescan,... to oinfo

oinfo(iOrbit).ginfo(iGranule).osscan = indices.current.osscan;
oinfo(iOrbit).ginfo(iGranule).oescan = indices.current.oescan;

oinfo(iOrbit).ginfo(iGranule).gsscan = indices.current.gsscan;
oinfo(iOrbit).ginfo(iGranule).gescan = indices.current.gescan;

if ~isempty(indices.pirate.osscan)
    oinfo(iOrbit).ginfo(iGranule).pirate_osscan = indices.current.osscan;
    oinfo(iOrbit).ginfo(iGranule).pirate_oescan = indices.current.oescan;
    
    oinfo(iOrbit).ginfo(iGranule).pirate_gsscan = indices.current.gsscan;
    oinfo(iOrbit).ginfo(iGranule).pirate_gescan = indices.current.gescan;
end

oinfo(iOrbit+1).ginfo(1).osscan = indices.next.osscan;
oinfo(iOrbit+1).ginfo(1).oescan = indices.next.oescan;

oinfo(iOrbit+1).ginfo(1).gsscan = indices.next.gsscan;
oinfo(iOrbit+1).ginfo(1).gescan = indices.next.gescan;

% Save the start & end time for the next orbit as well as metadata
% information for the first granule of the next orbit.

oinfo(iOrbit+1).orbit_start_time = scan_line_times(start_line_index);
oinfo(iOrbit+1).orbit_end_time = oinfo(iOrbit+1).orbit_start_time + secs_per_orbit;

oinfo(iOrbit+1).ginfo(1).metadata_global_attrib = oinfo(iOrbit).ginfo(iGranule).metadata_global_attrib;
oinfo(iOrbit+1).ginfo(1).metadata_name = oinfo(iOrbit).ginfo(iGranule).metadata_name;

oinfo(iOrbit+1).ginfo(1).start_time = oinfo(iOrbit).ginfo(iGranule).start_time;
oinfo(iOrbit+1).ginfo(1).end_time = oinfo(iOrbit).ginfo(iGranule).end_time;


