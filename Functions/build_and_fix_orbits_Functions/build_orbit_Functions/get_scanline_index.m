function nnToUse = get_scanline_index
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
%
% OUTPUT
%   nnToUse - the indices, either 1 (and 3 if 3 intersections) or 2, to use.
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

nnToUse = [];

canonical_nlat = nlat_avg;
target_lat_1 = nlat_t(5);

if isnan(target_lat_1)
    fprintf('*** Latitude for nlat_t(5) is nan for %s. This should not happen. Skipping this granule.\n', oinfo(iOrbit).ginfo(iGranule).metadata_name);
    
    status = populate_problem_list( 801, ['Latitude for nlat_t(5) is nan for ' oinfo(iOrbit).ginfo(iGranule).metadata_name '. This should not happen. Skipping this granule.']);
    return
end
    
nn = closest_point( canonical_nlat, target_lat_1, 0.02);

if isempty(nn)
    fprintf('*** Latitudes don''t appear to be right for %s. First latitude is %f\n', oinfo(iOrbit).ginfo(iGranule).metadata_name, nlat_t(1));
    
    status = populate_problem_list( 802, ['Latitudes don''t appear to be right for ' oinfo(iOrbit).ginfo(iGranule).metadata_name '. First latitude is ' num2str(nlat_t(1))])
    return
end

% Use the starting point that results in the lowest sum of squares between
% the granule nadir track and the canonical orbit. Only consider the first
% two crossings, the 3rd one will be too close to the end and should have
% been found in an intersection of the nadir track with 73 S, although this
% could be a problem in some rare cases. Also, the 3rd one should also be a
% good fit but based onn a lot less scan lines since these are exactly one
% orbit from those in the beginning of the orbit. In very rare cases, there
% is just one intersection. This will happen if nlat_t(5) > max(nlat_avg)
% or, I guess, less than min(nlat_avg). I found one case for this for
% granule: AQUA_MODIS_20020814T161005_L2_SST_OBPG_extras.nc4

if length(nn) == 1
    fprintf('Only one intersection of nlat_t(5) found with nlat_avg for %s. Continuing.\n', oinfo(iOrbit).ginfo(iGranule).metadata_name )

    status = populate_problem_list( 803, ['Only one intersection of nlat_t(5) found with nlat_avg for ' oinfo(iOrbit).ginfo(iGranule).metadata_name]);
end

for i=1:min(length(nn), 2)
    npts = min( [nn(i)+length(nlat_t)-1, 40271]) - nn(i) + 1;
    
    ddsumsq(i) = sum((nlat_t(1:npts)' - nlat_avg(nn(i):nn(i)+npts-1)).^2);
end

[val, aa] = min(ddsumsq);

% OK, now find the scan line near mm, that is a multiple of 5 scan lines in
% the granule and then determine, which of that scan line - 5, that scan
% line and that scan line + 5 is the best fit.

bb = (nn(aa)+7) - mod( (nn(aa)+7), 10) - 3 + 10 * [-1 0 1];

j = 0;
for i=1:3
    if bb(i) > 0
        j = j + 1;
        
        npts = min( [bb(i)+length(nlat_t)-1, 40271]) - bb(i) + 1;
        
        ddsumsq(j) = sum((nlat_t(1:npts)' - nlat_avg(bb(i):bb(i)+npts-1)).^2);
    end
end

[val, cc] = min(ddsumsq);

nnToUse = bb(cc);

if nnToUse < 10
    fprintf('...Be careful get_scanline_index found a starting index of %i. Is setting nnToUse to 1.\n', nnToUse)
     
    status = populate_problem_list( 804, ['Be careful, for granule ' oinfo(iOrbit).ginfo(iGranule).metadata_name ' get_scanline_index found a starting index of num2str(nnToUse). Is setting nnToUse to 1.']);   
    
    nnToUse = 1;
end
