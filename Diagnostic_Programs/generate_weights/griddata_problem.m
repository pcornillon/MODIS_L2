% griddata_problem - This script shows what appears to be a problem with griddata - PCC
%
% The idea is to regrid an array on a longitude, latitude grid 
% (lonxx, latxx) that is all zeros except for one point at location iPixel,
% iScan, which has a value of 1, to a new grid (regridded_lon, regridded_lat) 
% and determine the input grid locations that are impacted by this one
% value. 

% Load the two latitude and longitude grids to use.

load '~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/problem'

% Define the input grid.

vin = zeros(size(lat_in));

iPixel = 14;
iScan = 21;

vin(iPixel,iScan) = 1;

% Regrid using griddata linearly interpolating.

vout = griddata( lon_in(:), lat_in(:), vin(:), lon_out(:), lat_out(:));

% Find the impacted locations.

nn = find(vout~=0 & isnan(vout)==0);

% Plot the results

figure(1)
clf

% First the input grid.

h(1) = plot(lon_in(:), lat_in(:), '.k', markersize=15);

% And now the grid to which the input values are to be interpolated.

hold on
h(2) = plot(lon_out(:), lat_out(:), '.r', markersize=10);

% Now plot the locations of the outout grid impacted by the input array.

h(3) = plot( lon_out(nn), lat_out(nn), 'ok', markerfacecolor='c', markersize=20);

% Finally plot the location on the input grid of the nonzero value of this array.

h(4) = plot( lon_in(iPixel,iScan), lat_in(iPixel,iScan), 'ok', markerfacecolor='y', markersize=10);

legend(h, {'input grid', 'output grid', 'output locations affected by input value', 'input value of 1'})
set(gca,fontsize=20)

ylabel('Latitude')
xlabel('longitude')

title('gridata Problem', fontsize=30)

% Finally the location of the 1 in the input grid:

fprintf('The location of 1 in the input grid: (%i, %i)\n', iPixel, iScan)

[ix iy] = ind2sub(size(lat_in), nn);
fprintf('\nAnd the locations impacted in the output grid by the value in the input grid\n   1st dim: %i, %i, %i, %i, %i\n   2nd dim: %i, %i, %i, %i, %i\n', ix, iy) 

fprintf('\nThe problem is the last point. Why is that point affected by the input value?\nAdmittedly, the value is small, %f, but still...\n', vout(nn(end)))