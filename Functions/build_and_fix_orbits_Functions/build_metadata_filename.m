function [status, fi, start_line_index, scan_line_times, missing_granule, num_scan_lines_in_granule, imatlab_time] = ...
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
%   status  : 0 - OK
%           : 6 - 1st detector in data granule not 1st detector in group of 10. 
%           : 10 - missing granule.
%           : 11 - more than 2 metadata files for a given time. 
%   fi - the completely specified filename of the 1st granule for the orbit found.
%   start_line_index - the index in fi for the start of the orbit.
%   scan_line_times - matlab time for each scan line if granule info is
%    requested.
%   missing_granule - Matlab date/time of granule if missing otherwise empty.
%   num_scan_lines_in_granule - number of scans in this granule.
%   imatlab_time - the matlab_time of the granule to start with. If scan
%    times are obtained for this granule, imatlab_time will be set to the
%    first scan of the granule; otherwise the value passed in will be returned.
%

% Initialize return variables.

status = 0;
fi = '';
start_line_index = [];
scan_line_times = [];
num_scan_lines_in_granule = [];
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
    
    status = 10;
elseif length(file_list) > 2
    fprintf('*** Too many metadata files for %s. Going to the next granule.\n', datestr(imatlab_time, formatOut))
    
    status = 11;
else
    fi = [file_list(1).folder '/' file_list(1).name];

    if get_granule_info

        % Skip this part if the call was simply to build the file name and
        % check for its existence. Next get the Matlab times for each scan line.

        Year = ncread( fi, '/scan_line_attributes/year');
        YrDay = ncread( fi, '/scan_line_attributes/day');
        mSec = ncread( fi, '/scan_line_attributes/msec');

        scan_line_times = datenum( Year, ones(size(Year)), YrDay) + mSec / 1000 / 86400;

        num_scan_lines_in_granule = length(scan_line_times);
        
        % Reset the imatlab_time to the start of this granule if present; this
        % to avoid imatlabt_time drifting out of range.

        if isempty(scan_line_times) == 0
            imatlab_time = scan_line_times(1);
        end

        % Check that the 5th scan line in the granule corresponds to the middle
        % of the detector array.

        if abs(mSec(10)-mSec(1)) > 0
            fprintf('The 1st scan line for %s is not the 1st detector in a group of 10. Should never get here.', file_list(1).name)
            status = 6;
            return
        end

        % Does the descending nadir track crosses latlim?

        nlat_t = single(ncread( fi, '/scan_line_attributes/clat'));

        % Get the separation of along-track nadir pixels. Add one
        % separation at the end of the track for this granule so that the
        % size of the difference vector and along-track vector are the
        % same; need this to find the minimum.

        diff_nlat = [diff(nlat_t); nlat_t(end)-nlat_t(end-1)];

        mm = find( (abs(nlat_t-latlim)<0.1) & (diff_nlat<=0));

        if isempty(mm)
            return
        else

            % Make sure that the nadir track actually crossed latlim. This
            % addresses the problem of a nadir track that ends before or 
            % starts just after crossing latlim.
    
            if sign(nlat_t(mm(1))-latlim) == sign(nlat_t(mm(end))-latlim)
                return
            else
                nn = mm(1) - 1 + find(min(abs(nlat_t(mm)-latlim)) == abs(nlat_t(mm)-latlim));
                start_line_index = floor(nn(1) / 10) * 10 + 5;
            end
        end
    end
end
