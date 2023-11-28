function [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = pirate_data( latitude, longitude, SST_In, qual_sst, flags_sst, sstref, ...
    scan_seconds_from_start, granule_start_time_guess)
% pirate_data - reads data from next granule and puts it in orbit - PCC.
%
% Increments the current start time by 5 minues and does a dir on the
% granules direcotry for a data granule within 30 seconds or so of the new
% guess. If it doesn't find a file it writes an error and returns. If it
% does find a granule it reads from the granule and completes the orbit it
% is working on.
%
% INPTUT
%   status - 0 if all good, 122 if no data granule found.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   scan_seconds_from_start - seconds for from the start of the orbit.
%
% OUTPUT
%   granule_directory - the directory with the data files.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   scan_seconds_from_start - seconds for from the start of the orbit.
%   granule_start_time_guess - the matlab_time of the first scan line in
%    the current granule.
%

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

status = 0;

% Get the metadata filename for the granule from which to pirate data. Note
% that this granule starts near the end of the granule with the descending
% nadir crossing of 78 S.

% % % found_one = 0;
% % % test_time = oinfo(iOrbit).ginfo(end).end_time - 5 / 86400;
% % % for iSecond=1:65
% % %     test_time = test_time + 1 / 86400;
% % % 
% % %     metadata_granule = [metadata_directory datestr(test_time, formatOut.yyyy) '/AQUA_MODIS_' datestr(test_time, formatOut.yyyymmddThhmmss) '_L2_SST_OBPG_extras.nc4'];
% % % 
% % %     if exist(metadata_granule)
% % %         found_one = 1;
% % %         break
% % %     end
% % % end

[found_one, metadata_granule, ~] = get_S3_filename( 'metadata', oinfo(iOrbit).ginfo(end).end_time);

if found_one == 0
    fprintf('*** No data metadata granule found for %s. This means there is no file from which to pirate data. Should never get here. No scan lines added to the orbit.\n', datestr(granule_start_time_guess))

    status = populate_problem_list( 122, oinfo(iOrbit).ginfo(1).metadata_name);
else    
    if amazon_s3_run
        % Here for s3.
        % s3 data granule: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100619052000-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc

        % % % data_file_list = dir( [granules_directory datestr( granule_start_time_guess, formatOut.yyyy) '/' datestr( granule_start_time_guess, formatOut.yyyymmddhhmm) '*-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc']);

        [found_one, data_granule, ~] = get_S3_filename( 'data', metadata_granule);
    else
        data_file_list = dir( [granules_directory datestr( granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS.' datestr( granule_start_time_guess, formatOut.yyyymmddThhmm) '*']);
        
        if isempty(data_file_list)
            found_one = 0;
        else
            found_one = 1;
            data_granule = [data_file_list(1).folder '/' data_file_list(1).name];
        end
    end

    if found_one == 0
        if print_diagnostics
            fprintf('*** Could not find a NASA S3 granule corresponding to %s.\n', metadata_granule)
        end

        status = populate_problem_list( 902, ['*** Could not find a NASA S3 granule corresponding to ' metadata_granule]);

        return
    end

    % Need to read the scan times from the pirated metadata file.

    Year = ncread( metadata_granule, '/scan_line_attributes/year');
    YrDay = ncread( metadata_granule, '/scan_line_attributes/day');
    mSec = ncread( metadata_granule, '/scan_line_attributes/msec');

    % Now determine the start times for each scanline and the number of
    % scanlines in this granule. Be careful because the start times for scanlines
    % occur are the same for all detectors in a group.

    scan_line_times = datenum( Year, ones(size(Year)), YrDay) + mSec / 1000 / 86400;

    [ status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
        = add_granule_data_to_orbit( 'pirate', data_granule, metadata_granule, ...
        latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);
end
