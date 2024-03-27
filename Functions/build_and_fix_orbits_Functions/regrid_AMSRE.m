function [L2eqaLon, L2eqaLat, L2eqa_MODIS_SST, L2eqa_AMSR_E_SST, MODIS_SST_on_AMSR_E_grid] = ...
    regrid_AMSRE( MODIS_fi, AMSR_E_baseDir, MODIS_lon, MODIS_lat, MODIS_SST)
% regrid_AMSRE and MODIS to L3 and L2 coordinates corresponding to AMSR-E - PCC
%
% This function will first determine which AMSR-E orbit corresponds to the
% current MODIS orbit and read the AMSR-E lat, lon and SST. It will then
% average MODIS to a 10x10 km grid and regrid the MODIS data to the AMSR-E
% data between 65 S and 65N after which it will determine the longitudinal
% range of the two portions of the AMSR-E orbit between 65 S and 65 N and
% regrid both AMSR-E and MODIS to this grid.
%
% INPUT
%   fi - the filename of the MODIS orbit. If empty then use the needed information in oinfo.
%   AMSR_E_baseDir - location of the AMSR-E data.
%
%   MODIS_lon - regridded of MODIS.
%   MODIS_lat - regridded of MODIS.
%   MODIS_SST - regridded of MODIS.
%
% OUTPUT
%   L2eqaLon: longitude for the new 10x10 km grid averaged from all
%    latitudes falling in the the original grid,
%   L2eqaLat: latitude for the new 10x10 km grid, averaged as for Lon.
%   L2eqa_MODIS_SST: SST for the new 10x10 km grid, averaged as for Lon.
%   L2eqa_AMSR_E_SST: AMSR-E SST regridded to the L2eqa grid. 
%   MODIS_SST_on_AMSR_E_grid: MODIS SST regridded to the AMSR-E grid. 

global pixStartm pixEndm pixStartp pixEndp
global oinfo iOrbit iGranule iProblem problem_list

% Get the AMSR-E data. Start by determining the correct AMSR-E orbit. 

% The first AMSR-E orbit with data, orbit #416, starts at 01-Jun-2002
% 19:05:19 or Matlab time 731368.7953587963. The average time for one orbit
% is: 98.863071 minutes. Given the NASA orbit number of this MODIS orbit--
% oinfo.ginfo(end).NASA_orbit_number--we can guess at the name of the
% corresponding AMSR-E orbit and we can check that the start times of the
% AMSR-E and MODIS orbits are similar.
tic
if ~isempty(MODIS_fi)
    temp_time = ncread( MODIS_fi, 'DateTime');
    matlab_time_MODIS_start = datenum([1970,1,1]) + double(temp_time)/86400;

    kk = strfind( MODIS_fi, '_orbit_');
    NASA_orbit_t = str2num(MODIS_fi(kk+7:kk+12));

    [MODIS_yr, MODIS_mn, MODIS_day, MODIS_hr, MODIS_min, MODIS_sec] = datevec(matlab_time_MODIS_start);
else
    NASA_orbit_t = oinfo(end).orbit_number;
    
    [MODIS_yr, MODIS_mn, MODIS_day, MODIS_hr, MODIS_min, MODIS_sec] = datevec(oinfo(end).start_time);
end

% Build the AMSR-E orbit filename.

NASA_orbit = return_a_string( 6, NASA_orbit_t);

year_s = return_a_string( 4, MODIS_yr);
month_s = return_a_string( 2, MODIS_mn);
day_s = return_a_string( 2, MODIS_day);

AMSR_E_fi = [AMSR_E_baseDir year_s '/' year_s month_s day_s '-amsre-remss-l2p-l2b_v07_r' NASA_orbit(2:end) '.dat-v01.nc'];

%       metadata_name
%       data_name
%       NASA_orbit_number

% % % datestr(datenum([1981,1,1]) + double(ref_time)/86400)

% AMSR_E_fi = '~/Dropbox/Data/AMSR-R_regridding/20110201-amsre-remss-l2p-l2b_v07_r46525.dat-v01.nc';
% MODIS_fi = '~/Dropbox/Data/AMSR-R_regridding/AQUA_MODIS_orbit_046525_20110201T005330_L2_SST.nc4';
% 
% MODIS_lat = ncread( MODIS_fi, 'regridded_latitude');
% MODIS_lon = ncread( MODIS_fi, 'regridded_longitude');

% Note that the AMSR_E data are transposed, i<==>j, to be compatible with
% MODIS data.

AMSR_E_lat = ncread( AMSR_E_fi, 'lat')';
AMSR_E_lon = ncread( AMSR_E_fi, 'lon')';
AMSR_E_SST = ncread( AMSR_E_fi, 'sea_surface_temperature')' - 273.15;

% The beginning and end of the orbit appears to be nan values. Get rid of them.

nn = find(isnan(AMSR_E_lon(10,:)) == 0);
AMSR_E_SST = AMSR_E_SST(:,nn);
AMSR_E_lat = AMSR_E_lat(:,nn);
AMSR_E_lon = AMSR_E_lon(:,nn);

% Get rid of big jumps in longitude for AMSR-E. Do this for each pixel
% (column) location in the along-scan direction for the length of the
% orbit. Start by getting the step in longitude in the along-track
% direction at each pixel location. (Will use the same threshold for the
% longitudinal step as used for MODIS. 

lon_step_threshold = 190;

diffcol = diff(AMSR_E_lon, 1, 2);

for iCol=1:size(AMSR_E_lon,1)
    xx = AMSR_E_lon(iCol,:);

    % Find large longitude jumps for this column

    [~, jpix] = find( abs(diffcol(iCol,:)) > lon_step_threshold);

    if ~isempty(jpix)

        % Get the step where there is a large jump and set to 360 times the
        % sign of the step.

        for kPix=1:length(jpix)
            lonStep(kPix) = -sign(xx(jpix(kPix)+1) - xx(jpix(kPix))) * 360;
        end

        % If there is only one step set a second step at the end of the
        % orbit.

        if rem(length(jpix),2)
            jpix(length(jpix)+1) = length(xx);
        end

        % Now offset for each step.

        for ifix=1:2:length(jpix)
            locs2fix = [jpix(ifix)+1:jpix(ifix+1)];
            xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
        end

        AMSR_E_lon(iCol,:) = xx;
    end
end

% Add 360 since AMSR-E logitudes start low.

AMSR_E_lon = AMSR_E_lon + 360;

% % % %% Determine the MODIS grid elements to average to make the new 10x10 km grid. 
% % % 
% % % % Get the closest equatorial crossing of the MODIS nadir track on the
% % % % descending portion of the orbit.
% % % 
% % % iEq = find( min(abs(squeeze(MODIS_lat(677,20000:end)))) == abs(squeeze(MODIS_lat(677,20000:end)))) + 20000 - 1;
% % % 
% % % % Build the L2eqa grid. Will get the lat and lon values of pixels on a
% % % % MODIS scan line very near the Equator. We will add a pixel to the center
% % % % of the vector corresponding to the average lat, lon on either side of the
% % % % center. We do this since the Equator will correspond to the edge of the
% % % % two new 10x10 km cells on each side of the Equator; i.e., the center of
% % % % the first cell on either side of nadir will be 5 km from nadir. By adding
% % % % this value we can easily measure distances from nadir, from the center
% % % % pixel on the augmented scan line.
% % % 
% % % pixsPerScan = size(MODIS_lon,1);
% % % 
% % % scanMODIS_lon = MODIS_lon(1:677,iEq);
% % % scanMODIS_lon(678) = mean(squeeze(MODIS_lon(677:678,iEq)));
% % % scanMODIS_lon(679:pixsPerScan+1) = MODIS_lon(678:pixsPerScan,iEq);
% % % 
% % % scanMODIS_lat = MODIS_lat(1:677,iEq);
% % % scanMODIS_lat(678) = mean(squeeze(MODIS_lat(677:678,iEq)));
% % % scanMODIS_lat(679:pixsPerScan+1) = MODIS_lat(678:pixsPerScan,iEq);
% % % 
% % % % % % centerLon = mean(scanMODIS_lon(677:678));
% % % % % % centerLat = mean(scanMODIS_lat(677:678));
% % % 
% % % % Now calculate the distance to nadir from each cell location along the
% % % % augmented scan lin.
% % % 
% % % lonSep = diff(scanMODIS_lon);
% % % latSep = diff(scanMODIS_lat);
% % % pixSep = sqrt(lonSep.^2 + latSep.^2) * 111;
% % % 
% % % dist2nadir(677:-1:1) = cumsum(pixSep(677:-1:1));
% % % dist2nadir(678:pixsPerScan) = cumsum(pixSep(678:pixsPerScan));
% % % 
% % % % Next construct the 10x10 km grid from these values. The half width of the
% % % % MODIS scan line is 1162 km.
% % % 
% % % for iDist=10:10:1162
% % %     jDist = iDist / 10;
% % % 
% % %     nn = find(dist2nadir(1:pixsPerScan/2) >= iDist-10 & dist2nadir(1:pixsPerScan/2) < iDist); 
% % %     num2avgm(jDist) = length(nn);
% % %     pixStartm(jDist) = nn(1);
% % %     pixEndm(jDist) = nn(end);
% % % 
% % %     % Get the pixel(s) either at the along-scan center of each 10x10 cell
% % %     % if the number of elements to average is odd, otherwise get the pixles
% % %     % on each side of the center. These will be averaged to get the lat and
% % %     % lon of the center of the grid. (We will always be averaging 10 pixels
% % %     % in the along-track direction since the bow-tie fixing portion of
% % %     % build_and_fix_orbits forces the scan lines to be parallel to one
% % %     % another. 
% % % 
% % %     numPixElmnts = length(nn);
% % %     if rem(numPixElmnts,2)
% % %         pixSubStartm(jDist) = nn(ceil(numPixElmnts / 2));
% % %         pixSubEndm(jDist) = pixSubStartm(jDist);
% % %     else
% % %         pixSubStartm(jDist) = nn(numPixElmnts / 2);
% % %         pixSubEndm(jDist) = nn(numPixElmnts / 2) + 1;
% % %     end
% % % end
% % % 
% % % for iDist=10:10:1162
% % %     jDist = iDist / 10;
% % % 
% % %     nn = find(dist2nadir(pixsPerScan/2+1:end) >= iDist-10 & dist2nadir(pixsPerScan/2+1:end) < iDist);
% % %     num2avgp(jDist) = length(nn);
% % %     pixStartp(jDist) = nn(1) + pixsPerScan/2;
% % %     pixEndp(jDist) = nn(end) + pixsPerScan/2;
% % % 
% % %     numPixElmnts = length(nn);
% % %     if rem(numPixElmnts,2)
% % %         pixSubStartp(jDist) = nn(ceil(numPixElmnts / 2));
% % %         pixSubEndp(jDist) = pixSubStartp(jDist);
% % %     else
% % %         pixSubStartp(jDist) = nn(numPixElmnts / 2);
% % %         pixSubEndp(jDist) = nn(numPixElmnts / 2) + 1;
% % %     end
% % % end

% Get the elements to use in the regridding.

if iOrbit == 2
    iEq = find( min(abs(squeeze(MODIS_lat(677,20000:end)))) == abs(squeeze(MODIS_lat(677,20000:end)))) + 20000 - 1;

    get_MODIS_elements_for_L2eqa_grid(MODIS_lat(:,iEq), MODIS_lon(:,iEq));
end

%% Average SST, lat and lon for each cell in the new 10x10 km grid.

lonThreshold = 180;

numNewPixsm = length(pixStartm);
for iPix=1:numNewPixsm
    jScanLine = 0;
    for iScanLine=1:10:size(MODIS_SST,2)-10
        jScanLine = jScanLine + 1;
        L2eqa_MODIS_SST(numNewPixsm-iPix+1,jScanLine) = mean(MODIS_SST(pixStartm(iPix):pixEndm(iPix),iScanLine:iScanLine+10),'all','omitnan');
        
        L2eqaLon(numNewPixsm-iPix+1,jScanLine) = mean(MODIS_lon(pixStartm(iPix):pixEndm(iPix),iScanLine:iScanLine+10),'all','omitnan');
        L2eqaLat(numNewPixsm-iPix+1,jScanLine) = mean(MODIS_lat(pixStartm(iPix):pixEndm(iPix),iScanLine:iScanLine+10),'all','omitnan');
    end
end

numNewPixsp = length(pixStartp);
for iPix=1:numNewPixsp
    jScanLine = 0;
    for iScanLine=1:10:size(MODIS_SST,2)-10
        jScanLine = jScanLine + 1;
        L2eqa_MODIS_SST(numNewPixsp + iPix,jScanLine) = mean(MODIS_SST(pixStartp(iPix):pixEndp(iPix),iScanLine:iScanLine+10),'all','omitnan');
        
        L2eqaLon(numNewPixsp + iPix,jScanLine) = mean(MODIS_lon(pixStartp(iPix):pixEndp(iPix),iScanLine:iScanLine+10),'all','omitnan');
        L2eqaLat(numNewPixsp + iPix,jScanLine) = mean(MODIS_lat(pixStartp(iPix):pixEndp(iPix),iScanLine:iScanLine+10),'all','omitnan');
    end
end

%% Finally regrid AMSR-E to the L2eqa grid and L2eqa_MODIS_SST to the AMSR-E grid

L2eqa_AMSR_E_SST = griddata( AMSR_E_lon, AMSR_E_lat, AMSR_E_SST, L2eqaLon, L2eqaLat, 'natural');

MODIS_SST_on_AMSR_E_grid = griddata( L2eqaLon, L2eqaLat, L2eqa_MODIS_SST, AMSR_E_lon, AMSR_E_lat,'natural');

toc

lastpt = 0;



