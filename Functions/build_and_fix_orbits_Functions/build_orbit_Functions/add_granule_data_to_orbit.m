function [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = add_granule_data_to_orbit( add_type, fi_granule, latitude, longitude, SST_In, qual_sst, ...
    flags_sst, sstref, scan_seconds_from_start)
% get_granule_data - build the granule filename and read the granule data - PCC
%
% This function calls get_metadata, which builds the filename for either
% Amazon s3 or OBPG granules and then reads the fields reqiured for the
% remainder of the processing.
%
% INPUT
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
%   status  : 203 - no osscan data in oinfo.
%           : 204 - no pirate_osscan data in oinfo.
%   add_type - 'current' to use the current granule, 'pirate' to us the
%    next granule.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   scan_seconds_from_start - seconds for from the start of the orbit.
%

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
global oinfo iOrbit iGranule iProblem problem_list
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length time_of_NASA_orbit_change
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global latlim secs_per_day secs_per_orbit secs_per_scan_line orbit_length npixels

status = 0;

switch add_type
    case 'current'
        if isempty(oinfo(iOrbit).ginfo(iGranule).osscan)
            fprintf('No osscan data in oinfo(%i).ginfo(%i).oscan for granule %s. This should never happen.\n', iOrbit, iGranule, oinfo(iOrbit).ginfo(iGranule).metadata_name)
            
            status = populate_problem_list( 203, oinfo(iOrbit).ginfo(iGranule).osscan);
            return
        end
        
        osscan = oinfo(iOrbit).ginfo(iGranule).osscan;
        oescan = oinfo(iOrbit).ginfo(iGranule).oescan;
        
        gsscan = oinfo(iOrbit).ginfo(iGranule).gsscan;
        gescan = oinfo(iOrbit).ginfo(iGranule).gescan;
        
        scan_lines_to_read = gescan - gsscan + 1;
        
    case 'pirate'
        if isempty(oinfo(iOrbit).ginfo(iGranule).pirate_osscan)
            fprintf('No osscan data in oinfo(%i).ginfo(%i).pirate_osscan for granule %s. This should never happen.\n', iOrbit, iGranule, oinfo(iOrbit).ginfo(iGranule).metadata_name)
            
            status = populate_problem_list( 204, oinfo(iOrbit).ginfo(iGranule).osscan);
            return
        end
        
        osscan = oinfo(iOrbit).ginfo(iGranule).pirate_osscan;
        oescan = oinfo(iOrbit).ginfo(iGranule).pirate_oescan;
        
        gsscan = oinfo(iOrbit).ginfo(iGranule).pirate_gsscan;
        gescan = oinfo(iOrbit).ginfo(iGranule).pirate_gescan;
        
        scan_lines_to_read = gescan - gsscan + 1;

    otherwise
        fprintf('You entered %s but only ''current'' or ''pirate'' are acceptable./n', add_type)
        keyboard
end
    latitude(:,osscan:oescan) = single(ncread( fi_granule , '/navigation_data/latitude', [1 gsscan], [npixels scan_lines_to_read]));
    longitude(:,osscan:oescan) = single(ncread( fi_granule , '/navigation_data/longitude', [1 gsscan], [npixels scan_lines_to_read]));
    SST_In(:,osscan:oescan) = single(ncread( fi_granule , '/geophysical_data/sst', [1 gsscan], [npixels scan_lines_to_read]));
    
    qual_sst(:,osscan:oescan) = int8(ncread( fi_granule , '/geophysical_data/qual_sst', [1 gsscan], [npixels scan_lines_to_read]));
    flags_sst(:,osscan:oescan) = int16(ncread(fi_granule, '/geophysical_data/flags_sst', [1 gsscan], [npixels scan_lines_to_read]));
    
    sstref(:,osscan:oescan) = single(ncread( fi_granule , '/geophysical_data/sstref', [1 gsscan], [npixels scan_lines_to_read]));
    
    scan_seconds_from_start(osscan:oescan) = single(scan_line_times(gsscan:gescan) - oinfo(iOrbit).start_time) * secs_per_day;
end

