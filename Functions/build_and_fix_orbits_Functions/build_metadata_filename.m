function [status, fi, start_line_index, scan_line_times, missing_granule, imatlab_time] = ...
    build_metadata_filename( get_granule_info, latlim, input_directory, imatlab_time)
% find_start_of_orbit - checks if metadata file exists and if it does whether or not it crosses latlim in descent - PCC
%
% Read the latitude of the nadir track for this granule and determine
% whether or not it crosses latlim, nominally 78 S. It also checks to make
% sure that the granule starts with the first detector in a group of 10
% detectors. It does this by reading the milliseconds of each scan line;
% it are the same for all scan lines in a detector group.
%
% INPUT
%   get_granule_info - if 1, read info needed to determine if this granule
%    contains the start of a new orbit. If 0, return after checking for
%    existence of the file.
%   latlim - the latitude defining the start of an orbit.
%   input_directory - the directory with the OBPG metadata files.
%   imatlab_time - the matlab_time of the granule to start with.
%
% OUTPUT
%   status - 0 if success, 1 if problem with detectors.
%   fi - the completely specified filename of the 1st granule for the orbit found.
%   start_line_index - the index in fi for the start of the orbit.
%   scan_line_times - matlab time for each scan line if granule info is
%    requested.
%   missing_granule - Matlab date/time of granule if missing otherwise empty.
%   imatlab_time - the matlab_time of the granule to start with. If scan
%    times are obtained for this granule, imatlab_time will be set to the
%    first scan of the granule; otherwise the value passed in will be returned.
%

% Initialize return variables.

status = 0;
fi = '';
start_line_index = [];
scan_line_times = [];
missing_granule = [];

% Define formats to use when unpacking the matlab time into file names.

formatOut = 'yyyymmddTHHMM';
formatOutYear = 'yyyy';

% Does an OBPG metadata file exist for this time?

if strfind(input_directory, 'combined')
    file_list = dir( [input_directory datestr(imatlab_time, formatOutYear) '/AQUA_MODIS.' datestr(imatlab_time, formatOut) '*']);
else
    file_list = dir( [input_directory datestr(imatlab_time, formatOutYear) '/AQUA_MODIS_' datestr(imatlab_time, formatOut) '*']);
end

if isempty(file_list)
    missing_granule = imatlab_time;
    fprintf('*** Missing file for %s. Going to the next granule.\n', datestr(imatlab_time, formatOut))
elseif length(file_list) > 2
    fprintf('*** Too many files for %s. Going to the next granule.\n', datestr(imatlab_time, formatOut))
else
    fi = [file_list(1).folder '/' file_list(1).name];

    if get_granule_info

        % Skip this part if the call was simply to build the file name and
        % check for its existence. Next get the Matlab times for each scan line.

        Year = ncread( fi, '/scan_line_attributes/year');
        YrDay = ncread( fi, '/scan_line_attributes/day');
        mSec = ncread( fi, '/scan_line_attributes/msec');

        scan_line_times = datenum( Year, ones(size(Year)), YrDay) + mSec / 1000 / 86400;

        % Reset the imatlab_time to the start of this granule if present; this
        % to avoid imatlabt_time drifting out of range.

        if isempty(scan_line_times) == 0
            imatlab_time = scan_line_times(1);
        end

        % Check that the 5th scan line in the granule corresponds to the middle
        % of the detector array.

        if abs(mSec(10)-mSec(1)) > 0
            fprintf('The 1st scan line for %s is not the 1st detector in a group of 10. Should never get here.', file_list(1).name)
            status = 1;
            return
        end

        % Does the nadir track crosses latlim?

        nlat_t = single(ncread( fi, '/scan_line_attributes/clat'));

        nn = find(abs(nlat_t(1:end)-latlim)<0.1);

        % If nadir track didn't cross latlim, return.
        if isempty(nn)
            return
        else
            % If ascending reset nn to empty & return; we want a descending orbit.

            diff_nlat = diff(nlat_t);
            if diff_nlat(min(end, nn)) > 0
                nn = [];
                return
            else
                % Get the scan line nearest the middle of the 10 detector grou

                start_line_index = floor(nn(1) / 10) * 10 + 5;
                return
            end
        end

    end
end
