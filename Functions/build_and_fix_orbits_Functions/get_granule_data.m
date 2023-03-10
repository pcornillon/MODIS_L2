function [status, problem_list, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = get_granule_data( granules_directory, problem_list, check_attributes, scan_line_times, ...
    latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start)
% get_granule_data - build the granule filename and read the granule data - PCC
%
% This function calls build_granule_filename, which builds the filename for
% either Amazon s3 or OBPG granules and then reads the fields reqiured for
% the remainder of the processing.
%
% INPUT
%   granules_directory - the name of the directory with the granules.
%   problem_list - structure with list of filenames (filename) for skipped 
%    file and the reason for it being skipped (problem_code):
%    problem_code: 1 - couldn't find the file in s3.
%                : 2 - couldn't find the metadata file copied from OBPG data.
%   check_attributes - 1 to read the global attributes for the data granule
%    and check that they exist and/or are reasonable.
%   scan_line_times - time for the start of each scan line.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   scan_seconds_from_start - seconds for from the start of the orbit.
%
% OUTPUT
%   status  : 0 - OK
%           : 1 - couldn't find the data granule.
%           : 2 - didn't find number_of_lines global attribute.
%           : 3 - number of pixels global attribute not equal to 1354.
%           : 4 - number of scan lines global attribute not between 2020 and 2050.
%           : 5 - couldn't find the metadata file copied from OBPG data.
%   problem_list - structure with data on problem granules.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   scan_seconds_from_start - seconds for from the start of the orbit.
%

global iOrbit orbit_info iGranule
global npixels
global latlim secs_per_day secs_per_orbit secs_per_scan_line orbit_length

osscan = orbit_info(iOrbit).granule_info(iGranule).osscan;
oescan = orbit_info(iOrbit).granule_info(iGranule).oescan;

gsscan = orbit_info(iOrbit).granule_info(iGranule).gsscan;
gescan = orbit_info(iOrbit).granule_info(iGranule).gescan;

scan_lines_to_read = gescan - gsscan + 1;

[status, problem_list] = build_granule_filename( granules_directory, problem_list, check_attributes);

% Read the fields

fi_granule = orbit_info(iOrbit).granule_info(iGranule).data_granule_name;
fi_metadata = orbit_info(iOrbit).granule_info(iGranule).metadata_name;

if status == 0
    latitude(:,osscan:oescan) = single(ncread( fi_granule , '/navigation_data/latitude', [1 gsscan], [npixels scan_lines_to_read]));
    longitude(:,osscan:oescan) = single(ncread( fi_granule , '/navigation_data/longitude', [1 gsscan], [npixels scan_lines_to_read]));
    SST_In(:,osscan:oescan) = single(ncread( fi_granule , '/geophysical_data/sst', [1 gsscan], [npixels scan_lines_to_read]));
    
    qual_sst(:,osscan:oescan) = int8(ncread( fi_granule , '/geophysical_data/qual_sst', [1 gsscan], [npixels scan_lines_to_read]));
    flags_sst(:,osscan:oescan) = int16(ncread(fi_granule, '/geophysical_data/flags_sst', [1 gsscan], [npixels scan_lines_to_read]));
    
    sstref(:,osscan:oescan) = single(ncread( fi_granule , '/geophysical_data/sstref', [1 gsscan], [npixels scan_lines_to_read]));
    
    scan_seconds_from_start(osscan:oescan) = single(scan_line_times(gsscan:gescan) - orbit_info(iOrbit).orbit_start_time) * secs_per_day;
else
    fprintf('****** Data for %s not read because of error %i.\n', status)
end

end

