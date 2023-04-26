% griddata_full_orbits

% Read in data.

fi_orbit = '~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/AQUA_MODIS_orbit_41616_20100301T000736_L2_SST.nc4';

sst_in = ncread(fi_orbit, 'SST_In');
lat = ncread(fi_orbit, 'latitude');
lon = ncread(fi_orbit, 'longitude');
regridded_lon = ncread(fi_orbit, 'regridded_longitude');
regridded_lat = ncread(fi_orbit, 'regridded_latitude');

qual_sst = ncread(fi_orbit, 'qual_sst');
sst_good = sst_in;
sst_good(qual_sst>1) = nan;

time_start = tic;

fprintf('Working on sst_good_linear\n')
tic
sst_good_linear = griddata( lon, lat, sst_good, regridded_lon, regridded_lat, 'linear');

fprintf('sst_good_linear took %f s. Working on sst_good_nearest\n', toc)
tic
sst_good_nearest = griddata( lon, lat, sst_good, regridded_lon, regridded_lat, 'nearest');

fprintf('sst_good_nearest took %f s. Working on sst_out_linear\n', toc)
tic
sst_out_linear = griddata( lon, lat, sst_in, regridded_lon, regridded_lat, 'linear');

fprintf('sst_out_linear took %f s. Working on sst_out_nearest\n', toc)
tic
sst_out_nearest = griddata( lon, lat, sst_in, regridded_lon, regridded_lat, 'nearest');

fprintf('sst_out_nearest took %f s. Working on qual_out_nearest\n', toc)
tic
qual_out_nearest = griddata( lon, lat, qual_sst, regridded_lon, regridded_lat, 'nearest');
fprintf('qual_out_nearest took %f s.\n', toc)

% Save the results

nn = strfind( fi_orbit, '.nc4');
fileout = [fi_orbit(1:nn-1) '_regridded.mat'];

save(fileout, 'sst_good_*', 'sst_out_*', 'qual_out_nearest');

fprintf('Job took %f s.\n', toc(time_start))

