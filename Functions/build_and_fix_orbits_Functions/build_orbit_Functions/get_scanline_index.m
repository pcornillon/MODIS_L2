function nnToUse = get_scanline_index( target_lat_1, target_lat_2)
% get_scanline_index - gets the index for the scanline corresponding to the time passed in - PCC 
%  
% This function looks for the location of a target latitude in the
% canonical orbit. To find it requires two points following each other in
% time. Each one will have either 2 or 3 intersections with the canonical
% orbit, 3 because of the overlap at the end of the orbit. The  reason for
% passing a pair of points in is to make sure we are on either the
% ascending or descending part of the orbit; i.e., to pick out the correct
% one. Unfortunately, if it is in the overlapping portion of the function
% may find two points for descending paths, either of which is good so both
% will be returned. 
%
% INPUT
%   targe_lat_1 - the latitude of the 1st point (in time). 
%   targe_lat_2 - the latitude of the 2nd point (in time). This point
%    shouled be at least 5 scanlines after the 1st point if the 1st point
%    is the 5th or later point in a group of 10 scans corresponding to a 10
%    detector set.
%
% OUTPUT
%   nnToUse - the indices, either 1 (and 3 if 3 intersections) or 2, to use.
%

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg

canonical_nlat = nlat_avg;

nn1 = closest_point( canonical_nlat, target_lat_1, 0.02);
nn2 = closest_point( canonical_nlat, target_lat_2, 0.02);

if isempty(nn1) | isempty(nn2)
    fprintf('Latitudes don''t appear to be right for %s. First latitude is %f\n', oinfo(iOrbit).ginfo(iGranule).metadata_name, nlat_t(1));
    
    status = populate_problem_list( 101, oinfo(iOrbit).ginfo(iGranule).metadata_name);
    return
end

% % % % If the 2nd point comes farther along in the orbit than the 1st point then
% % % % the 1st (or 3rd if there is one) point(s) are the appropriate ones,
% % % % otherwist the 2nd point is.
% % % 
% % % if nn2(1) > nn1(1)
% % %     nnToUse = nn1(1);
% % %     if length(nn1) == 3
% % %         nnToUse(2) = nn1(3);
% % %     end
% % % else
% % %     nnToUse = nn1(2);
% % % end

% Use the starting point that results in the lowest sum of squares between
% the granule nadir track and the canonical orbit.

for i=1:length(nn1)
    npts = min( [nn1(i)+length(nlat_t)-1, 40271]) - nn1(i) + 1;
    
    ddsumsq(i) = sum((nlat_t(1:npts)' - nlat_avg(nn1(i):nn1(i)+npts-1)).^2);
end

[val, mm] = min(ddsumsq);

nnToUse = nn1(mm);
