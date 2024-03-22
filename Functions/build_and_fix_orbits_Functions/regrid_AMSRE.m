function [outputArg1,outputArg2] = regrid_AMSRE( MODIS_fi, AMSR_E_baseDir, MODIS_lon, MODIS_lat, MODIS_sst)
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
%   MODIS_sst - regridded of MODIS.
%
% OUTPUT
%   L3_lon - new L3 longitude grid
%   L3_lat - new L3 latitude grid
%
%   AMSRE_L3_sst - AMSR-E SST regridded to the L3 grid
%
%   AMSRE_L2_lon - original AMSR-E longitude
%   AMSRE_L2_lat - original AMSR-E latitude
%   AMSRE_L2_sst - original AMSR-E SST
%
%
%   MODIS_L2_sst - MODIS SST regridded to the AMSR-E L2 grid
%   MODIS_L3_sst - MODIS SST regridded to the L3 grid

% Get the AMSR-E data. Start by determining the correct AMSR-E orbit. 

% The first AMSR-E orbit with data, orbit #416, starts at 01-Jun-2002
% 19:05:19 or Matlab time 731368.7953587963. The average time for one orbit
% is: 98.863071 minutes. Given the NASA orbit number of this MODIS orbit--
% oinfo.ginfo(end).NASA_orbit_number--we can guess at the name of the
% corresponding AMSR-E orbit and we can check that the start times of the
% AMSR-E and MODIS orbits are similar.

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

AMSR_E_lat = ncread( AMSR_E_fi, 'lat');
AMSR_E_lon = ncread( AMSR_E_fi, 'lon');

% % % MODIS_lonnadir = MODIS_lon(677,:);
% % % MODIS_latnadir = MODIS_lat(677,:);

% Get the closes equatorial crossing of the nadir track on the descending
% portion of the orbit.

iEq = find( min(abs(squeeze(MODIS_lat(677,20000:end)))) == abs(squeeze(MODIS_lat(677,20000:end)))) + 20000 - 1;

% % % figure(1)
% % % clf
% % % 
% % % plot( MODIS_lonnadir, MODIS_latnadir, '.k')
% % % hold on
% % % 
% % % for i=0:10
% % %     plot(MODIS_lon(:,nn(3)+i), MODIS_lat(:,nn(3)+i), '.b')
% % % end

% Build the L2eqa grid.

pixsPerScan = size(MODIS_lon,1);

scanMODIS_lon = MODIS_lon(1:677,iEq);
scanMODIS_lon(678) = mean(squeeze(MODIS_lon(677:678,iEq)));
scanMODIS_lon(679:pixsPerScan+1) = MODIS_lon(678:pixsPerScan,iEq);

scanMODIS_lat = MODIS_lat(1:677,iEq);
scanMODIS_lat(678) = mean(squeeze(MODIS_lat(677:678,iEq)));
scanMODIS_lat(679:pixsPerScan+1) = MODIS_lat(678:pixsPerScan,iEq);

% % % centerLon = mean(scanMODIS_lon(677:678));
% % % centerLat = mean(scanMODIS_lat(677:678));

lonSep = diff(scanMODIS_lon);
latSep = diff(scanMODIS_lat);
pixSep = sqrt(lonSep.^2 + latSep.^2) * 111;

dist2nadir(677:-1:1) = cumsum(pixSep(677:-1:1));
dist2nadir(678:pixsPerScan) = cumsum(pixSep(678:pixsPerScan));

for iDist=10:10:1162
    jDist = iDist / 10;

    nn = find(dist2nadir(1:pixsPerScan/2) >= iDist-10 & dist2nadir(1:pixsPerScan/2) < iDist); 
    num2avgm(jDist) = length(nn);
    pixStartm(jDist) = nn(1);
    pixEndm(jDist) = nn(end);
    
    numPixElmnts = length(nn);
    if rem(numPixElmnts,2)
        pixSubStartm(jDist) = nn(ceil(numPixElmnts / 2));
        pixSubEndm(jDist) = pixSubStartm(jDist);
    else
        pixSubStartm(jDist) = nn(numPixElmnts / 2);
        pixSubEndm(jDist) = nn(numPixElmnts / 2) + 1;
    end
end

for iDist=10:10:1162
    jDist = iDist / 10;

    nn = find(dist2nadir(pixsPerScan/2+1:end) >= iDist-10 & dist2nadir(pixsPerScan/2+1:end) < iDist);
    num2avgp(jDist) = length(nn);
    pixStartp(jDist) = nn(1) + pixsPerScan/2;
    pixEndp(jDist) = nn(end) + pixsPerScan/2;
    
    numPixElmnts = length(nn);
    if rem(numPixElmnts,2)
        pixSubStartp(jDist) = nn(ceil(numPixElmnts / 2));
        pixSubEndp(jDist) = pixSubStartp(jDist);
    else
        pixSubStartp(jDist) = nn(numPixElmnts / 2);
        pixSubEndp(jDist) = nn(numPixElmnts / 2) + 1;
    end
end

% % longitude = MODIS_lon;
% % threshold = 180;
% % corrected_longitude = longitude;
% % 
% % % Detect and correct discontinuities for each scan line
% % for i = 1:size(longitude, 2)
% %     % Compute differences with wrapping at 360 degrees
% %     differences = diff([longitude(1, i); longitude(:, i)]);  % Include the first element for proper diff calculation
% %     jump_indices = find(abs(differences) > threshold);
% %     
% %     % Correct for each detected discontinuity
% %     for j = jump_indices
% %         if differences(j) > 0
% %             % Forward jump detected, subtract 360 from subsequent points
% %             corrected_longitude( j+1:end, i) = corrected_longitude( j+1:end, i) - 360;
% %         else
% %             % Backward jump detected, add 360 to subsequent points
% %             corrected_longitude( j+1:end, i) = corrected_longitude( j+1:end, i) + 360;
% %         end
% %     end
% % end

%% Now average SST.

lonThreshold = 180;

numNewPixsm = length(pixStartm);
for iPix=1:numNewPixsm
    jScanLine = 0;
    for iScanLine=1:10:size(MODIS_sst,2)-10
        jScanLine = jScanLine + 1;
        sstNew(numNewPixsm-iPix+1,jScanLine) = mean(MODIS_sst(pixStartm(iPix):pixEndm(iPix),iScanLine:iScanLine+10),'all','omitnan');
        
        L2eqaLat(numNewPixsm-iPix+1,jScanLine) = mean(MODIS_lat(pixSubStartm(iPix):pixSubEndm(iPix),iScanLine+4:iScanLine+5),'all','omitnan');
        
        lonElmnts = MODIS_lon(pixSubStartm(iPix):pixSubEndm(iPix),iScanLine+4:iScanLine+5);
        if (max(lonElmnts(:)) - min(lonElmnts(:))) > lonThreshold
                lonElmnts(lonElmnts<0) = lonElmnts(lonElmnts<0) + 360;
        end
        L2eqaLon(numNewPixsm-iPix+1,jScanLine) = mean(lonElmnts(:),'omitnan');
    end
end

numNewPixsp = length(pixStartp);
for iPix=1:numNewPixsp
    jScanLine = 0;
    for iScanLine=1:10:size(MODIS_sst,2)-10
        jScanLine = jScanLine + 1;
        sstNew(numNewPixsp + iPix,jScanLine) = mean(MODIS_sst(pixStartp(iPix):pixEndp(iPix),iScanLine:iScanLine+10),'all','omitnan');
        
        L2eqaLat(numNewPixsp + iPix,jScanLine) = mean(MODIS_lat(pixSubStartp(iPix):pixSubEndp(iPix),iScanLine+4:iScanLine+5),'all','omitnan');
        
        lonElmnts = MODIS_lon(pixSubStartp(iPix):pixSubEndp(iPix),iScanLine+4:iScanLine+5);
        if (max(lonElmnts(:)) - min(lonElmnts(:))) > lonThreshold
                lonElmnts(lonElmnts<0) = lonElmnts(lonElmnts<0) + 360;
        end
        L2eqaLon(numNewPixsp + iPix,jScanLine) = mean(lonElmnts(:),'omitnan');
    end
end

a = 180;
