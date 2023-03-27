function [latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = add_granule_data_to_orbit( fi_granule, osscan, oescan, gsscan, gescan, ...
    latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start)
% get_granule_data - build the granule filename and read the granule data - PCC
%
% This function calls get_metadata, which builds the filename for either
% Amazon s3 or OBPG granules and then reads the fields reqiured for the
% remainder of the processing.
%
% INPUT
% % % %   granules_directory - the name of the directory with the granules.
% % % %   data_file_list - the list of filenames corresponding to this granule
% % % %    --hopefully, just one filename on the list.
% % % %   check_attributes - 1 to read the global attributes for the data granule
% % % %    and check that they exist and/or are reasonable.
%   fi_granule - name of granule from which to read the relevant scan lines.
%   osscan - starting scan line in orbit for data from this granule.
%   oescan - ending scan line in orbit for data from this granule.
%   gsscan - starting location in granule from which to extract scan lines.
%   gescan - ending location in granule from which to extract scan lines.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   scan_seconds_from_start - seconds for from the start of the orbit.
%
% OUTPUT
% % % %   status  : 0 - OK
% % % %           : 1 - couldn't find the data granule.
% % % %           : 2 - didn't find number_of_lines global attribute.
% % % %           : 3 - number of pixels global attribute not equal to 1354.
% % % %           : 4 - number of scan lines global attribute not between 2020 and 2050.
% % % %           : 5 - couldn't find the metadata file copied from OBPG data.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   scan_seconds_from_start - seconds for from the start of the orbit.
%

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule sltimes_avg nlat_avg
global latlim secs_per_day secs_per_orbit secs_per_scan_line orbit_length npixels

% % % osscan = oinfo(iOrbit).ginfo(iGranule).osscan;
% % % oescan = oinfo(iOrbit).ginfo(iGranule).oescan;
% % % 
% % % gsscan = oinfo(iOrbit).ginfo(iGranule).gsscan;
% % % gescan = oinfo(iOrbit).ginfo(iGranule).gescan;
% % % 
% % % scan_lines_to_read = gescan - gsscan + 1;
% % % 
% % % % % % status = build_granule_filename( granules_directory, check_attributes);
% % % 
% % % % Read the fields
% % % 
% % % fi_granule = oinfo(iOrbit).ginfo(iGranule).data_name;

% % % if (status == 0) & ~isempty(oescan)
    latitude(:,osscan:oescan) = single(ncread( fi_granule , '/navigation_data/latitude', [1 gsscan], [npixels scan_lines_to_read]));
    longitude(:,osscan:oescan) = single(ncread( fi_granule , '/navigation_data/longitude', [1 gsscan], [npixels scan_lines_to_read]));
    SST_In(:,osscan:oescan) = single(ncread( fi_granule , '/geophysical_data/sst', [1 gsscan], [npixels scan_lines_to_read]));
    
    qual_sst(:,osscan:oescan) = int8(ncread( fi_granule , '/geophysical_data/qual_sst', [1 gsscan], [npixels scan_lines_to_read]));
    flags_sst(:,osscan:oescan) = int16(ncread(fi_granule, '/geophysical_data/flags_sst', [1 gsscan], [npixels scan_lines_to_read]));
    
    sstref(:,osscan:oescan) = single(ncread( fi_granule , '/geophysical_data/sstref', [1 gsscan], [npixels scan_lines_to_read]));
    
    scan_seconds_from_start(osscan:oescan) = single(scan_line_times(gsscan:gescan) - oinfo(iOrbit).orbit_start_time) * secs_per_day;
% % % else
% % %     fprintf('****** Data for %s not read because of error %i.\n', oinfo(iOrbit).name, status)
% % %     fprintf('Orbit range %i-%i; granule range %i-%i.\n', osscan, oescan, gsscan, gescan)
% % %     
% % %     status = populate_problem_list( 121, fi_granule);
% % % end

end

