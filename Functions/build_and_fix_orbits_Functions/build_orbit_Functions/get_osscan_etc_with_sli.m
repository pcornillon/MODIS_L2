function [indices] = get_osscan_etc_with_sli(indices)
% % % % % function [indices] = get_osscan_etc_with_sli( skip_to_start_of_orbit, indices)
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
% % % % % %   skip_to_start_of_orbit: 0 to force number of scans in the orbit to
% % % % % %    40,271
%   indicies: first crack at indices to use in building orbits.
%
% OUTPUT
%   indices - a structure with the discovered indices.
%
%  CHANGE LOG
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/13/2024 - Initial version - PCC
%   1.0.1 - 5/13/2024 - Added versioning. Modified number of characters to
%           skip backward when printing the name to accommodate the
%           addition of -URI_24-1 to the filename.
%   2.0.0 - 5/21/2024 - Updated error handling - PCC

global version_struct
version_struct.get_osscan_etc_with_sli = '2.0.0';


% globals for the run as a whole.

global print_diagnostics

% globals for build_orbit part.

global orbit_length

global oinfo iOrbit
global start_line_index num_scan_lines_in_granule

% globals used in the other major functions of build_and_fix_orbits.

global iProblem problem_list 

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

% % % % % if (indices.current.oescan ~= orbit_length) & (skip_to_start_of_orbit == 0)
if (indices.current.oescan ~= orbit_length)

    if (indices.current.oescan ~= orbit_length - 10) & (indices.current.oescan ~= orbit_length - 11) & (indices.current.oescan ~= orbit_length - 1)
        if iOrbit > 1
            [~, orbitName, ~] = fileparts(oinfo(iOrbit).name);
            dont_use_status = populate_problem_list( 345, ['Calculated length of ' orbitName ' is ' num2str(indices.current.oescan) ' scans. Forcing to ' num2str(orbit_length) '.']); % old status 416
        end
    end

    indices.current.oescan = orbit_length;
    indices.current.gescan = indices.current.oescan - indices.current.osscan + 1;
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

if ((indices.current.oescan + 1 - indices.current.osscan) > num_scan_lines_in_granule)
    
    % This case arises if the additional 101 scan lines needed to complete
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
else

end

indices.next.osscan = 1;
indices.next.oescan = num_scan_lines_in_granule - start_line_index + 1;
indices.next.gsscan = start_line_index;
indices.next.gescan = num_scan_lines_in_granule;
