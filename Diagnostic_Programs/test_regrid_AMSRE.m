% test_regrid_AMSRE

% Test MODIS orbit. Get lon, lat and SST from this orbit.

if ~exist('MODIS_fi')
    MODIS_fi = '~/Dropbox/Data/AMSR-R_regridding/AQUA_MODIS_orbit_046525_20110201T005330_L2_SST.nc4';
    
    MODIS_lon = ncread(MODIS_fi, 'regridded_longitude');
    MODIS_lat = ncread(MODIS_fi, 'regridded_latitude');
    MODIS_sst = ncread(MODIS_fi, 'regridded_sst');
    
    % AMSR_E_baseDir = '/Volumes/Aqua-1/AMSR-E_L2-v7/';
    AMSR_E_baseDir = '/Users/petercornillon/Dropbox/Data/AMSR-R_regridding/';
end

% Test AMSR-E orbit.

[outputArg1,outputArg2] = regrid_AMSRE( MODIS_fi, AMSR_E_baseDir, MODIS_lon, MODIS_lat, MODIS_sst)

