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
%  CHANGE LOG
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/9/2024 - Initial version - PCC
%   1.0.1 - 5/9/2024 - Added versioning. Removed unused code. - PCC
%   1.0.2 - 5/12/2024 - Added status return to get_filename. - PCC
%   1.2.0 - 5/17/2024 - Added code for switch to list of granules/times.
%           Updated error handling for new approach - PCC

global version_struct
version_struct.pirate_data = '1.2.0';

% globals for the run as a whole.

global print_diagnostics

% globals for build_orbit part.

global oinfo iOrbit
global scan_line_times
global secs_per_day secs_per_orbit secs_per_scan_line secs_per_granule orbit_duration

% globals used in the other major functions of build_and_fix_orbits.

global iProblem problem_list

status = 0;

% Get the metadata filename for the granule from which to pirate data. Note
% that this granule starts near the end of the granule with the descending
% nadir crossing of 78 S. Go to next file on the list if it is within 10
% seconds of the end of the orbit otherwise set found_one to 0. To go to
% the next file on the list increment iGranuleList before the call and
% decrement after the call since we will go after this file when we build
% the next orbit.

if (granuleList(iGranuleList).mtTime - oinfo(iOrbit).ginfo(end).end_time) < (10 / secs_per_day)
    iGranuleList = iGranuleList + 1;

    [status, found_one, metadata_granule_folder_name, metadata_granule_file_name, ~] = get_filename( 'metadata', oinfo(iOrbit).ginfo(end).end_time);

    iGranuleList = iGranuleList - 1;
else
    % % % % %     found_one = 0;
    % % % % % end
    % % % % %
    % % % % % if status == 921
    % % % % %     return
    % % % % % end
    % % % % %
    % % % % % if found_one == 0
    % % % % % fprintf('*** No metadata granule found for %s. This means there is no file from which to pirate data. Should never get here. No scan lines added to the orbit.\n', datestr(granule_start_time_guess))

    status = populate_problem_list( 122, ['No metadata granule found for ' oinfo(iOrbit).ginfo(1).metadata_name ' No file from which to pirate data.']);
    % % % % % else

    return
end

metadata_granule = [metadata_granule_folder_name metadata_granule_file_name];

[status, found_one, data_granule_folder_name, data_granule_file_name, ~] = get_filename( 'sst_data', metadata_granule_file_name);

if status == 921 %%%*** if status > 900
    return
end

if found_one == 0
    % % % % % if print_diagnostics
    % % % % %     fprintf('*** Could not find a NASA S3 granule corresponding to %s.\n', metadata_granule)
    % % % % % end

    status = populate_problem_list( 902, ['Could not find a NASA S3 granule corresponding to ' metadata_granule]);

    return
end

data_granule = [data_granule_folder_name data_granule_file_name];

% Need to get scan_line_times for the pirated granule but this will
% overwrite the values for the previous granule, which are needed for
% the next orbit. Sooo.... copy the current values to a temporary place
% and reinstate them after the call to add_granule_data_to_orbit, which
% needs them. A bit clunky but doing it this way means that I don't
% have to change other stuff.

temp_scan_line_times = scan_line_times;

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

% Now reinstate scan_line_times for the start of the next orbit.

scan_line_times = temp_scan_line_times;
% % % % % end
