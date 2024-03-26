function [xx] = fix_lon_at_poles( xx, jpix)
% fix_lon_at_poles - remove steps in the along-track longitude values near the poles - PCC
%
% This function deals with longitude for the orbit near the poles.
% For 90 degrees norths tart by looking for a large step between elements
% 19200 and 19300, corresponding to nadir latitudes of about 81.8 N. The
% max nadir latitude is 81.84 N for AQUA_MODIS_orbit_046525_20110201T005330_L2_SST.nc4. 
% If the step is to larger longitudes, then remove jpix values between
% 19200 and 19300 and set a new jpix value that is closest to half way
% between the longitude values at 19200 and 19300. It may find several,
% choose the last one; i.e., the one closest to 19300. 360 degrees will be
% subtracted from all longitudes starting at this location until a step
% down is found or the end of the orbit. Sort of a cludge but there are
% likely very few if any SST values in this region and ugly things happen
% to the longitude here.
%
% Similar for the southern region except it goes from scan line 39,000 to 39,3700. 
%
% INPUT
%   latNadir: the nadir values of the latitude for this orbit.
%   xx: the longitudes for a given pixel location in the along-scan direction.
%   jpix: the indices for the locations where the longitude changes by more
%    than 150 degrees between scan lines.
%
% OUTPUT
%   xx: the recast longitude with, hopefully, no large jumps, except maybe
%    at high latitudes.

% Initialize indices for the ranges to use for the high latitude target regions.

indN1 = 19200;
indN2 = 19300;

indS1 = 39000;
indS2 = 39700;

% Get the steps to use.

for kPix=1:length(jpix)
    lonStep(kPix) = -sign(xx(jpix(kPix)+1) - xx(jpix(kPix))) * 360;
end

if ~isempty(jpix)
%     llpix = find( (jpix<indN1) | ((jpix>indN2) & (jpix<indS1)) | (jpix>indS2) );
    llpix = find( (jpix<indN1) | (jpix>indN2) );
    if ~isempty(llpix)
        jpix = jpix(llpix);
        lonStep = lonStep(llpix);
    end
end

% If number of jpix elements is odd, add one more element
% corresponding to the number of scans in the orbit. We don't need
% to add the last lonStep, since it wouldn't be used.

if ~isempty(jpix)
    if rem(length(jpix),2)
        jpix(length(jpix)+1) = length(xx);
    end

    for ifix=1:2:length(jpix)
        locs2fix = [jpix(ifix)+1:jpix(ifix+1)];

        xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
    end
end
