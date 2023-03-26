function granule_start_time_guess = get_start_of_first_full_orbit( metadata_directory)
% get_start_of_first_full_orbit - search from the start time for build_and_fix_orbits for the start of the first full orbit - PCC
%   
% This function starts by searching for the first metadata granule at or
% after the start time passed into build_and_fix_orbits. It then searches
% for the first granule for which the descending nadir track of the
% satellite passes latlim, nominally 78 S.
%
% INPUT
%   metadata_directory - directory with the input files
%   granule_start_time_guess - the time to start searching for exisitng metadata granules.
%
% OUTPUT
%   granule_start_time_guess - time of the start of the granule with the
%    start of the next orbit.
%

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule sltimes_avg nlat_avg
global print_diagnostics save_just_the_facts
global formatOut
global latlim secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global Matlab_start_time Matlab_end_time
global sst_range sst_range_grid_size
global med_op
global amazon_s3_run

% granule_start_time_guess is the time, a dummy variable, for the approximate
% start time of a granule. It will be incremented by 5 minutes/granule as
% this script loops through granules. Need to find the first granule in the
% range. Since there has to be a metadata granule corresponding to the
% first data granule, search for the first metadata granule. Note that
% build_metadata_filename will upgrade granule_start_time_guess to the
% actual time of the 1st scan when called with 1 for the 1st argument. This
% effectively syncs the start times to avoid any drifts.

% Because the time input to build_and_fix_orbits may not be at a minute
% when the first metadata file exists start with a broader search; search
% for a granule in the given hour. Remove minutes and seconds from the
% specified start time. In the while loop increment by one hour.

file_list = [];

granule_start_time_guess = floor(Matlab_start_time*24) / 24 - 1 / 24;

while isempty(file_list)
    granule_start_time_guess = granule_start_time_guess + 1/24;
    
    if granule_start_time_guess > Matlab_end_time
        fprintf('Didn''t find a metadata granule between %f and %f.\n', Matlab_start_time, Matlab_end_time)
        
        status = populate_problem_list( 911, []);
        return
    end
    
    % index_offset is used when getting the date and time from the name of
    % the granule. If a PO.DAAC file there is no 'T' between date and time,
    % for an OBPG file there is.
    
    index_offset = 1;
    if amazon_s3_run
        index_offset = 0;
        % Here for s3. May need to fix this; not sure I will have combined 
        % in the name. Probably should set up to search for data or
        % metadata file as we did for the not-s3 run.
        file_list = dir( [metadata_directory datestr(Matlab_start_time, formatOut.yyyy) '/AQUA_MODIS_' datestr(Matlab_start_time, formatOut.yyyymmddThh) '*']);
        file_list = dir( [metadata_directory datestr(Matlab_start_time, formatOut.yyyy) '/AQUA_MODIS_' datestr(Matlab_start_time, formatOut.yyyymmdd) '*']);
    elseif isempty(strfind(metadata_directory,'combined'))
        % Here if looking for a metadata file - notice the underscore after MODIS.
        file_list = dir( [metadata_directory datestr(Matlab_start_time, formatOut.yyyy) '/AQUA_MODIS_' datestr(Matlab_start_time, formatOut.yyyymmddThh) '*']);
    else
        % Here if looking for a data file - notice the period after MODIS.
        file_list = dir( [metadata_directory datestr(Matlab_start_time, formatOut.yyyy) '/AQUA_MODIS.' datestr(Matlab_start_time, formatOut.yyyymmddThh) '*']);
    end
end

% Found an hour with at least one metadata file in it. Get the Matlab time
% corresponding to this file (yyyy mm dd T hh mm ss is good enough) and
% starting with the time of this file, search for a granule with the start
% of an orbit, defined as the point at which the descending satellite crosses 
% latlim, nominally 78 S.

% fi_metadata: AQUA_MODIS_20030101T002505_L2_SST_OBPG_extras.nc4

nn = strfind( file_list(1).name, 'AQUA_MODIS_');
yyyy = str2num(file_list(1).name(nn+11:nn+14));
mm = str2num(file_list(1).name(nn+15:nn+16));
dd = str2num(file_list(1).name(nn+17:nn+18));
HH = str2num(file_list(1).name(nn+19+index_offset:nn+20+index_offset));
MM = str2num(file_list(1).name(nn+21+index_offset:nn+22+index_offset));

granule_start_time_guess = datenum(yyyy,mm,dd,HH,MM,0);

% Next, find the ganule at the beginning of the first complete orbit
% starting with the first granule found in the time range.

[status, granule_start_time_guess] = find_start_of_orbit( metadata_directory, granule_start_time_guess);

% Abort this run if a major problem occurs at this point.

if status ~= 0
    fprintf('*** Major problem with metadata file %s at date/time %s or no start of an orbit in the specified range %s to %s. Aborting.\n', ...
        orbit_info(iOrbit).granule_info(iGranule).metadata_name, datestr(granule_start_time_guess), datestr(Matlab_start_time), datestr(Matlab_end_time))
    return
end

