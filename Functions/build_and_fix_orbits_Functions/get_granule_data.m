function [fi_granule, problem_list, latitude, longitude, SST_In, qual_sst, flags_sst, sstref] ...
    = get_granule_data( fi_metadata, granules_directory, problem_list, orbit_data_range, ...
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
%   fi_granule - granule filename from which the data were read. 
%   problem_list - structure with data on problem granules.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%

%   Detailed explanation goes here

osscan = orbit_data_range(1);
oescan = orbit_data_range(2);

gsscan = granule_data_range(1);
gescan = granule_data_range(2);

[fi_granule, problem_list] = build_granule_filename( fi_metadata, granules_directory, problem_list);

% Read the fields

latitude(:,osscan:oesan) = single(ncread( fi_granule , '/navigation_data/latitude', [1 gsscan], [npixels gescan]));
longitude(:,osscan:oesan) = single(ncread( fi_granule , '/navigation_data/longitude', [1 gsscan], [npixels gescan]));
SST_In(:,osscan:oesan) = single(ncread( fi_granule , '/geophysical_data/sst', [1 gsscan], [npixels gescan]));

qual_sst(:,osscan:oesan) = int8(ncread( fi_granule , '/geophysical_data/qual_sst', [1 gsscan], [npixels gescan]));
flags_sst(:,osscan:oesan) = int16(ncread(fi_metadata, '/geophysical_data/flags_sst', [1 gsscan], [npixels gescan]));

sstref(:,osscan:oesan) = single(ncread( fi_granule , '/geophysical_data/sstref', [1 gsscan], [npixels gescan]));

end

