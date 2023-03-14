function [ status, global_attrib, problem_list] = check_global_attrib( fi_granule, problem_list)
% check_global_attrib - read and check global attributes from the metadata file - PCC 
%   
% This script reads the global attributes from the granule file and make
% sure that they exist and/or are within limits. Really just a sanity
% check.
%
% INPUT
%   fi_granule - granule filename. 
%   problem_list - structure with list of filenames (filename) for skipped 
%    file and the reason for it being skipped (problem_code):
%    problem_code: 1 - couldn't find the file in s3.
%                : 2 - didn't find number_of_lines global attribute.
%                : 3 - number of pixels global attribute not equal to 1354.
%                : 4 - number of scan lines global attribute not between 2020 and 2050.
%                : 5 - couldn't find the metadata file copied from OBPG data.
%
% OUTPUT
%   status : 0 - OK
%          : 2 - didn't find number_of_lines global attribute.
%          : 3 - number of pixels global attribute not equal to 1354.
%          : 4 - number of scan lines global attribute not between 2020 and 2050.
%          : 5 - couldn't find the metadata file copied from OBPG data.
%   global_attrib - the global attributes read from the data granul.
%   problem_list - as above but the list is incremented by 1 if a problem.
%

global scan_line_times start_line_index num_scan_lines_in_granule
global latlim secs_per_day secs_per_orbit secs_per_scan_line orbit_length npixels

% Initialize some parameters.

status = 0;
nscans_range = [2019 2051];

% Read the global attributes from the granule file.

global_attrib = ncinfo(fi_granule);

% Perform tests on some of the global variables. 

if isempty(strcmp(global_attrib.Dimensions(1).Name, 'number_of_lines'))
    fprintf('Didn''t find an attribute for ''%s'' in %s. Skipping this granule. Error code 2.\n', global_attrib.Dimensions(1).Name, fi_granule)
    skip_this_granule = 1;
    
    problem_list.iProblem = problem_list.iProblem + 1;
    problem_list.fi_metadata{problem_list.iProblem} = fi_granule;
    problem_list.problem_code(problem_list.iProblem) = 2;
    
    status = problem_list.problem_code(problem_list.iProblem);
    return
end

% Check the number of pixels/scan line and the number of scan lines.

nscans = global_attrib.Dimensions(1).Length;
mpixels = global_attrib.Dimensions(2).Length;

if mpixels ~= npixels
    fprintf('There are %i pixels/scan line in granule: %s but there should be %i. Skipping this granule. Error code 3.\n', mpixels, fi_granule, npixels)
    
    skip_this_granule = 1;
    
    problem_list.iProblem = problem_list.iProblem + 1;
    problem_list.fi_metadata{problem_list.iProblem} = fi_granule;
    problem_list.problem_code(problem_list.iProblem) = 3;
    
    status = problem_list.problem_code(problem_list.iProblem);
    return
end


if (nscans < nscans_range(1)) | (nscans > nscans_range(2))
    fprintf('There are %i scan lines in this granule: %s but the number of scan lines should be between %i and %i. Skipping this granule. Error code 4.\n', ...
        nscans, fi_granule, nscans_range)
    
    skip_this_granule = 1;
    
    problem_list.iProblem = problem_list.iProblem + 1;
    problem_list.fi_metadata{problem_list.iProblem} = fi_granule;
    problem_list.problem_code(problem_list.iProblem) = 4;
    
    status = problem_list.problem_code(problem_list.iProblem);
    return
end


% Get the start and end times for this granule. Make sure
% that time_coverage_start exists in the attributes.

not_found = 1;
for iAtt=1:length(global_attrib.Attributes)
    if strfind(global_attrib.Attributes(iAtt).Name, 'time_coverage_start')
        xx = global_attrib.Attributes(iAtt).Value;
        not_found = 0;
        datetime_start = datenum( str2num(xx(1:4)), str2num(xx(6:7)), ...
            str2num(xx(9:10)), str2num(xx(12:13)), str2num(xx(15:16)), str2num(xx(18:23)));
    end
    
    if strfind(global_attrib.Attributes(iAtt).Name, 'time_coverage_end')
        xx = global_attrib.Attributes(iAtt).Value;
        datetime_end = datenum( str2num(xx(1:4)), str2num(xx(6:7)), ...
            str2num(xx(9:10)), str2num(xx(12:13)), str2num(xx(15:16)), str2num(xx(18:23)));
    end
end

if not_found
    fprintf('Whoa, didn''t find ''time_coverage_start'' in the attributes for: %s. This should never happen. Skipping this granule. Error code 5.\n', fi_granule)
    
    skip_this_granule = 1;
    
    problem_list.iProblem = problem_list.iProblem + 1;
    problem_list.fi_metadata{problem_list.iProblem} = fi_granule;
    problem_list.problem_code(problem_list.iProblem) = 5;
    
    status = problem_list.problem_code(problem_list.iProblem);
    return
end

