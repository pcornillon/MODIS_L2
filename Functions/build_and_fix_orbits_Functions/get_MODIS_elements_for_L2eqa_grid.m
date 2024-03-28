function [pixStartm, pixEndm, pixStartp, pixEndp] = get_MODIS_elements_for_L2eqa_grid(MODIS_lat, MODIS_lon)
% get_MODIS_elements_for_L2eqa_grid - PCC
%
% This function will determine the along-scan elements in the original
% MODIS grid, which must be averaged to build the new equal area grid in a
% quasi-L2 projection. It starts by obtaining the lat and lon values of
% pixels on a MODIS scan line very near the Equator. A pixel is then added 
% to the center of this vector, which corresponds to the average lat, lon
% on either side of the central value. This is done since the nadir track
% will correspond to the edge of the two new 10x10 km cells on each side of
% the nadir track; i.e., the center of the first cell on either side of
% nadir will be 5 km from nadir. By adding this value we can easily measure
% distances from nadir, using the center pixel on the augmented scan line.
%
% INPUT
%   MODIS_lat: lat values on the scan line for which the nadir value is
%    closest to the Equator.
%   MODIS_lon: correspond lon values.
%
% OUTPUT in global variables.
% %   pixStartm: first along-scan pixel falling within the corresponding
% %    10x10 km L2eq cell on the first half of the scan line moving away from
% %    nadir.
% %   pixEndm: last pixel in the 10x10 km L2eqa grid element.
% %   pixStartp: same as above except for the 2nd half of the scan line.
% %   pixEndp: ...
%
% Note that the scan line of interest is obtained prior to calling this
% function from this command:
%  iEq = find( min(abs(squeeze(MODIS_lat(677,20000:end)))) == abs(squeeze(MODIS_lat(677,20000:end)))) + 20000 - 1;

global pixStartm pixEndm pixStartp pixEndp

% Get the closest equatorial crossing of the MODIS nadir track on the
% descending portion of the orbit so that lat and lon spacing is about
% equal.


pixsPerScan = size(MODIS_lon,1);

scanMODIS_lon = MODIS_lon(1:677);
scanMODIS_lon(678) = mean(squeeze(MODIS_lon(677:678)));
scanMODIS_lon(679:pixsPerScan+1) = MODIS_lon(678:pixsPerScan);

scanMODIS_lat = MODIS_lat(1:677);
scanMODIS_lat(678) = mean(squeeze(MODIS_lat(677:678)));
scanMODIS_lat(679:pixsPerScan+1) = MODIS_lat(678:pixsPerScan);

% % % centerLon = mean(scanMODIS_lon(677:678));
% % % centerLat = mean(scanMODIS_lat(677:678));

% Now calculate the distance to nadir from each cell location along the
% augmented scan lin.

lonSep = diff(scanMODIS_lon);
latSep = diff(scanMODIS_lat);
pixSep = sqrt(lonSep.^2 + latSep.^2) * 111;

dist2nadir(677:-1:1) = cumsum(pixSep(677:-1:1));
dist2nadir(678:pixsPerScan) = cumsum(pixSep(678:pixsPerScan));

% Next construct the 10x10 km grid from these values. The half width of the
% MODIS scan line is 1162 km.

for iDist=10:10:1162
    jDist = iDist / 10;

    nn = find(dist2nadir(1:pixsPerScan/2) >= iDist-10 & dist2nadir(1:pixsPerScan/2) < iDist); 
    pixStartm(jDist) = nn(1);
    pixEndm(jDist) = nn(end);
end

for iDist=10:10:1162
    jDist = iDist / 10;

    nn = find(dist2nadir(pixsPerScan/2+1:end) >= iDist-10 & dist2nadir(pixsPerScan/2+1:end) < iDist);
    pixStartp(jDist) = nn(1) + pixsPerScan/2;
    pixEndp(jDist) = nn(end) + pixsPerScan/2;
end
