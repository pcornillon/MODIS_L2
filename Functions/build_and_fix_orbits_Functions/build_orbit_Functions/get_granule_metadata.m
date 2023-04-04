function [status, granule_start_time_guess] = get_granule_metadata( metadata_file_list, update_oinfo, granule_start_time_guess)
% find_start_of_orbit - checks if metadata file exists and if it does whether or not it crosses latlim in descent - PCC
%
% Read the latitude of the nadir track for this granule and determine
% whether or not it crosses latlim, nominally 78 S. It also checks to make
% sure that the granule starts with the first detector in a group of 10
% detectors. It does this by reading the milliseconds of each scan line;
% it are the same for all scan lines in a detector group.
%
% INPUT
%   metadata_file_list - list of granule metadata found files for this time.
%   data_file_list - list of granule data files found for this time.
%   granule_start_time_guess - the matlab_time of the granule to start with.
%
% OUTPUT
%   status : 201 - No scanline start times for scanlines in this granule
%          : 202 - 1st detector in data granule not 1st detector in group of 10.
%   granule_start_time_guess - the matlab_time of the granule to start with. If scan
%    times are obtained for this granule, granule_start_time_guess will be set to the
%    first scan of the granule; otherwise the value passed in will be returned.
%

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length time_of_NASA_orbit_change
global formatOut
global latlim
global amazon_s3_run
global print_diagnostics save_just_the_facts debug

% Initialize some variables.

status = 0;
start_line_index = [];
nlat_t = [];

% Build temporaty filename.

temp_filename = [metadata_file_list(1).folder '/' metadata_file_list(1).name];

% Read time info from metadata granule.

Year = ncread( temp_filename, '/scan_line_attributes/year');
YrDay = ncread( temp_filename, '/scan_line_attributes/day');
mSec = ncread( temp_filename, '/scan_line_attributes/msec');

% Now determine the start times for each scanline and the number of
% scanlines in this granule. Be careful because the start times for scanlines
% occur are the same for all detectors in a group.

scan_line_times = datenum( Year, ones(size(Year)), YrDay) + mSec / 1000 / 86400;
num_scan_lines_in_granule = length(scan_line_times);

% Make sure that there is time data for this granule and that the 1st line
% in the granule is the 1st detector in a group of 10. If either of these
% fails, return, skipping the granule; this should NEVER happen. The
% importance of the 1st line in the granule being the first in the detector
% group is that we want to start our new orbit on the 5th scanline in the
% detector group to minimize the spreading effect from the bowtie issue.

if isempty(scan_line_times)
    fprintf('*** No scanline start times for scanlines in this granule. SHOULD NEVER GET HERE.\n', metadata_file_list(1).name)
    granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);
    
    status = populate_problem_list( 201, temp_filename);
    return
end

if abs(mSec(10)-mSec(1)) > 0.01
    fprintf('*** The 1st scan line for %s is not the 1st detector in a group of 10. Should not get here.\n', metadata_file_list(1).name)
    granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);
    
    status = populate_problem_list( 202, temp_filename);
    return
end

% Does the descending nadir track crosses latlim?

nlat_t = single(ncread( temp_filename, '/scan_line_attributes/clat'));

% Get the separation of along-track nadir pixels. Add one separation at the
% end of the track for this granule so that the size of the difference
% vector and along-track vector are the same; need this to find the minimum. 

diff_nlat = [diff(nlat_t); nlat_t(end)-nlat_t(end-1)];

% Find groups of scan line nadir values within 0.1 of latlim; will end up
% with up to 3 groups for 3 different crossings of 78 S.

mm = find( (abs(nlat_t-latlim)<0.1) & (diff_nlat<=0));

if ~isempty(mm)
    
    % Make sure that the nadir track actually crossed latlim. This addresses 
    % the problem of a nadir track that ends before or starts just after
    % crossing latlim. On the canonical orbit there are 3473 scan lines
    % separationg the descending node crossing of 73 S from the ascending
    % crossing so, in the following, testing on the first scan line and the
    % last scan line in the granule is safe--and easy.
    
    if sign(nlat_t(1)-latlim) ~= sign(nlat_t(end)-latlim)
        
        nn = mm(1) - 1 + find(min(abs(nlat_t(mm)-latlim)) == abs(nlat_t(mm)-latlim));
        start_line_index = floor(nn(1) / 10) * 10 + 5;
        
        % Next check to see if the 11th point from here is closer to
        % latlim, if it is use it but first make sure that there are at
        % least 11 more scan lines left in the orbit after start_line_index.
        
        if (start_line_index + 10) < num_scan_lines_in_granule
            if abs(nlat_t(start_line_index)-latlim) > abs(nlat_t(start_line_index+10)-latlim)
                start_line_index = start_line_index + 10;
            end
        end
    end
end

% Reset granule_start_time_guess to the start time of this granule and add
% 5 minutes.

granule_start_time_guess = scan_line_times(1) + 5 / (24 * 60);
