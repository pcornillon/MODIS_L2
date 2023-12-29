function [status, granule_start_time_guess] = check_for_latlim_crossing( metadata_granule_folder_name, metadata_granule_file_name, granule_start_time_guess)
% % % function [status, granule_start_time_guess] = check_for_latlim_crossing( metadata_file_list, update_oinfo, granule_start_time_guess) 
% check_for_latlim_crossing - checks if metadata file exists and if it does whether or not it crosses latlim in descent - PCC


% Read the latitude of the nadir track for this granule and determine
% whether or not it crosses latlim, nominally 78 S. It also checks to make
% sure that the granule starts with the first detector in a group of 10
% detectors. It does this by reading the milliseconds of each scan line;
% it are the same for all scan lines in a detector group.
%
% The start of an orbit corresponds to the time of the scan line for which
% the nadir value is the CLOSEST to 78 S on the descending portion of the
% orbit. Note that another definition would have been the first scan line
% with a nadir value south of 78 S on a descending orbit. This is NOT how
% it is defined. 
%
% INPUT
% % % %   metadata_file_list - list of granule metadata found files for this time.
%   metadata_granule_folder_name - the metadata folder in which the file was found.
%   metadata_granule_file_name - the name of the metadata file found.
%   granule_start_time_guess - the matlab_time of the granule to start with.
%
% OUTPUT
%   status : 201 - No scanline start times for scanlines in this granule
%          : 202 - 1st detector in data granule not 1st detector in group of 10.
%   granule_start_time_guess - the matlab_time of the granule to start with. If scan
%    times are obtained for this granule, granule_start_time_guess will be set to the
%    first scan of the granule; otherwise the value passed in will be returned.
%

% globals for the run as a whole.

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory_local output_file_directory_remote
global print_diagnostics print_times debug
global npixels

% globals for build_orbit part.

global save_just_the_facts amazon_s3_run
global formatOut
global secs_per_day secs_per_orbit secs_per_scan_line secs_per_granule
global index_of_NASA_orbit_change possible_num_scan_lines_skip
global sltimes_avg nlat_orbit nlat_avg orbit_length
global latlim
global sst_range sst_range_grid_size

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t mside
global Matlab_start_time Matlab_end_time

% globals used in the other major functions of build_and_fix_orbits.

global med_op

% Initialize some variables.

status = 0;
start_line_index = [];
nlat_t = [];

% Build temporaty filename.

% % % temp_filename = [metadata_file_list(1).folder '/' metadata_file_list(1).name];
temp_filename = [metadata_granule_folder_name metadata_granule_file_name];

% Read the mirror side information

% % % mside = single(ncread( temp_filename, '/scan_line_attributes/mside'));

% Read time info from metadata granule.

Year = ncread( temp_filename, '/scan_line_attributes/year');
YrDay = ncread( temp_filename, '/scan_line_attributes/day');
mSec = ncread( temp_filename, '/scan_line_attributes/msec');

% Now determine the start times for each scanline and the number of
% scanlines in this granule. Be careful because the start times for scanlines
% occur are the same for all detectors in a group.

% % % scan_line_times = datenum( Year, ones(size(Year)), YrDay) + mSec / 1000 / 86400;

% Actual time is in groups of 10. scan_line_times, below, is the time of 
% scans had each scan line been done separately.

temp_times = datenum( Year, ones(size(Year)), YrDay) + mSec / 1000 / secs_per_day;

% Need to set scan_line_times to empty because the number of scans changes
% from between 2030 and 2040. If the previous granule had 2040 scan lines
% and this one had 2030, the last 10 values will be bogus, belonging to the
% previous granule. Also the resulting lenght of scan_line_times will be
% wrong.  Note scan_line_times SHOULD NOT BE CLEARED in that this will
% clear it as a global variable and it will not be passed to other
% functions.

scan_line_times = [];

for iScan=1:10:length(temp_times)-9
    for jSubscan=0:9
        scan_line_times(iScan+jSubscan) = temp_times(iScan) + jSubscan * secs_per_scan_line / secs_per_day;
    end
end

num_scan_lines_in_granule = length(scan_line_times);

% Make sure that there is time data for this granule and that the 1st line
% in the granule is the 1st detector in a group of 10. If either of these
% fails, return, skipping the granule; this should NEVER happen. The
% importance of the 1st line in the granule being the first in the detector
% group is that we want to start our new orbit on the 5th scanline in the
% detector group to minimize the spreading effect from the bowtie issue.

if isempty(scan_line_times)
    % % % fprintf('*** No scanline start times for scanlines in this granule. SHOULD NEVER GET HERE.\n', metadata_file_list(1).name)
    fprintf('*** No scanline start times for scanlines in this granule. SHOULD NEVER GET HERE.\n', metadata_granule_file_name)
    granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);

    status = populate_problem_list( 201, temp_filename, granule_start_time_guess);
    return
end

if abs(mSec(10)-mSec(1)) > 0.01
    fprintf('*** The 1st scan line for %s is not the 1st detector in a group of 10. Should not get here.\n', metadata_file_list(1).name)
    granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);

    status = populate_problem_list( 202, temp_filename, granule_start_time_guess);
    return
end

% Make sure that the scan_line_times are good.

dt = (scan_line_times(end-5) - scan_line_times(5)) * secs_per_day;
if abs(dt - (secs_per_granule * length(scan_line_times) / 2030 - 10 * secs_per_scan_line)) > 0.01
    if print_diagnostics
        fprintf('...Mirror rotation rate seems to have changed for granule starting at %s.\n   Continuing but be careful.\n', datestr(granule_start_time_guess));
    end

    status = populate_problem_list( 141, ['Mirror rotation rate seems to have changed for granule starting at ' datestr(granule_start_time_guess) '. Continuing but be careful.'], granule_start_time_guess);
end

% Determine the time for this granule. Note that it is scaled at the end to
% 2030 scan lines since the first guess from build_and_fix_orbits is for
% 2030 scan lines.

secs_per_granule = ((scan_line_times(end) - scan_line_times(1)) * secs_per_day + secs_per_scan_line) * 2030 / length(scan_line_times);

% Does the descending nadir track crosses latlim?

nlat_t = single(ncread( temp_filename, '/scan_line_attributes/clat'));

% Get the separation of along-track nadir pixels. Add one separation at the
% end of the track for this granule so that the size of the difference
% vector and along-track vector are the same; need this to find the minimum.

diff_nlat = [diff(nlat_t); nlat_t(end)-nlat_t(end-1)];

% Find groups of scan line nadir values within 0.1 of latlim; could end up
% with up 2 different crossings of 78 S, but this is very rare if it ever
% happens, but, just in case,...

% % % mm = find( (abs(nlat_t-latlim)<0.1) & (diff_nlat<=0));
aa = find(abs(nlat_t-latlim)<0.1);

% If no crossing found return.

if ~isempty(aa)

    % If more than 10 scan lines separate groups of scan lines found near 78 S
    % break them up and analyze separately for direction.

    diffaa = diff(aa);
    bb = find(diffaa >10);

    mm = [];
    if isempty(bb)
        % Only one group

        if nlat_t(aa(end)) < nlat_t(aa(1))
            mm = aa;
        end
    else
        % Two groups
        if nlat_t(aa(bb)) < nlat_t(aa(1))
            mm = aa(1:bb);
        end

        if nlat_t(aa(end)) < nlat_t(aa(bb+1))
            mm = aa(bb+1:end);
        end
    end

    if ~isempty(mm)

        % Make sure that the nadir track actually crossed latlim. This addresses
        % the problem of a nadir track that ends before or starts just after
        % crossing latlim. On the canonical orbit there are 3473 scan lines
        % separationg the descending node crossing of 73 S from the ascending
        % crossing so, in the following, testing on the first scan line and the
        % last scan line in the granule is safe--and easy.

        if sign(nlat_t(mm(1))-latlim) ~= sign(nlat_t(mm(end))-latlim)

            nn = mm(1) - 1 + find(min(abs(nlat_t(mm)-latlim)) == abs(nlat_t(mm)-latlim));

            % Find the descending scan line for which the nadir value is
            % CLOSEST to 78 S and is the 5th scan line in a 10 scan line
            % group. But,first make sure that iStart_of_group is at the
            % beginning of a 10 scan line group. Need to check that test
            % values of nlat_t do not extend past either end of nlat_t.
            
            iStart_of_group = floor(nn(1) / 10) * 10 + 1;
            
            bad_grouping = 0;
            if iStart_of_group <= 1
                if nlat_t(iStart_of_group+10-1) == nlat_t(iStart_of_group+10)
                    bad_grouping = 1;
                    
                end
            elseif iStart_of_group+10 >= length(nlat_t)
                if nlat_t(iStart_of_group-1) == nlat_t(iStart_of_group)
                    bad_grouping = 1;
                end
            elseif (nlat_t(iStart_of_group-1) == nlat_t(iStart_of_group)) | (nlat_t(iStart_of_group+10-1) == nlat_t(iStart_of_group+10))
                bad_grouping = 1;
            end
            
            if bad_grouping == 1
                fprintf('*** Can''t find the start of a group of 10 scan lines. Thought that it would be %i. SHOULD NEVER GET HERE.\n', iStart_of_group)
                granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);
                
                status = populate_problem_list( 153, ['Can''t find the start of a group of 10 scan lines. Thought that it would be ' num2str(iStart_of_group) '. SHOULD NEVER GET HERE.'], granule_start_time_guess);
            end
            
            % Now find the group of 10 with the point in the middle closest
            % to 78 S looking at the group of 10 before the one in which
            % the crossing was found, the group of 10 in which the crossing
            % was found and the next group of 10.

            iPossible = [iStart_of_group-6 iStart_of_group+5 iStart_of_group+15];
            start_line_index = iPossible(2);
            
            central_group = abs(nlat_t(iPossible(2)) - latlim);
            
            if iPossible(1) > 0
                if abs(nlat_t(iPossible(1)) - latlim) < central_group
                    start_line_index = iPossible(1);
                end
            end
            
            if iPossible(3) < length(nlat_t)
                if abs(nlat_t(iPossible(3)) - latlim) < central_group
                    start_line_index = iPossible(3);
                end
            end            

% % %             option_1 = floor(nn(1) / 10) * 10 + 1;
% % %             option_2 = floor(nn(1) / 10) * 10 + 5;
% % % 
% % %             %% LOOKS LIKE THE NEXT LINE IS WRONG
% % % %             if abs(option_1 - latlim) <= abs(option_2 - latlim)
% % %             
% % %             %% IT SHOULD BE
% % %             if abs(nlat_t(option_1) - latlim) <= abs(nlat_t(option_2) - latlim)
% % %                 start_line_index = option_1;
% % %             else
% % %                 start_line_index = option_2;
% % %             end
% % % 
% % %             % Next check to see if the 11th point from here is closer to
% % %             % latlim, if it is use it but first make sure that there are at
% % %             % least 11 more scan lines left in the orbit after start_line_index.
% % % 
% % %             if (start_line_index + 10) < num_scan_lines_in_granule
% % %                 if abs(nlat_t(start_line_index)-latlim) > abs(nlat_t(start_line_index+10)-latlim)
% % %                     start_line_index = start_line_index + 10;
% % %                 end
% % %             end
        end
    end
end

% Reset granule_start_time_guess to the start time of this granule and add
% 5 minutes.

granule_start_time_guess = scan_line_times(1) + 5 / (24 * 60);
