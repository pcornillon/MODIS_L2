function [xx] = fix_lon_at_poles( latNadir, xx, jpix)
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

% Work on the northern region near the point at which the satellite moves
% from ascending to descending.

tpix = [];
tStep = [];

if (xx(indN2) - xx(indN1)) < -150

    xxbar = (xx(indN1) + xx(indN2)) / 2;
    nn = find( ( (xx(indN1:indN2-1) > xxbar) & (xx(indN1+1:indN2) < xxbar) ) | ( (xx(indN1:indN2-1) < xxbar) & (xx(indN1+1:indN2) > xxbar) ) ) + indN1 - 1;

    llpix = find(jpix<indN1);

    thisStep = -sign(xx(indN2)-xx(indN1)) * 180;

    if ~isempty(llpix)

        % If the number of jumps before the start of the northern region is
        % odd, this means that there must be a step up in the northern region
        % that will be missed in the following so add one it one scane line
        % before the location at which we determine a step down for the region.
        % It's only necessary if there are steps before the northern region.

        if rem(length(llpix),2)
            tpix = [jpix(llpix) nn(end)-1];
            tStep = [lonStep(llpix) -lonStep(llpix(end))];
        end

        % Now add in the new step down.

        tpix = [jpix(llpix) nn(end)];
        tStep = [lonStep(llpix) thisStep];
    else
        tpix = nn(end);
        tStep = thisStep;
    end

    llpix = find( (jpix>indN2) & (jpix<indS1) );
    if ~isempty(llpix)
        tpix = [tpix jpix(llpix)];
        tStep = [tStep lonStep(llpix)];
    % % % else
    % % %     tpix = tpix;
    % % %     tStep = tStep;
    end
else
    llpix = find(jpix<indS1);
    if ~isempty(llpix)
        tpix = jpix(llpix);
        tStep = lonStep(llpix);
    end
end

% Now work on the sourthern region near the point at which the satellite
% moves from descending to ascending.

if abs(xx(indS2) - xx(indS1)) > 150

    % Find the locations at which xx crosses xxbar in the southern interval.

    xxbar = (xx(indS1) + xx(indS2)) / 2;
    nn = find( ( (xx(indS1:indS2-1) > xxbar) & (xx(indS1+1:indS2) < xxbar) ) | ( (xx(indS1:indS2-1) < xxbar) & (xx(indS1+1:indS2) > xxbar) ) ) + indS1 - 1;

    % % % llpix = find(jpix<indS1);
    % % % if ~isempty(llpix)
    if ~isempty(tpix)
        
        thisStep = sign(xx(indS2) - xx(indS1)) * 180;

        % If tpix has an odd number of values, this means that there is a
        % start of a region to modify but no end. Set the end to just
        % before the location determined for the step up in this region.

        if rem(length(tpix),2)
            tpix(length(tpix)+1) = nn(1)-1;
            tStep(length(tpix)+1) = -sign(xx(indS1) - xx(indS1-1)) * 180;
        end

        % % % tpix = [jpix(llpix) nn(1)];
        % % % tStep = [lonStep(llpix) -sign(xx(indS2)-xx(indS1))*180];
        tpix = [tpix nn(1)];
        tStep = [tStep thisStep];
    else
        % % % tpix = nn(1);
        % % % tStep = -sign(xx(indS2) - xx(indS1)) * 180;
        tpix = nn(1);
        tStep = thisStep;
    end

    llpix = find(jpix>indS2);
    if ~isempty(llpix)
        jpix = [tpix jpix(llpix)];
        lonStep = [tStep lonStep(llpix)];
    else
        jpix = tpix;
        lonStep = tStep;
    end
else
    llpix = find(jpix>indS2);
    if ~isempty(llpix)
        jpix = jpix(llpix);
        jStep = lonStep(llpix);
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
