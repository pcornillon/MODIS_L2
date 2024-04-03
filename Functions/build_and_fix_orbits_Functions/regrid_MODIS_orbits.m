function [ status, new_lon, new_lat, new_sst, region_start, region_end,  easting, northing, new_easting, new_northing, ...
    L2eqaLon, L2eqaLat, L2eqa_MODIS_SST, L2eqa_MODIS_std_SST, L2eqa_MODIS_num_SST, L2eqa_AMSR_E_SST, ...
    AMSR_E_lon, AMSR_E_lat, AMSR_E_SST, MODIS_SST_on_AMSR_E_grid] = ...
    regrid_MODIS_orbits( regrid_to_AMSRE, longitude, latitude, SST_In)
% % %     regrid_MODIS_orbits( regrid_sst, augmented_weights, augmented_locations, longitude, latitude, SST_In)
%  regrid_MODIS_orbits - regrid MODIS orbit - PCC
%
% INPUT
%   regrid_to_AMSRE - if 1 will read the corresponding AMSR-E orbit and
%    regrid to AMSR-E native AMSR-E and regrid both AMSR-E and MODIS to a
%    geogrid. In all cases will use regridded MODIS data.
% % % % %   augmented_weights - weights used for fast regridding of SST. If empty,
% % % % %    will skip do 'slow' regridding. Fast regridding uses weights and
% % % % %    locations to determine regridded SST values; simple multiplications
% % % % %    instead of using griddata, which can be painfully slow.
% % % % %   augmented_locations - used with augmented weights for fast regridding.
%   longitude - array to be fixed.
%   latitude - needed for high latitude locations.
%   base_dir_out - the directory to which the new lon, lat, SST_In and mask
%    will be writte. The output filename will the same as the input filename
%    with '_fixed' appended.
%
% OUTPUT
%   ...
%
% EXAMPLE
%  ........
%   fi_in = '~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Original/2010/AQUA_MODIS.20100619T000124.L2.SST.mat';
%   regrid_MODIS_orbits( fi_in, [])

global pixStartm pixEndm pixStartp pixEndp
global iOrbit oinfo nlat_orbit nlat_avg
global npixels

global determine_fn_size

% globals used in the other major functions of build_and_fix_orbits.

global iProblem problem_list

if determine_fn_size; get_job_and_var_mem; end

% Turn off warnings for duplicate values in griddata.

id = 'MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId';
warning('off',id)

% Initialize return variables.

status = 0;

% Initialize other variables.

Debug = 0;

if Debug
    tic_regrid_start = tic;
end

% Get the data

[mpixels, nscans] = size(longitude);

if mpixels ~= npixels
    fprintf('***** There are %i pixels/scan line in this granule but there should be %i. Skipping this granule. Error code 3.\n', mpixels, npixels)
    
    status = populate_problem_list( 3, fi_granule);
    return
end

dummy_scans = reshape([1:10*npixels], npixels, 10);

num_detectors = 10;
num_steps = num_detectors - 1;

%% Next find the four sections of this orbit.

% Assume that the orbits start ascending at 79 S. The orbit will be broken
% up into 5 sections:
%   1) scan lines with nadir values between 79 S and 75 S.
%   2) scan lines with nadir values ascending from 75 S to 75 N.
%   3) lines with nadir values 75 N to 75 N moving from west to east.
%   4) lines with nadir values from 75 N to 75 S, descending.
%   5) lines with nadir values from 75 S descending to the end of the orbit
%
% latitude will be empty where there are missing granules. Fill them in
% with the canonical orbit???

nn = find(isnan(nlat_orbit) == 1);

if ~isempty(nn)
    nlat_orbit(nn) = nlat_avg(nn-1);
end

% First, the part near the beginning of the orbit.

north_lat_limit = 75;
south_lat_limit = -75;

nn = find(nlat_orbit(1:floor(nscans/4)) < south_lat_limit);

region_start(1) = 1;
region_end(1) = floor(nn(end)/10) * 10;

nn = find(nlat_orbit(1:end) > north_lat_limit);

region_start(2) = region_end(1) + 1;
region_end(2) = floor(nn(1) / 10) * 10;

region_start(3) = region_end(2) + 1;
region_end(3) = floor(nn(end) / 10) * 10;

region_start(3) = region_end(2) + 1;
region_end(3) = floor(nn(end) / 10) * 10;

nn = find(nlat_orbit(region_end(3)+2:40271) < south_lat_limit) + region_end(3) + 1;

region_start(4) = region_end(3) + 1;
region_end(4) = floor(nn(1) / 10) * 10 - 1;

region_start(5) = floor(nn(1) / 10) * 10;
region_end(5) =  nscans-1;

if Debug
    disp(['Regions to process'])
    for iRegion=1:5
        disp([' Region ' num2str(iRegion) ': ' num2str(region_start(iRegion)) ' to ' num2str(region_end(iRegion)) ])
    end
    disp([' '])
end

%% Preallocate output arrays

new_lon = nan(mpixels, nscans);
new_lat = new_lon;
new_sst = single(nan(mpixels, nscans));

easting = single(new_lon);
northing = single(new_lon);

new_easting = single(new_lon);
new_northing = single(new_lon);

% % % %% Recast longitude to not go from -180 to + 180
% % %
% % % % % % % Start by fixing the along-scan direction. Get the separation of longitude values in the along-scan direction.
% % % % % %
% % % % % % difflon = diff(longitude);
% % %
% % % % Find pixel locations where it changes sign by more than
% % % % lon_step_threshold degrees, whic is set to 190 for now.
% % %
% % % lon_step_threshold = 190;
% % %
% % % % Now fix the along-track direction.
% % %
% % % % % indN1 = 19200;
% % % % % indN2 = 19300;
% % %
% % % indN1 = 18821;
% % % indN2 = 19681;
% % %
% % % diffcol = diff(longitude, 1, 2);
% % %
% % % for iCol=1:mpixels
% % %
% % %     xx = longitude(iCol,:);
% % %
% % %     [~, jpix] = find( abs(diffcol(iCol,:)) > lon_step_threshold);
% % %
% % %     if ~isempty(jpix)
% % %
% % %         % % % [xx] = fix_lon_at_poles( xx, jpix);
% % %
% % %         for kPix=1:length(jpix)
% % %             lonStep(kPix) = -sign(xx(jpix(kPix)+1) - xx(jpix(kPix))) * 360;
% % %         end
% % %
% % %         if ~isempty(jpix)
% % %
% % %             % Now get steps excluding ones between indN1 and indN2
% % %             llpix = find( (jpix<indN1) | (jpix>indN2) );
% % %             if ~isempty(llpix)
% % %                 jpix = jpix(llpix);
% % %                 lonStep = lonStep(llpix);
% % %             end
% % %         end
% % %
% % %         % If number of jpix elements is odd, add one more element
% % %         % corresponding to the number of scans in the orbit. We don't need
% % %         % to add the last lonStep, since it wouldn't be used.
% % %
% % %         if ~isempty(jpix)
% % %             if rem(length(jpix),2)
% % %                 jpix(length(jpix)+1) = length(xx);
% % %             end
% % %
% % %             for ifix=1:2:length(jpix)
% % %                 locs2fix = [jpix(ifix)+1:jpix(ifix+1)];
% % %
% % %                 xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
% % %             end
% % %         end
% % %
% % %         longitude(iCol,:) = xx;
% % %     end
% % % end
% % %
% % % % Now for scan lines.
% % %
% % % for iRow=1:nscans
% % %     xx = longitude(677:end,iRow);
% % %     diffrow = diff(xx);
% % %     ipix = find(abs(diffrow) > lon_step_threshold);
% % %     if ~isempty(ipix)
% % %         for kPix=1:length(ipix)
% % %             lonStep(kPix) = -sign(xx(ipix(kPix)+1) - xx(ipix(kPix))) * 360;
% % %         end
% % %         if rem(length(ipix),2)
% % %             ipix(length(ipix)+1) = length(xx);
% % %         end
% % %         for ifix=1:2:length(ipix)
% % %             locs2fix = [ipix(ifix)+1:ipix(ifix+1)];
% % %             xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
% % %         end
% % %     end
% % %     longitude(677:end,iRow) = xx;
% % % end
% % %
% % % for iRow=1:nscans
% % %     xx = longitude(1:677,iRow);
% % %     diffrow = diff(xx);
% % %     ipix = find(abs(diffrow) > lon_step_threshold);
% % %     if ~isempty(ipix)
% % %
% % %         % Reverse the order since we are going from nadir.
% % %
% % %         ipix = flip(ipix);
% % %
% % %         clear lonStep
% % %         for kPix=1:length(ipix)
% % %             if xx(ipix(kPix)+1) > xx(ipix(kPix))
% % %                 lonStep(kPix) = 360;
% % %             else
% % %                 lonStep(kPix) = -360;
% % %             end
% % %         end
% % %         if rem(length(ipix),2)
% % %             ipix(length(ipix)+1) = 1;
% % %         end
% % %         for ifix=1:2:length(ipix)
% % %             locs2fix = [ipix(ifix+1):ipix(ifix)];
% % %             xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
% % %         end
% % %     end
% % %     longitude(1:677,iRow) = xx;
% % % end
% % %
% % % % Now shift the entire longitude range if too positive or too negative.
% % %
% % % if min(longitude(:)) < -360
% % %     longitude = longitude + 360;
% % % elseif max(longitude) > 360
% % %     longitude = longitude - 360;
% % % end
% % %
% % % % Now move outliers, which seem to have escaped the above.
% % %
% % % [Values, Edges] = histcounts(longitude);
% % %
% % % nn = find(Values > 0);
% % %
% % % cc = 0;
% % % for jBin=nn(1):nn(end)
% % %     iBin = nn(1) + jBin - 1;
% % %
% % %     if Values(iBin) == 0
% % %         cc = cc + 1;
% % %         if cc > 10
% % %             edgeToUse = Edges(iBin);
% % %             break
% % %         end
% % %     else
% % %         cc = 0;
% % %     end
% % % end
% % %
% % % % If cc >= 10, it found a pretty long area with no values. That means that
% % % % there are likely outliers so we need to shift them.
% % %
% % % if cc >= 10
% % %     nn = find(longitude < edgeToUse);
% % %
% % %     % If the number of elements found is less than 1/2, then shift these
% % %     % up, otherwise find the ones > edgeToUse and shift them down.
% % %
% % %     if length(nn) < nscans * mpixels / 2
% % %         longitude(nn) = longitude(nn) + 360;
% % %     else
% % %         nn = find(longitude > edgeToUse);
% % %        longitude(nn) = longitude(nn) - 360;
% % %     end
% % % end
% % %
% % % if (min(longitude) < -360) | (max(longitude) > 360)
% % %     fprintf('Longitude values range from %f to %f, which is going to results in an error from ll2 function.\n', min(longitude), max(longitude))
% % % end

zz = longitude;
[longitude, nnSave, mmSave] = fix_lon_steps_and_constrain( 'fixSteps', zz);
clear zz

%% Now regrid segments 1 & 5

% Start by converting from lat,lon to easting, northing. Note that the
% conversion goes one line beyond the end for segment 1. That's to get the
% corresponding line of the next cycle (10 detector set) beyond the end.

for iSection=[1,5]
    if Debug
        disp(['Doing section ' num2str(iSection) ': ' num2str(toc(tic_regrid_start))])
        disp(' ')
    end
    
    if iSection == 1
        scans_this_section = [region_start(iSection):region_end(iSection)+1];
    else
        scans_this_section = [region_start(iSection):region_end(iSection)];
    end
    
    % % %     % longitude values can't be less than -360 or probably larger than 360
    % % %     % for the ll2p functions so will shift all values < -360 up by 360 and
    % % %     % those > 360 down by 360.
    % % %
    % % %     zz = longitude(:,scans_this_section);
    % % %
    % % %     nn = find(zz < -360);
    % % %     mm = find(zz > 360);
    % % %
    % % %     if ~isempty(nn)
    % % %         zz(nn) = zz(nn) + 360;
    % % %     end
    % % %
    % % %     if ~isempty(mm)
    % % %         zz(mm) = zz(mm) - 360;
    % % %     end
    % % %
    % % %     % Now move outliers, which seem to have escaped the above.
    % % %
    % % %     [Values, Edges] = histcounts(zz);
    % % %
    % % %     nn = find(Values > 0);
    % % %
    % % %     cc = 0;
    % % %     for jBin=nn(1):nn(end)
    % % %         iBin = nn(1) + jBin - 1;
    % % %
    % % %         if Values(iBin) == 0
    % % %             cc = cc + 1;
    % % %             if cc > 10
    % % %                 edgeToUse = Edges(iBin);
    % % %                 break
    % % %             end
    % % %         else
    % % %             cc = 0;
    % % %         end
    % % %     end
    % % %
    % % %     % If cc >= 10, it found a pretty long area with no values. That means that
    % % %     % there are likely outliers so we need to shift them.
    % % %
    % % %     if cc >= 10
    % % %         nn = find(zz < edgeToUse);
    % % %
    % % %         % If the number of elements found is less than 1/2, then shift these
    % % %         % up, otherwise find the ones > edgeToUse and shift them down.
    % % %
    % % %         if length(nn) < nscans * mpixels / 2
    % % %             zz(nn) = zz(nn) + 360;
    % % %         else
    % % %             nn = find(longitude > edgeToUse);
    % % %             zz(nn) = zz(nn) - 360;
    % % %         end
    % % %     end
    
    [lonArray, nnSave, mmSave] = fix_lon_steps_and_constrain( 'constrainLongitude', longitude(:,scans_this_section));
    
    % % %     [easting(:,scans_this_section), northing(:,scans_this_section)] = ll2psn(latitude(:,scans_this_section), lonArray);
    [easting(:,scans_this_section), northing(:,scans_this_section)] = ll2ps(latitude(:,scans_this_section), lonArray);
    
    % Do the scan lines up to the first complete set of 10 detectors.
    
    mult = [0:9] / num_detectors;
    
    scans_this_section = [];
    for iScan=region_start(iSection):num_detectors:region_end(iSection)-9
        if mod(iScan,101) == 0 & Debug
            disp(['Am working on scan ' num2str(iScan) ' at time ' num2str(toc(tic_regrid_start))])
        end
        
        northing_separation = northing(:,iScan+10) - northing(:,iScan);
        easting_separation  = easting(:,iScan+10)  - easting(:,iScan);
        
        iScanVec = [iScan:iScan+9];
        scans_this_section = [scans_this_section iScanVec];
        
        new_northing(:,iScanVec) = northing(:,iScan) + northing_separation * mult;
        new_easting(:,iScanVec)  = easting(:,iScan)  + easting_separation  * mult;
    end
    
    % Now regrid using easting and northing.
    
    xx = double(easting(:,scans_this_section));
    yy = double(northing(:,scans_this_section));
    ss = double(SST_In(:,scans_this_section));
    
    pp = find(isnan(xx) == 0);
    
    if (length(pp) == 0) | (isempty(find(isnan(ss) == 0)))
        status = populate_problem_list( 1001, ['All SST_In values in Section ' num2str(iSection) ' are nan for orbit ' oinfo(iOrbit).name], '');
    else
        new_sst(:,scans_this_section) = griddata( xx(pp), yy(pp), ss(pp), double(new_easting(:,scans_this_section)), double(new_northing(:,scans_this_section)), 'natural');
    end
    
    % And convert from polar to lat, lon.
    
    % % %     [new_lat(:,scans_this_section), new_lon(:,scans_this_section)] = psn2ll(new_easting(:,scans_this_section), new_northing(:,scans_this_section));
    [new_lat(:,scans_this_section), new_lon(:,scans_this_section)] = ps2ll(new_easting(:,scans_this_section), new_northing(:,scans_this_section));
    
    % And add the last scan line in the orbit (Section 5). It will be
    % very nearly unaffected by the bowtie effect since it it a middle
    % detector in the set of 10.
    
    if iSection == 5
        new_lat(:,end) = latitude(:,end);
        new_lon(:,end) = longitude(:,end);
    end
    
    
    % % %     % Now need to undo the shifting around that was done to accommodate ll2
    % % %
    % % %     zz = new_lon(:,scans_this_section);
    % % %
    % % %     if ~isempty(nn)
    % % %         zz(nn) = zz(nn) - 360;
    % % %     end
    % % %
    % % %     if ~isempty(mm)
    % % %         zz(mm) = zz(mm) + 360;
    % % %     end
    % % %
    % % %     if ~isempty(nn) | ~isempty(mm)
    % % %         new_lon(nn) = zz;
    % % %     end
    
    
    if ~isempty(nnSave) | ~isempty(mmSave)
        [lonArray, ~, ~] = fix_lon_steps_and_constrain( 'unconstrainLongitude', new_lon(:,scans_this_section));
    
        new_lon(:,scans_this_section) = lonArray;
    end
    
end

%% Regrid segments 2 and 4.

for iSection=[2,4]
    if Debug
        disp(['Doing section ' num2str(iSection) ': ' num2str(toc(tic_regrid_start))])
        disp(' ')
    end
    
    imult = [0:9] / num_detectors;
    
    scans_this_section = [];
    % for iScan=region_start(iSection):num_detectors:region_end(iSection)-9
    for iScan=region_start(iSection):num_detectors:region_end(iSection)
        if mod(iScan,1001) == 0 & Debug
            disp(['Am working on scan ' num2str(iScan) ' at time ' num2str(toc(tic_regrid_start))])
        end
        
        jScan = iScan;
        kScan = iScan + 10;
        
        lat_separation = latitude(:,kScan) - latitude(:,jScan);
        lon_separation = longitude(:,kScan) - longitude(:,jScan);
        
        iScanVec = [jScan:kScan-1];
        
        % Check to see if the first value in this goup has been changed. If
        % it has, it was decremented by one so remove the last scan line
        % reference from scans_this_section.
        
        if jScan == iScan
            scans_this_section = [scans_this_section iScanVec];
        else
            scans_this_section = [scans_this_section(1:end-1) iScanVec];
        end
        
        mult = [0:kScan-jScan-1] / (kScan - jScan);
        
        new_lat(:,iScanVec) = latitude(:,jScan) + lat_separation * mult;
        new_lon(:,iScanVec) = longitude(:,jScan) + lon_separation * mult;
    end
    
    % Regrid SST.
    
    xx = double(longitude(:,scans_this_section));
    yy = double(latitude(:,scans_this_section));
    ss = double(SST_In(:,scans_this_section));
    
    pp = find(isnan(xx) == 0);
    
    if (length(pp) == 0) | (isempty(find(isnan(ss) == 0)))
        fprintf('...All SST_In values in Section 2 or 4 are nan for orbit %s.\n', oinfo(iOrbit).name)
        
        status = populate_problem_list( 1002, ['All SST_In values in Section 2 or 4 are nan for orbit ' oinfo(iOrbit).name], '');
    else
        new_sst(:,scans_this_section) = griddata( xx(pp), yy(pp), ss(pp), double(new_lon(:,scans_this_section)), double(new_lat(:,scans_this_section)), 'natural');
    end
end

%% Do Section 3.

iSection = 3;

if Debug
    disp(['Doing section ' num2str(iSection) ': ' num2str(toc)])
    disp(' ')
end

% % clear easting northing new_easting new_northing

scans_this_section = [region_start(iSection):region_end(iSection)+1];

% longitude values can't be less than -360 or probably larger than 360
% for the ll2p functions so will shift all values < -360 up by 360 and
% those > 360 down by 360.

[lonArray, nnSave, mmSave] = fix_lon_steps_and_constrain( 'constrainLongitude', longitude(:,scans_this_section));

% % % [new_lat(:,scans_this_section), new_lon(:,scans_this_section)] = psn2ll(new_easting(:,scans_this_section), new_northing(:,scans_this_section));
[easting(:,scans_this_section), northing(:,scans_this_section)] = ll2psn(latitude(:,scans_this_section), lonArray);

% % % % Fix the longitude jump introduced by psn2ll. (19250 corresponds to the
% % % % highest latitude reached by the satellite-the nadir track.)
% % %
% % % aa = new_lon(:,region_start(3):19250);
% % % rr = find(aa<-100);
% % % aa(rr) = aa(rr) + 360;
% % % new_lon(:,region_start(3):19250) = aa;
% % %
% % % clear aa

% Now regrid using easting and northing.

xx = double(easting(:,scans_this_section));
yy = double(northing(:,scans_this_section));
ss = double(SST_In(:,scans_this_section));

pp = find(isnan(xx) == 0);

if (length(pp) == 0) | (isempty(find(isnan(ss) == 0)))
    status = populate_problem_list( 1001, ['All SST_In values in Section 3 are nan for orbit ' oinfo(iOrbit).name], '');
else
    new_sst(:,scans_this_section) = griddata( xx(pp), yy(pp), ss(pp), double(new_easting(:,scans_this_section)), double(new_northing(:,scans_this_section)), 'natural');
end

% Convert regridded easting and northing back to longitude and latitude.

[new_lat(:,scans_this_section), new_lon(:,scans_this_section)] = psn2ll(new_easting(:,scans_this_section), new_northing(:,scans_this_section));

[lonArray, ~, ~] = fix_lon_steps_and_constrain( 'constrainLongitude', new_lon(:,scans_this_section));

if ~isempty(nnSave) | ~isempty(mmSave)
    new_lon(:,scans_this_section) = lonArray;
end

% Add 1 to region_end(end), generally region_end(5). This is because the
% scans in each subregion analyzed go from the middle scan line in one
% group of 10 detectors to the middle scan line in the next group of 10
% detectors. (These values are not changed in the regridding.) This means
% that there are 10n+1 scan lines in the entire orbit as opposed to 10 but
% to facilitate processiong, region_end(end) was set to the length of the
% orbit -1 above. Adding 1 here will reset it to the proper value.

region_end(end) = region_end(end) + 1;

if Debug
    disp(['Finished regridding after: ' num2str(toc(tic_regrid_start)) ' seconds.'])
end

% % % %% Now average MODIS SST to 10x10 km L2eqa grid
% % %
% % % % Get the elements to use in the regridding if this is the first orbit processed.
% % %
% % % if iOrbit == 1
% % %     iEq = find( min(abs(squeeze(new_lat(677,20000:end)))) == abs(squeeze(new_lat(677,20000:end)))) + 20000 - 1;
% % %
% % %     get_MODIS_elements_for_L2eqa_grid(new_lat(:,iEq), new_lon(:,iEq));
% % % end

%% Average SST, lat and lon for each cell in the new 10x10 km grid.

numNewPixsm = length(pixStartm);
for iPix=1:numNewPixsm
    jScanLine = 0;
    for iScanLine=1:10:size(new_sst,2)-10
        jScanLine = jScanLine + 1;
        tt = new_sst(pixStartm(iPix):pixEndm(iPix),iScanLine:iScanLine+10);
        kk = find(isnan(tt)==0);
        if isempty(kk)
            L2eqa_MODIS_SST(numNewPixsm-iPix+1,jScanLine) = nan;
            L2eqa_MODIS_std_SST(numNewPixsm-iPix+1,jScanLine) = single(nan);
            L2eqa_MODIS_num_SST(numNewPixsm-iPix+1,jScanLine) = int16(0);
        else
            tt = tt(kk);
            L2eqa_MODIS_SST(numNewPixsm-iPix+1,jScanLine) = mean(tt,'all','omitnan');
            L2eqa_MODIS_std_SST(numNewPixsm-iPix+1,jScanLine) = single(std(tt,[],'all','omitnan'));
            L2eqa_MODIS_num_SST(numNewPixsm-iPix+1,jScanLine) = int16(length(kk));
        end
        
        L2eqaLon(numNewPixsm-iPix+1,jScanLine) = mean(new_lon(pixStartm(iPix):pixEndm(iPix),iScanLine:iScanLine+10),'all','omitnan');
        L2eqaLat(numNewPixsm-iPix+1,jScanLine) = mean(new_lat(pixStartm(iPix):pixEndm(iPix),iScanLine:iScanLine+10),'all','omitnan');
    end
end

numNewPixsp = length(pixStartp);
for iPix=1:numNewPixsp
    jScanLine = 0;
    for iScanLine=1:10:size(new_sst,2)-10
        jScanLine = jScanLine + 1;
        tt = new_sst(pixStartp(iPix):pixEndp(iPix),iScanLine:iScanLine+10);
        kk = find(isnan(tt)==0);
        if isempty(kk)
            L2eqa_MODIS_SST(numNewPixsp + iPix,jScanLine) = nan;
            L2eqa_MODIS_std_SST(numNewPixsp + iPix,jScanLine) = single(nan);
            L2eqa_MODIS_num_SST(numNewPixsp + iPix,jScanLine) = int16(0);
        else
            tt = tt(kk);
            L2eqa_MODIS_SST(numNewPixsp + iPix,jScanLine) = mean(tt,'all','omitnan');
            L2eqa_MODIS_std_SST(numNewPixsp + iPix,jScanLine) = single(std(tt,[],'all','omitnan'));
            L2eqa_MODIS_num_SST(numNewPixsp + iPix,jScanLine) = int16(length(kk));
        end
        
        L2eqaLon(numNewPixsp + iPix,jScanLine) = mean(new_lon(pixStartp(iPix):pixEndp(iPix),iScanLine:iScanLine+10),'all','omitnan');
        L2eqaLat(numNewPixsp + iPix,jScanLine) = mean(new_lat(pixStartp(iPix):pixEndp(iPix),iScanLine:iScanLine+10),'all','omitnan');
    end
end

%% Finally regrid AMSR-E to the L2eqa grid and the 10x10 km MODIS SST to the AMSR-E grid

if regrid_to_AMSRE
    [  AMSR_E_lon, AMSR_E_lat, AMSR_E_SST, L2eqa_AMSR_E_SST, MODIS_SST_on_AMSR_E_grid] = ...
        regrid_AMSRE( L2eqaLon, L2eqaLat, L2eqa_MODIS_SST);
else
    AMSR_E_lat = nan;
    AMSR_E_lon = nan;
    AMSR_E_SST = nan;
    
    L2eqa_AMSR_E_SST = nan;
    MODIS_SST_on_AMSR_E_grid = nan;
end
