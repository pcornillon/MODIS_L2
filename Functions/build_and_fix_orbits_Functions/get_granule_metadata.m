function [status, missing_granule, granule_start_time_guess] = get_granule_metadata( metadata_directory, granule_start_time_guess)
% find_start_of_orbit - checks if metadata file exists and if it does whether or not it crosses latlim in descent - PCC
%
% Read the latitude of the nadir track for this granule and determine
% whether or not it crosses latlim, nominally 78 S. It also checks to make
% sure that the granule starts with the first detector in a group of 10
% detectors. It does this by reading the milliseconds of each scan line;
% it are the same for all scan lines in a detector group.
%
% INPUT
%   metadata_directory - the directory with the OBPG metadata files.
%   granule_start_time_guess - the matlab_time of the granule to start with.
%
% OUTPUT
%   status  : 0 - OK
%           : 6 - 1st detector in data granule not 1st detector in group of 10.
%           : 10 - missing granule.
%           : 11 - more than 2 metadata files for a given time.
%    requested.
%   missing_granule - Matlab date/time of granule if missing otherwise empty.
%   granule_start_time_guess - the matlab_time of the granule to start with. If scan
%    times are obtained for this granule, granule_start_time_guess will be set to the
%    first scan of the granule; otherwise the value passed in will be returned.
%

global iOrbit orbit_info iGranule
global scan_line_times start_line_index num_scan_lines_in_granule
global formatOut
global latlim
global amazon_s3_run

% Initialize return variables.

status = 0;

start_line_index = [];
missing_granule = [];

% Does an OBPG metadata file exist for this time?

if amazon_s3_run
    % Here for s3. May need to fix this; not sure I will have combined
    % in the name. Probably should set up to search for data or
    % metadata file as we did for the not-s3 run.
    file_list = dir( [metadata_directory datestr(granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS_' datestr(granule_start_time_guess, formatOut.yyyymmddThhmm) '*']);
elseif isempty(strfind(metadata_directory,'combined'))
    % Here if looking for a metadata file - notice the underscore after MODIS.
    file_list = dir( [metadata_directory datestr(granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS_' datestr(granule_start_time_guess, formatOut.yyyymmddThhmm) '*']);
else
    % Here if looking for a data file - notice the period after MODIS.
    file_list = dir( [metadata_directory datestr(granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS.' datestr(granule_start_time_guess, formatOut.yyyymmddThhmm) '*']);
end

if isempty(file_list)
    missing_granule = granule_start_time_guess;
    fprintf('*** Missing file for %s. Going to the next granule.\n', datestr(granule_start_time_guess, formatOut.yyyymmddThhmmss))
    granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);
    
    status = 10;
elseif length(file_list) > 2
    fprintf('*** Too many metadata files for %s. Going to the next granule.\n', datestr(granule_start_time_guess, formatOut.yyyymmddThhmmss))
    granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);
    
    status = 11;
else
    orbit_info(iOrbit).granule_info(iGranule).metadata_name = [file_list(1).folder '/' file_list(1).name];
    
    % Skip this part if the call was simply to build the file name and
    % check for its existence. Next get the Matlab times for each scan line.
    
    Year = ncread( orbit_info(iOrbit).granule_info(iGranule).metadata_name, '/scan_line_attributes/year');
    YrDay = ncread( orbit_info(iOrbit).granule_info(iGranule).metadata_name, '/scan_line_attributes/day');
    mSec = ncread( orbit_info(iOrbit).granule_info(iGranule).metadata_name, '/scan_line_attributes/msec');
    
    scan_line_times = datenum( Year, ones(size(Year)), YrDay) + mSec / 1000 / 86400;
    
    num_scan_lines_in_granule = length(scan_line_times);
    
    % Reset the granule_start_time_guess to the start of this granule if present; this
    % to avoid granule_start_time_guess drifting out of range.
    
    if isempty(scan_line_times) == 0
        granule_start_time_guess = scan_line_times(1);
    end
    
    % Check that the 5th scan line in the granule corresponds to the middle
    % of the detector array.
    
    if abs(mSec(10)-mSec(1)) > 0
        fprintf('The 1st scan line for %s is not the 1st detector in a group of 10. Should never get here.', file_list(1).name)
        granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);

        status = 6;
        return
    end
    
    % Does the descending nadir track crosses latlim?
    
    nlat_t = single(ncread( orbit_info(iOrbit).granule_info(iGranule).metadata_name, '/scan_line_attributes/clat'));
    
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
