function [status] = check_global_attrib
% check_global_attrib - read and check global attributes from the metadata file - PCC 
%   
% This script reads the global attributes from the granule file and make
% sure that they exist and/or are within limits. Really just a sanity
% check.
%
% INPUT
%
% OUTPUT
%   status : 0 - OK
%          : 2 - didn't find number_of_lines global attribute.
%          : 3 - number of pixels global attribute not equal to 1354.
%          : 4 - number of scan lines global attribute not between 2020 and 2050.
%          : 5 - couldn't find the metadata file copied from OBPG data.
%   global_attrib - the global attributes read from the data granul.
%

%   problem_list - structure with list of filenames (filename) for skipped 
%    file and the reason for it being skipped (problem_code):
%    problem_code: 1 - couldn't find the file in s3.
%                : 2 - didn't find number_of_lines global attribute.
%                : 3 - number of pixels global attribute not equal to 1354.
%                : 4 - number of scan lines global attribute not between 2020 and 2050.
%                : 5 - couldn't find the metadata file copied from OBPG data.

global iOrbit orbit_info iGranule problem_list
global scan_line_times start_line_index num_scan_lines_in_granule sltimes_avg nlat_avg
global npixels

% Initialize some parameters.

status = 0;
nscans_range = [2019 2051];

% Read the global attributes from the granule file.

orbit_info(iOrbit).data_global_attrib = ncinfo(orbit_info(iOrbit).granule_info(iGranule).data_granule_name);

% Perform tests on some of the global variables. 

if isempty(strcmp(orbit_info(iOrbit).data_global_attrib.Dimensions(1).Name, 'number_of_lines'))
    fprintf('Didn''t find an attribute for ''%s'' in %s. Skipping this granule. Error code 2.\n', ...
        orbit_info(iOrbit).data_global_attrib.Dimensions(1).Name, orbit_info(iOrbit).granule_info(iGranule).data_granule_name)
    
    status = 2;

    problem_list.iProblem = problem_list.iProblem + 1;
    problem_list.filename = orbit_info(iOrbit).granule_info(iGranule).data_granule_name;
    problem_list.code = status;

    return
end

% Check the number of pixels/scan line and the number of scan lines.

nscans = orbit_info(iOrbit).data_global_attrib.Dimensions(1).Length;
npixels_attr = orbit_info(iOrbit).data_global_attrib.Dimensions(2).Length;

if npixels_attr ~= npixels
    fprintf('There are %i pixels/scan line in granule: %s but there should be 1354. Skipping this granule. Error code 3.\n', ...
        npixels, orbit_info(iOrbit).granule_info(iGranule).data_granule_name)
    
    status = 3;
    
    problem_list.iProblem = problem_list.iProblem + 1;
    problem_list.filename = orbit_info(iOrbit).granule_info(iGranule).data_granule_name;
    problem_list.code = status;

    return
end


if (nscans < nscans_range(1)) | (nscans > nscans_range(2))
    fprintf('There are %i scan lines in this granule: %s but the number of scan lines should be between %i and %i. Skipping this granule. Error code 4.\n', ...
        nscans, orbit_info(iOrbit).granule_info(iGranule).data_granule_name, nscans_range)
   
    status = 4;
    
    problem_list.iProblem = problem_list.iProblem + 1;
    problem_list.filename = orbit_info(iOrbit).granule_info(iGranule).data_granule_name;
    problem_list.code = status;

    return
end


% Get the start and end times for this granule. Make sure
% that time_coverage_start exists in the attributes.

not_found = 1;
for iAtt=1:length(orbit_info(iOrbit).data_global_attrib.Attributes)
    if strfind(orbit_info(iOrbit).data_global_attrib.Attributes(iAtt).Name, 'time_coverage_start')
        xx = orbit_info(iOrbit).data_global_attrib.Attributes(iAtt).Value;
        not_found = 0;
        datetime_start = datenum( str2num(xx(1:4)), str2num(xx(6:7)), ...
            str2num(xx(9:10)), str2num(xx(12:13)), str2num(xx(15:16)), str2num(xx(18:23)));
    end
    
    if strfind(orbit_info(iOrbit).data_global_attrib.Attributes(iAtt).Name, 'time_coverage_end')
        xx = orbit_info(iOrbit).data_global_attrib.Attributes(iAtt).Value;
        datetime_end = datenum( str2num(xx(1:4)), str2num(xx(6:7)), ...
            str2num(xx(9:10)), str2num(xx(12:13)), str2num(xx(15:16)), str2num(xx(18:23)));
    end
end

if not_found
    fprintf('Whoa, didn''t find ''time_coverage_start'' in the attributes for: %s. This should never happen. Skipping this granule. Error code 5.\n', ...
        orbit_info(iOrbit).granule_info(iGranule).data_granule_name)
    
    status = 5;
    
    problem_list.iProblem = problem_list.iProblem + 1;
    problem_list.filename = orbit_info(iOrbit).granule_info(iGranule).data_granule_name;
    problem_list.code = status;

    return
end

