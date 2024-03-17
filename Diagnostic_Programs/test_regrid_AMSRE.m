% test_regrid_AMSRE

% Test MODIS orbit. Get lon, lat and SST from this orbit.

fi = '/Users/petercornillon/Data/temp_MODIS_L2_output_directory/output/SST/2011/01/AQUA_MODIS_orbit_046073_20110101T013634_L2_SST.nc4';

MODIS_lon = ncread(fi, 'regridded_longitude');
MODIS_lat = ncread(fi, 'regridded_latitude');
MODIS_sst = ncread(fi, 'regridded_sst');

% Test AMSR-E orbit.

AMSR_E_baseDir = '/Volumes/Aqua-1/AMSR-E_L2-v7/';

[outputArg1,outputArg2] = regrid_AMSRE( fi, AMSR_E_baseDir, MODIS_lon, MODIS_lat, MODIS_sst);