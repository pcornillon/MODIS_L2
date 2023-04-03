% test_orbit_building - plots canonical orbit and granules - PCC
% 
% The idea of this script is to plot orbit granules as one progresses
% through build_and_fix_orbits. It starts by loading and plotting the
% canonical orbit. It then gets reads the longitude of the nadir track from
% the current metadata granule--the latitude of the track of the nadir has,
% presumably already been read. It then plots the granule as well as lines
% of relevance such as the new orbit start line, nominally 78 S.

% Start by writing out some stuff.

fprintf('Current start time of current granule: %s\n', datestr(granule_start_time_guess))
fprintf('iOrbit, iGranule: %i, %i\n', iOrbit,iGranule)

if isfield( oinfo.ginfo, 'oescan')
    fprintf('Location of the end of the previous scan in the canonical orbit is at: %i\n', oinfo(iOrbit).ginfo(iGranule-1).oescan)
end

if isfield( oinfo.ginfo, 'start_time')
    fprintf('Start time of current granule: %s\n', datestr(oinfo(iOrbit).ginfo(iGranule).start_time))
end

% Get the canonical orbit and plot it.

load ~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/avg_scan_line_start_times.mat
nlon_typical(1:2464) = nlon_typical(1:2464) + 360;
plot( nlon_typical, nlat_avg, '.k')
hold on

% Get the longitude of the nadir track of the current orbit and add it to
% the plot of the canonical orbit.

nlon_t = single(ncread( oinfo(iOrbit).ginfo(iGranule).metadata_name, '/scan_line_attributes/clon'));
dd2 = diff(nlon_t);
nn2 = find(abs(dd2)> 1);
nlon_t(1:nn2) = nlon_t(1:nn2) + 360;
plot( nlon_t, nlat_t, 'r', linewidth=2)

% Annotate the plot a bit.

grid on
plot([-200 300], -78 * [1 1], 'm', linewidth=2)
plot([-200 300], nlat_t(1) * [1 1], 'g', linewidth=2)
plot([-200 300], nlat_t(end) * [1 1], 'c', linewidth=2)

plot( nlon_t(1), nlat_t(1), 'ok', markerfacecolor='r', markersize=10)
plot( nlon_t(start_line_index), nlat_t(start_line_index), 'ok', markerfacecolor='b', markersize=10)
