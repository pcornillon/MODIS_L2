function [status, fi_granule, problem_list, global_attrib, latitude, longitude, SST_In, qual_sst, flags_sst, sstref] ...
    = get_granule_data( fi_metadata, granules_directory, problem_list, check_attributes, orbit_data_range, ...
    granule_data_range, latitude, longitude, SST_In, qual_sst, flags_sst, sstref)
% get_granule_data - build the granule filename and read the granule data - PCC
%
% This function calls build_granule_filename, which builds the filename for
% either Amazon s3 or OBPG granules and then reads the fields reqiured for
% the remainder of the processing.
%
% INPUT
%   fi_metadata - the filename for the metadata file for this granule. The
%    metadata information was copied from the OBPG granule because it does
%    not exist in the PO.DAAC granule.
%   granules_directory - the name of the directory with the granules.
%   problem_list - structure with list of filenames (filename) for skipped 
%    file and the reason for it being skipped (problem_code):
%    problem_code: 1 - couldn't find the file in s3.
%                : 2 - couldn't find the metadata file copied from OBPG data.
%   check_attributes - 1 to read the global attributes for the data granule
%    and check that they exist and/or are reasonable.
%   orbit_data_range - a two element vector with the start and end locations
%    in the orbit arrays for the data from this granule.
%   granule_data_range - the same for the start and end locations of the
%    arrays in the granules.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%
% OUTPUT
%   status  : 0 - OK
%           : 1 - couldn't find the data granule.
%           : 2 - didn't find number_of_lines global attribute.
%           : 3 - number of pixels global attribute not equal to 1354.
%           : 4 - number of scan lines global attribute not between 2020 and 2050.
%           : 5 - couldn't find the metadata file copied from OBPG data.
%   fi_granule - granule filename from which the data were read. 
%   problem_list - structure with data on problem granules.
%   global_attrib - the global attributes read from the data granule.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%

osscan = orbit_data_range(1);
oescan = orbit_data_range(2);

gsscan = granule_data_range(1);
gescan = granule_data_range(2);

scan_lines_to_read = gescan - gsscan + 1;

[status, fi_granule, problem_list, global_attrib] ...
    = build_granule_filename( fi_metadata, granules_directory, problem_list, check_attributes);

% Read the fields

if ~skip_this_granule
    latitude(:,osscan:oesan) = single(ncread( fi_granule , '/navigation_data/latitude', [1 gsscan], [npixels scan_lines_to_read]));
    longitude(:,osscan:oesan) = single(ncread( fi_granule , '/navigation_data/longitude', [1 gsscan], [npixels scan_lines_to_read]));
    SST_In(:,osscan:oesan) = single(ncread( fi_granule , '/geophysical_data/sst', [1 gsscan], [npixels scan_lines_to_read]));
    
    qual_sst(:,osscan:oesan) = int8(ncread( fi_granule , '/geophysical_data/qual_sst', [1 gsscan], [npixels scan_lines_to_read]));
    flags_sst(:,osscan:oesan) = int16(ncread(fi_metadata, '/geophysical_data/flags_sst', [1 gsscan], [npixels scan_lines_to_read]));
    
    sstref(:,osscan:oesan) = single(ncread( fi_granule , '/geophysical_data/sstref', [1 gsscan], [npixels scan_lines_to_read]));
end

end

