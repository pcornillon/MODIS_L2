function [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = add_granule_data_to_orbit( add_type, data_granule, metadata_granule, latitude, longitude, ...
    SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start)
% get_granule_data - build the granule filename and read the granule data - PCC
%
% This function calls get_metadata, which builds the filename for either
% Amazon s3 or OBPG granules and then reads the fields reqiured for the
% remainder of the processing.
%
% INPUT
%   add_type - 'current' to add from the current granule, 'pirate' to add
%    from the next granule. 
%   data_granule - name of granule from which to read the relevant scan lines.
%   metadata_granule - name of granule from which to read the relevant
%    metadata scan lines. 
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
%  CHANGE LOG 
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/9/2024 - Initial version - PCC
%   1.0.1 - 5/9/2024 - Added versioning. Added line to check if S3 
%           credentials need to be updated, update if they do. 
%   1.0.2 - 5/12/2024 - Test to see if failure to get NASA se credentials
%           end the run if this is the case with status=921. Added status
%           to the returned variable for calls to read_variable_HDF.
%   1.0.3 - 5/16/2024 - Removed 273.15 from NASA SST read in from AWS - PCC
%   1.2.0 - 5/21/2024 - Updated error handling for new approach - PCC 

global version_struct
version_struct.add_granule_data_to_orbit = '1.2.0';

global s3_expiration_time

% globals for the run as a whole.

global npixels

% globals for build_orbit part.

global amazon_s3_run
global secs_per_day

global oinfo iOrbit iGranule
global scan_line_times

% globals used in the other major functions of build_and_fix_orbits.

global iProblem problem_list 

status = 0;

switch add_type
    case 'current'
        if isempty(oinfo(iOrbit).ginfo(iGranule).osscan)
% % % % %             fprintf('No osscan data in oinfo(%i).ginfo(%i).oscan for granule %s. This should never happen.\n', iOrbit, iGranule, oinfo(iOrbit).ginfo(iGranule).metadata_name)

            status = populate_problem_list( 203, ['No osscan data for iOrbit ' num2str(iOrbit) ', iGranule ' num2str(iGranule) '.  oinfo(' num2str(iOrbit) ').ginfo(' num2str(iGranule) ').osscan: ' num2str(oinfo(iOrbit).ginfo(iGranule).osscan)]);
            return
        end

        osscan = oinfo(iOrbit).ginfo(iGranule).osscan;
        oescan = oinfo(iOrbit).ginfo(iGranule).oescan;

        gsscan = oinfo(iOrbit).ginfo(iGranule).gsscan;
        gescan = oinfo(iOrbit).ginfo(iGranule).gescan;
        
    case 'pirate'
        if isempty(oinfo(iOrbit).ginfo(iGranule).pirate_osscan)
% % % % %             fprintf('No osscan data in oinfo(%i).ginfo(%i).pirate_osscan for granule %s. This should never happen.\n', iOrbit, iGranule, oinfo(iOrbit).ginfo(iGranule).metadata_name)

            status = populate_problem_list( 204, ['No pirated osscan data for iOrbit ' num2str(iOrbit) ', iGranule ' num2str(iGranule) '.  oinfo(' num2str(iOrbit) ').ginfo(' num2str(iGranule) ').osscan: ' num2str(oinfo(iOrbit).ginfo(iGranule).osscan)]);
            return
        end

        osscan = oinfo(iOrbit).ginfo(iGranule).pirate_osscan;
        oescan = oinfo(iOrbit).ginfo(iGranule).pirate_oescan;

        gsscan = oinfo(iOrbit).ginfo(iGranule).pirate_gsscan;
        gescan = oinfo(iOrbit).ginfo(iGranule).pirate_gescan;

    otherwise
        fprintf('You entered %s but only ''current'' or ''pirate'' are acceptable./n', add_type)
        keyboard
end

% Now fill fields with the number of scan lines from this granule. 

scan_lines_to_read = gescan - gsscan + 1;

if amazon_s3_run

    % Make sure S3 credentials are up-to-date, then read from the data file

    if (now - s3_expiration_time) > 30 / (60 * 24)
        [status, s3Credentials] = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', 'eiMTJr6yeuD6');
        
        if status == 921 %%%*** if status > 900
            return
        end
    end

    file_id = H5F.open( data_granule, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');

    [status, latitude(:,osscan:oescan)] = read_variable_HDF( file_id, data_granule, 'lat', npixels, gsscan, scan_lines_to_read);
    if status == 921 %%%*** if status > 900
        return
    end
    
    [status, longitude(:,osscan:oescan)] = read_variable_HDF( file_id, data_granule, 'lon', npixels, gsscan, scan_lines_to_read);
    if status == 921 %%%*** if status > 900
        return
    end

    [status, SST_In(:,osscan:oescan)] = read_variable_HDF( file_id, data_granule, 'sea_surface_temperature', npixels, gsscan, scan_lines_to_read);
    if status == 921
        return
    end
    SST_In(:,osscan:oescan) = SST_In(:,osscan:oescan) - 273.15;

    H5F.close(file_id)

    % Read from the metadata file.

    % % % metadata_granule = oinfo(iOrbit).ginfo(iGranule).metadata_name;

    qual_sst(:,osscan:oescan) = int8(ncread( metadata_granule , '/geophysical_data/qual_sst', [1 gsscan], [npixels scan_lines_to_read]));
    flags_sst(:,osscan:oescan) = int16(ncread( metadata_granule, '/geophysical_data/flags_sst', [1 gsscan], [npixels scan_lines_to_read]));

    sstref(:,osscan:oescan) = single(ncread( metadata_granule , '/geophysical_data/sstref', [1 gsscan], [npixels scan_lines_to_read]));
else
    latitude(:,osscan:oescan) = single(ncread( data_granule , '/navigation_data/latitude', [1 gsscan], [npixels scan_lines_to_read]));
    longitude(:,osscan:oescan) = single(ncread( data_granule , '/navigation_data/longitude', [1 gsscan], [npixels scan_lines_to_read]));
    SST_In(:,osscan:oescan) = single(ncread( data_granule , '/geophysical_data/sst', [1 gsscan], [npixels scan_lines_to_read]));

    qual_sst(:,osscan:oescan) = int8(ncread( metadata_granule , '/geophysical_data/qual_sst', [1 gsscan], [npixels scan_lines_to_read]));
    flags_sst(:,osscan:oescan) = int16(ncread(metadata_granule, '/geophysical_data/flags_sst', [1 gsscan], [npixels scan_lines_to_read]));

    sstref(:,osscan:oescan) = single(ncread( metadata_granule , '/geophysical_data/sstref', [1 gsscan], [npixels scan_lines_to_read]));
end

scan_seconds_from_start(osscan:oescan) = single(scan_line_times(gsscan:gescan) - oinfo(iOrbit).start_time) * secs_per_day;
end

