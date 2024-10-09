% determine_orbit_timing - how many seconds/orbit
% This script will open the first orbit in the time series, on 4 July 2002
% and then the first one every year. It will get the start time of the
% orbit in matlab time and the list of granules contributing to the orbit.
% It will open the OBPG metadata for that file and get the NASA orbit
% number. From this information it will generate a table of seconds/orbit
% for the given year. 

granule_dir = '/Volumes/MODIS_L2_Modified/AQUA/SST_Orbits/';
metadata_dir = '/Volumes/MODIS_L2_Modified/AQUA/Data_from_OBPG_for_PO-DAAC/';

granule_dir = '/Volumes/MODIS_L2_Modified/AQUA/SST_Orbits/2003/02/AQUA_MODIS_orbit_003973_20030201T001240_L2_SST-URI_24-1.nc4';
metadata_dir = '/Volumes/MODIS_L2_Modified/AQUA/Data_from_OBPG_for_PO-DAAC/2021/AQUA_MODIS_20210131T233001_L2_SST_OBPG_extras.nc4';

iOrbit = 0;
for year=2002:2023
    yearS = num2str(year);

    for month=1:12
        monthS = return_a_string( 2, month);

        % Get the first orbit in this month

        orbit_list = dir( [granule_dir yearS '/' monthS '/*.nc4']);

        if isempty(orbit_list)
            fprintf('No data for %s/%s, going to the next month.\n', yearS, monthS)
        else
            iOrbit = iOrbit + 1;

            % Get the filename for this orbit.
            orbit_filename = [orbit_list(1).folder '/' orbitlist(1).folder];

            % Get the start time of this orbit.

            DateTime(iOrbit) = ncread( orbit_filename, 'DateTime');
            matTime(iOrbit) = datenum(1970,1,1,0,0,0) + DateTime(iOrbit) / 86400;

            % Get the list of filenames

            filenames = ncread( orbit_filename, '/contributing_granules/filenames');
            datetime_string = filenames(1,1:14);

            % Build the OBPG metadata filename from the first file on the list.

            OBPG_filename(iOrbit) = [metadata_dir yearS '/AQUA_MODIS_' datetime_string(1:8) 'T' datetime_string(9:16) '_L2_SST_OBPG_extras.nc4'];

            yearStart = ncread( OBPG_filename(iOrbit), '/scan_line_attributes/year');
            dayStart = ncread( OBPG_filename(iOrbit), '/scan_line_attributes/day');
            msecStart = ncread( OBPG_filename(iOrbit), '/scan_line_attributes/msec');

            granule_start_time = datenum( yearStart(1), dayStart(1), msecStart(1)/(1000*86400));

            NASA_orbit(iOrbit) = ncreadatt( OBPG_filename(iOrbit). '/' 'orbit_number');

        end
    end
end

x = 1