function [status, metadata_file_list, data_file_list, indices, granule_start_time_guess] = get_start_of_first_full_orbit
% get_start_of_first_full_orbit - search from the start time for build_and_fix_orbits for the start of the first full orbit - PCC
%   
% This function starts by searching for the first metadata granule at or
% after the start time passed into build_and_fix_orbits. It then searches
% for the first granule for which the descending nadir track of the
% satellite passes latlim, nominally 78 S.
%
% INPUT
%   none
%
% OUTPUT
%   status  : 911 - end of run.
%           : Value returnd from find_start_of_orbit.
%   metadata_file_list - result of a dir function on the metadata directory
%    returning at least one filename.
%   data_file_list - result of a dir function on the data directory
%    returning at least one filename.
%   indices - a structure with osscan, oescan, gsscan and gescan for the
%    current orbit, data to be pirated from the next orbit if relevant and,
%    also if relevant, values for the next orbit. 
%   granule_start_time_guess - the matlab_time of the granule to start with.
%

local_debug = 0;

% globals for the run as a whole.

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
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

if local_debug; fprintf('In get_start_of_first_full_orbit.\n'); end

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

if amazon_s3_run

    % Will look for the first good granule stepping through the granule
    % times one second at a time until it finds one.

    granule_start_time_guess = granule_start_time_guess - 1 / 86400;
    while 1==1
        granule_start_time_guess = granule_start_time_guess + 1 / 86400;

        if granule_start_time_guess > Matlab_end_time
            fprintf('*** Didn''t find a metadata granule between %s and %s.\n', datestr(Matlab_start_time), datestr(Matlab_end_time))

            status = populate_problem_list( 911, ['No metadata granule in time range: ' datestr(Matlab_start_time) ' to'  datestr(Matlab_end_time)], granule_start_time_guess);
            return
        end

        filename = [metadata_directory datestr(granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS_' datestr(granule_start_time_guess, formatOut.yyyymmddThhmmss) '_L2_SST_OBPG_extras.nc4'];
        
        if exist(filename)
            file_list = dir(filename);
            break
        end
    end

else
    while isempty(file_list)

        granule_start_time_guess = granule_start_time_guess + 1/24;

        if local_debug; fprintf('In while loop. granule_start_time_guess: %s\n', datestr(granule_start_time_guess)); end

        if granule_start_time_guess > Matlab_end_time
            fprintf('*** Didn''t find a metadata granule between %s and %s.\n', datestr(Matlab_start_time), datestr(Matlab_end_time))

            status = populate_problem_list( 911, ['No metadata granule in time range: ' datestr(Matlab_start_time) ' to'  datestr(Matlab_end_time)], granule_start_time_guess);
            return
        end

        file_list = dir( [metadata_directory datestr(granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS_' datestr(granule_start_time_guess, formatOut.yyyymmddThh) '*']);

        if local_debug; fprintf('%s\n', [file_list(1).folder '/' file_list(1).name]); end
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
HH = str2num(file_list(1).name(nn+20:nn+21));
MM = str2num(file_list(1).name(nn+22:nn+23));
SS = str2num(file_list(1).name(nn+24:nn+25));

granule_start_time_guess = datenum(yyyy,mm,dd,HH,MM,SS);

if local_debug; fprintf('Following while loop. granule_start_time_guess: %s\n', datestr(granule_start_time_guess)); end

% Next, find the ganule at the beginning of the first complete orbit
% starting with the first granule found in the time range.

start_line_index = [];

while granule_start_time_guess <= Matlab_end_time
    
    % Zero out iGranule since this is the start of the job and this script
    % is looking for the first granule with a descending 78 S crossing.
    
    iGranule = 0;

    if local_debug; fprintf('In 2nd while loop.\n'); end

    [status, metadata_file_list, data_file_list, indices, granule_start_time_guess] = find_next_granule_with_data( granule_start_time_guess);

    % find_next_granule_with_data, used in the loop above, looks for the next
    % granule with data in it and it looks to see if the nadir track of the
    % granule crosses 78 S while descending. It if does, it finds the pixel at
    % which this occurs and returns the location of this pixel in the granule
    % in start_line_index.

    if local_debug; fprintf('After call to find_nex_granule_with_data. granule_start_time_guess: %s, start_line_index: %i\n', datestr(granule_start_time_guess), start_line_index); end
    
    % Return if end of run.
    
    if (status == 201) | (status == 231) | (status > 900)
        fprintf('End of run.\n')
        return
    end
    
    if ~isempty(start_line_index)
        break
    end
end

% So, the nadir track of the last granule read crossed 78 S moving southward.
% The way find_next_granule_with_data works is that it populates oinfo(1) 
% corresponding to the data prior to this crossing and it populates
% oinfor(2) for the portion of the granule after crossing 78 S. Note that
% iOrbit, the argument of oinfo, is 1 in this case because this is the
% first attempt to find such a crossing. This means that when build_orbit
% is called it will be working on iOrbit=2 but it should really be 1, so
% oinfo will be rewritten at this point.

temp_oinfo = oinfo(2);
oinfo = temp_oinfo;
iOrbit = 1;

% If the start of an orbit was not found in the time range specified let
% the person running the program know.

if (status == 201) | (status == 231) | (status > 900)
    if print_diagnostics
        fprintf('No start of an orbit in the specified range %s to %s.\n', datestr(Matlab_start_time), datestr(Matlab_end_time))
    end
end

