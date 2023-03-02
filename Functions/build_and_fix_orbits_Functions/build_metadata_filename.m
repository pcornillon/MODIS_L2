function [status, fi, start_line_index, imatlab_time, missing_granule] = build_metadata_filename( get_granule_info, latlim, input_directory, imatlab_time)
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
%   imatlab_time - updated matlab_time for this granule to start with; the
%    matlab time passed in is approximate.
%   missing_granule - Matlab date/time of granule if missing otherwise empty. 
%

% Initialize return variables.

start_line_index = [];
missing_granule = [];
status = 0;

% Does an OBPG metadata file exist for this time? To sort this out, get the
% date and time for this granule and generate strings for use in the names.

[iyear, imonth, iday, ihour, iminute, isecond] = datevec(imatlab_time);

iyears = num2str(iyear);
imonths = return_a_string(imonth);
idays = return_a_string(iday);
ihours = return_a_string(ihour);
iminutes = return_a_string(iminute);

if strfind(input_directory, 'combined')
    file_list = dir( [input_directory iyears '/AQUA_MODIS.' iyears imonths idays 'T' ihours iminutes '*']);
else
    file_list = dir( [input_directory iyears '/AQUA_MODIS_' iyears imonths idays 'T' ihours iminutes '*']);
end

fi = '';

if isempty(file_list)
    missing_granule = datenum( iyear, imonth, iday, ihour, iminute, 0);
    fprintf('*** Missing file for %s%s%sT%s%s. Going to the next granule.\n', iyears, imonths, idays, ihours, iminutes)
elseif length(file_list) > 2
    fprintf('*** Too many files for %s%s%sT%s%s. Going to the next granule.\n', iyears, imonths, idays, ihours, iminutes)
elseif get_granule_info
    % Found a metadata granule. Does the nadir track for it cross latlim
    % in descent? Read the nadir latitude valuesfor each scan line. Also 
    % read the year, day-of-year and milliseconds for each scan line. These
    % are used to update imatlab_time to the start of this granule. In 
    % addition milliseconds are used to make sure that the 5th scan line in
    % the granule corresponds to the middle detector array.
    
    fi = [file_list(1).folder '/' file_list(1).name];
    
    Year = ncread( fi, '/scan_line_attributes/year');
    YrDay = ncread( fi, '/scan_line_attributes/day');
    mSec = ncread( fi, '/scan_line_attributes/msec');
    
    % Find the matlab time corresponding to the first scan line.
    
    imatlab_time = datenum(Year(1), 1, YrDay(1)) + mSec(1)/(1000*86400);
    
    if abs(mSec(10)-mSec(1)) > 0
        fprintf('The 1st scan line for %s is not the 1st detector in a group of 10. Should never get here.', file_list(1).name)
        status = 1;
        return
    end
    
    nlat_t = single(ncread( fi, '/scan_line_attributes/clat'));
    
    diff_nlat = diff(nlat_t);
    nn = find( (abs(nlat_t(1:end)-latlim)<0.1) & (diff_nlat<0));
    
    if isempty(nn) == 0
        
        % This granule contains the start of a new orbit. Assing the
        % index to the nearest middle of a 10 detector group and break
        % out of this loop.
        
        start_line_index = floor(nn(1) / 10) * 10 + 5;
        return
    end
end

end

