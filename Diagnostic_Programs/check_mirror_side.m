% check_mirror_side - will get the mirror side for two consecutive granules.

example = 99;

% Get the list of existing orbits in 2003/01 and generate the associated filenames. 

file_list = dir('/Volumes/MODIS_L2_Modified/OBPG/SST/2003/01/AQUA_MODIS_orbit_*.nc4');

for iFile=1:length(file_list)
    filename{iFile} = [file_list(iFile).folder '/' file_list(iFile).name];
end

% Will look at the last granule in jFile and the first granule in jFile+1.

switch example
    case 1
        iFile = 8;
        jFile = 8;

        iGranule = 11;
        jGranule = 12;

    case 2
        iFile = 9;
        jFile = 9;

        iGranule = 11;
        jGranule = 12;

    case 3
        iFile = 30;
        jFile = 30;

        iGranule = 16;
        jGranule = 17;

    case 99
        iFile = 30;
        jFile = 30;

        iGranule = 15;
        jGranule = 16;
        
end

% Get the granule name for the last granule in jFile and from there get the
% mirror side info and the time info.

gfilename_1 = ['/Volumes/MODIS_L2_original/OBPG/combined/2003/' ncread( filename{iFile}, '/contributing_granules/filenames', [iGranule 1], [1 inf], [1 1])];

fi = gfilename_1;

mside_1 = single(ncread( fi, '/scan_line_attributes/mside'));

sl_year = ncread(fi, '/scan_line_attributes/year');
sl_day = ncread(fi, '/scan_line_attributes/day');
sl_msec = floor(ncread(fi, '/scan_line_attributes/msec'));

matlab_time_1 = datenum(sl_year, 1, sl_day) + sl_msec/ (86400 * 1000);

% Get lat and lon for this granule.

Lat_1 = ncread(fi, '/navigation_data/latitude', [677 1], [1 inf]);
Lon_1 = ncread(fi, '/navigation_data/longitude', [677 1], [1 inf]);


% Get the granule name for the first granule in jFile+1 and from there get 
% the mirror side info and the time info.

gfilename_2 = ['/Volumes/MODIS_L2_original/OBPG/combined/2003/' ncread( filename{jFile}, '/contributing_granules/filenames', [jGranule 1], [1 inf], [1 1])];
fi = gfilename_2;

mside_2 = single(ncread( fi, '/scan_line_attributes/mside'));

sl_year = ncread(fi, '/scan_line_attributes/year');
sl_day = ncread(fi, '/scan_line_attributes/day');
sl_msec = floor(ncread(fi, '/scan_line_attributes/msec'));

matlab_time_2 = datenum(sl_year, 1, sl_day) + sl_msec/ (86400 * 1000);

% Get lat and lon for this granule.

Lat_2 = ncread(fi, '/navigation_data/latitude', [677 1], [1 inf]);
Lon_2 = ncread(fi, '/navigation_data/longitude', [677 1], [1 inf]);

% Clean things up a bit

clear fi sl*

% Output stuff

fprintf('\nOutput for file: %s\n\n', filename{iFile})
fprintf('Mirror side on the last scan line of granule %i is %i and on first scan line of granule %i is %i. They should differ.\n', iGranule, mside_1(end), jGranule, mside_2(1))

secs_per_scan_line = 0.14772;
dtime = (matlab_time_2(1) - (matlab_time_1(end) + 10 * secs_per_scan_line / 86400)) * 86400 / secs_per_scan_line;

fprintf('The difference in scan line times between the last scan line on granule %i and the first scan line of granule %i is %7.2f. It should be 0.\n', iGranule, jGranule, dtime)

nadir_dist = sqrt( ((Lon_2(1)-Lon_1(end)) .* cosd(Lat_2(1))).^2 + (Lat_2(1)-Lat_1(end)).^2) * 111;

fprintf('The nadir point of the last scan line on granule %i is separated by %6.2f km from the nadir point of the first scan line on granule %i. It should be about 1 km.\n\n', iGranule, nadir_dist, jGranule)
