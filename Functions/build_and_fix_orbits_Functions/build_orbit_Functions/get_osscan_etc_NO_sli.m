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
% % % %   orbit_status - 'new_orbit' to start an orbit from scratch, 'continue_orbit',
% % % %    to get the indices to complete the current orbit and beginninggranule_start_time_guess
% % % %    building the next one.
% OUTPUT
%   status - if 65 do not populate orbit for this granule.
%   indices - a structure with the discovered indices.
%

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global Matlab_start_time Matlab_end_time
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global latlim
global print_diagnostics

% Get the possible location of this granule in the orbit. If the starts in
% the 101 scanline overlap region, two possibilities will be returned. We
% will choose the earlier, smaller scanline, of the two; choosing the later
% of the two would mean that we would only use the last few scanlines in
% the orbit, which should have already been done if nadir track of the
% previous granule crossed 78 S. 

target_lat_1 = nlat_t(5);
target_lat_2 = nlat_t(11);

nnToUse = get_scanline_index( target_lat_1, target_lat_2, oinfo(iOrbit).ginfo(iGranule).metadata_name);

indices.current.osscan = nnToUse(1);
indices.current.oescan = indices.current.osscan + num_scan_lines_in_granule - 1;

indices.current.gsscan = 1;
indices.current.gescan = num_scan_lines_in_granule - 1;

% Check the above if this is NOT the first granule found in a new orbit.

% Get lines to skip for missing granules. Will, hopefully, be 0 if no
% granules skipped. If this is the first granule in a new orbit and the
% previous granule did not cross 78 S, the number of lines to skip will be
% nnToUse(1). 

if iGranule > 1
    lines_to_skip = floor( abs((indices.current.start_time - oinfo(iOrbit).ginfo(end-1).end_time) + 0.05) / secs_per_scan_line);
        
    % Check that the number of lines to skip is a multiple of 10. If not, force it to be.
    
    if isempty(lines_to_skip == [1:39]'*[1020:10:1050])
        fprint('Wanted to skip %i lines but the only permissible values are multiles of 1020, 1030, 1040 or 1050. Setting lines to skip to 0.\n', lines_to_skip)
        lines_to_skip = 0;
        
        status = populate_problem_list( 121, []);
    end
    
    osscan_test = oinfo(iOrbit).ginfo(iGranule-1).oescan + lines_to_skip;

    if indices.current.osscan ~= osscan_test
        fprintf('Problem with start of scanline granules in this orbit for granule %s\n    %i calcuated based on canonical orbit, %i calcuated based on previous granule. \n', ...
            indices.current.name, indices.current.osscan, osscan_test)
        
        status = populate_problem_list( 231, oinfo(iOrbit).ginfo(iGranule).metadata_name);
        return
    end
end

% Write ossan, oescan,... to oinfo

oinfo(iOrbit).ginfo(iGranule).osscan = indices.current.osscan;
oinfo(iOrbit).ginfo(iGranule).oescan = indices.current.oescan;

oinfo(iOrbit).ginfo(iGranule).gsscan = indices.current.gsscan;
oinfo(iOrbit).ginfo(iGranule).gescan = indices.current.gescan;


