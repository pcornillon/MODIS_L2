function [ status, new_lon, new_lat, new_sst, region_start, region_end,  easting, northing, new_easting, new_northing] = ...
    regrid_MODIS_orbits( regrid_sst, longitude, latitude, SST_In)
% % %     regrid_MODIS_orbits( regrid_sst, augmented_weights, augmented_locations, longitude, latitude, SST_In)
%  regrid_MODIS_orbits - regrid MODIS orbit - PCC
%
% INPUT
%   regrid_sst - if 1 will regrid SST. If 0 will just determine new
%    latitudes and longitudes, which involves simple interpolations along
%    the track line; no need for griddate.
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
% EXAMPLE
%  ........
%   fi_in = '~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Original/2010/AQUA_MODIS.20100619T000124.L2.SST.mat';
%   regrid_MODIS_orbits( fi_in, [])

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

% % % % regridding_mode is used to tell the remainder of this function what to do:
% % % %
% % % % regridding_mode = 1 - determine new lat, lon grid and regrid SST to it 
% % % %                   using griddata. Regridding is done after all of the new
% % % %                   grid points have been determined for the given region.
% % % % regridding_mode = 2 - determine new lat, lon grid and regrid SST to it 
% % % %                   using fast regridding. Regridding is done after all of 
% % % %                   the newgrid points have been determined for the given 
% % % %                   region.
% % % % regridding_mode = 3 - determine new lat, lon grid and regrid SST to it 
% % % %                   using fast regridding. Regridding is done for each
% % % %                   group of 10 detectors.
% % % % regridding_mode = 0 - determine new lat, lon grid but don't regrid SST.
% % % 
% % % if regrid_sst == 1
% % %     if isempty(augmented_weights)
% % %         regridding_mode = 1;
% % %     else
% % %         regridding_mode = 2;  % Set to -1 to use fast regridding **************************
% % %     end
% % % else
% % %     regridding_mode = 0;
% % % end

% Get the data

[mpixels nscans] = size(longitude);

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

%% Recast longitude to not go from -180 to + 180

% Start by fixing the along-scan direction. Get the separation of longitude values in the along-scan direction.

difflon = diff(longitude);

% Find pixel locations where it changes sign by more than
% lon_step_threshold degrees, whic is set to 190 for now.

lon_step_threshold = 190;

[ipix, jpix] = find( abs(difflon) > lon_step_threshold);

% If found some longitudes with large changes, fix them.

if ~isempty(jpix)

    % Check that it doesn't change twice on the same line.

    diffjpix = diff(jpix);
    nn = find(abs(diffjpix) < 0.5);
    if ~isempty(nn)
        iProblem = 301;
        status = populate_problem_list( iProblem, ['Too many large longitudinal changes for scan line ' num2str(jpix(nn(1)))]);
        for inn=1:nn
            fprintf('  *** Too many large longitudinal changes for scan line %i\n', jpix(nn(inn)))
        end
    end

    % Add 360 degrees to all negative values on those lines where it changes dramatically.

    for j=1:length(jpix)
        xx = longitude(:,jpix(j));
        xx(xx<0) = xx(xx<0) + 360;

        longitude(:,jpix(j)) = xx;
    end
end

% Now fix the along-track direction.

indN1 = 19200;
indN2 = 19300;

latNadir = latitude(677,:);

diffcol = diff(longitude, 1, 2);

for iCol=1:mpixels

    xx = longitude(iCol,:);

    [~, jpix] = find( abs(diffcol(iCol,:)) > lon_step_threshold);

    if ~isempty(jpix)

        % % % [xx] = fix_lon_at_poles( xx, jpix);

        for kPix=1:length(jpix)
            lonStep(kPix) = -sign(xx(jpix(kPix)+1) - xx(jpix(kPix))) * 360;
        end

        if ~isempty(jpix)

            % Now get steps excluding ones between indN1 and indN2
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

        longitude(iCol,:) = xx;
    end
end

% Now fix problem, which results in very large values. This appears to
% occur at the seam between large negative and large positive values
% resulting when the scan line crosses the 90 S. Just in case do the same
% if the value is very negative.

nn = find(longitude > 360);
longitude(nn) = longitude(nn) - 360;

nn = find(longitude < -360);
longitude(nn) = longitude(nn) + 360;

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
        scans_to_do = [region_start(iSection):region_end(iSection)+1];
    else
        scans_to_do = [region_start(iSection):region_end(iSection)];
    end
    
    [easting(:,scans_to_do), northing(:,scans_to_do)] = ll2psn(latitude(:,scans_to_do), longitude(:,scans_to_do));

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

    % And add the last scan line in the orbit (Section 5). It will be
    % very nearly unaffected by the bowtie effect since it it a middle
    % detector in the set of 10.
        
    if iSection == 5
        new_lat(:,end) = latitude(:,end);
        new_lon(:,end) = longitude(:,end);        
    end

    % Now regrid using easting and northing.
    
% % %     if regridding_mode==1
        xx = double(easting(:,scans_this_section));
        yy = double(northing(:,scans_this_section));
        ss = double(SST_In(:,scans_this_section));

        % % pp = find(isnan(xx) == 0);
        pp = find(isnan(ss) == 0);

        if length(pp) == 0
            fprintf('...All SST_In values in Section %i are nan for orbit %s.\n', iSection, oinfo(iOrbit).name)

            status = populate_problem_list( 1001, ['All SST_In values in Section ' num2str(iSection) ' are nan for orbit ' oinfo(iOrbit).name], '');
        else
            new_sst(:,scans_this_section) = griddata( xx(pp), yy(pp), ss(pp), double(new_easting(:,scans_this_section)), double(new_northing(:,scans_this_section)), 'natural');
        end
% % %     end

    % And convert from polar to lat, lon.

    [new_lat(:,scans_this_section), new_lon(:,scans_this_section)] = psn2ll(new_easting(:,scans_this_section), new_northing(:,scans_this_section));

    % Fix the longitude jump introduced by psn2ll. (19250 corresponds to the
    % highest latitude reached by the satellite-the nadir track.)

    aa = new_lon(:,region_start(iSection):region_end(iSection));
    rr = find(aa<0); 
    aa(rr) = aa(rr) + 360;
    new_lon(:,region_start(iSection):region_end(iSection)) = aa;

    clear aa
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
    
% % %     if regridding_mode==1
        xx = double(longitude(:,scans_this_section));
        yy = double(latitude(:,scans_this_section));
        ss = double(SST_In(:,scans_this_section));
        
        % % pp = find(isnan(xx) == 0);
        pp = find(isnan(ss) == 0);

        if length(pp) == 0
            fprintf('...All SST_In values in Section 2 or 4 are nan for orbit %s.\n', oinfo(iOrbit).name)

            status = populate_problem_list( 1002, ['All SST_In values in Section 2 or 4 are nan for orbit ' oinfo(iOrbit).name], '');
        else
            new_sst(:,scans_this_section) = griddata( xx(pp), yy(pp), ss(pp), double(new_lon(:,scans_this_section)), double(new_lat(:,scans_this_section)), 'natural');
        end
% % %     end

    % % % if regrid_to_AMSRE
    % % %     regrid_AMSRE( longitude(:,scans_this_section), latitude(:,scans_this_section), new_sst(:,scans_this_section))
    % % % end

    % % % % % %% Fix problem with longitude going from one side of the dateline to the other.
    % % % % % 
    % % % % % diff_lon = diff(longitude);
    % % % % % [icdl, jcdl] = find(abs(diff_lon) > 10);
    % % % % % 
    % % % % % Range = 5;
    % % % % % 
    % % % % % for iScan=region_start(iSection):region_end(iSection)
    % % % % %     nn = find(jcdl == iScan);
    % % % % % 
    % % % % %     if ~isempty(nn)
    % % % % % 
    % % % % %         fix_start = min(icdl(nn));
    % % % % %         fix_end = max(icdl(nn));
    % % % % % 
    % % % % %         % Do not fix if the dateline is near (within 5 pixels) of the 
    % % % % %         % beginning or the end of the scanline.
    % % % % % 
    % % % % %         if (fix_start > Range) & (fix_end < size(new_sst,1)-Range)
    % % % % % 
    % % % % %             % Do not fix if new_sst is nan to Range (nominally 5)
    % % % % %             % pixels on either side of the identified range.  
    % % % % % 
    % % % % %             nn = find(isnan(new_sst(fix_start-Range:fix_start-1, iScan))==0);
    % % % % %             mm = find(isnan(new_sst(fix_end+1:fix_end+Range, iScan))==0);
    % % % % % 
    % % % % %             fix_start = fix_start - Range + max(nn);
    % % % % %             fix_end = fix_end + min(mm) - 1;
    % % % % % 
    % % % % %             if (isnan(new_sst(fix_start-1, iScan)) == 0) & (isnan(new_sst(fix_end+1, iScan))== 0)
    % % % % %                 num_fill = fix_end - fix_start + 1;
    % % % % % 
    % % % % %                 step_size = new_sst(fix_end+1, iScan) - new_sst(fix_start-1, iScan);
    % % % % %                 pixel_step_size = step_size / (num_fill + 1);
    % % % % % 
    % % % % %                 for iElement=fix_start:fix_end
    % % % % % 
    % % % % %                     % Only fill this element if it is a nan in new_sst.
    % % % % %                     % This happens when the orbit is bending over at high
    % % % % %                     % latitudes. Could get fancy and fill between the
    % % % % %                     % pixels that have legit values but this occurs rarely
    % % % % %                     % in the orbit and it's not clear how much fixing it
    % % % % %                     % helps at these locations.
    % % % % % 
    % % % % %                     if isnan(new_sst(iElement,iScan))
    % % % % %                         new_sst(iElement, iScan) = new_sst(fix_start-1, iScan) + pixel_step_size * (iElement - (fix_start - 1));
    % % % % %                     end
    % % % % %                 end
    % % % % %             end
    % % % % %         end
    % % % % %     end
    % % % % % end
end

%% Do Section 3.

iSection = 3;

if Debug
    disp(['Doing section ' num2str(iSection) ': ' num2str(toc)])
    disp(' ')
end

% % clear easting northing new_easting new_northing

scans_to_do = [region_start(iSection):region_end(iSection)+1];

[easting(:,scans_to_do), northing(:,scans_to_do)] = ll2psn(latitude(:,scans_to_do), longitude(:,scans_to_do));

% % scans_to_do = [region_start(iSection):num_detectors:region_end(iSection)];

mult = [0:9] / num_detectors;

scans_this_section = [];
for iScan=region_start(iSection):num_detectors:region_end(iSection)-9
    if mod(iScan,101) == 0 & Debug
        disp(['Am working on scan ' num2str(iScan) ' at time ' num2str(toc)])
    end
    
    northing_separation = northing(:,iScan+10) - northing(:,iScan);
    easting_separation = easting(:,iScan+10) - easting(:,iScan);
    
    iScanVec = [iScan:iScan+9];
    scans_this_section = [scans_this_section iScanVec];
    
    new_northing(:,iScanVec) = northing(:,iScan) + northing_separation * mult;
    new_easting(:,iScanVec) = easting(:,iScan) + easting_separation * mult;
end

[new_lat(:,scans_this_section), new_lon(:,scans_this_section)] = psn2ll(new_easting(:,scans_this_section), new_northing(:,scans_this_section));

% Fix the longitude jump introduced by psn2ll. (19250 corresponds to the
% highest latitude reached by the satellite-the nadir track.)

aa = new_lon(:,region_start(3):19250);
rr = find(aa<0);
aa(rr) = aa(rr) + 360;
new_lon(:,region_start(3):19250) = aa;

clear aa

% Now regrid using easting and northing.

% % % if regridding_mode==1
    xx = double(easting(:,scans_this_section)); 
    yy = double(northing(:,scans_this_section));
    ss = double(SST_In(:,scans_this_section));

    % % pp = find(isnan(xx) == 0);
    pp = find(isnan(ss) == 0);

    if length(pp) == 0
        fprintf('...All SST_In values in Sections 3 are nan for orbit %s.\n', oinfo(iOrbit).name)

        status = populate_problem_list( 1003, ['All SST_In values in Section 3 are nan for orbit ' oinfo(iOrbit).name], '');
    else
        new_sst(:,scans_this_section) = griddata( xx(pp), yy(pp), ss(pp), double(new_easting(:,scans_this_section)), double(new_northing(:,scans_this_section)), 'natural');
    end
% % % end

% % % %% Regrid SST using fast grid if requested.
% % % 
% % % if regridding_mode == 2
% % % 
% % %     [nElements, nScans] = size(SST_In);
% % %     [nMax, mElements, mScans] = size(augmented_weights);
% % % 
% % %     % Truncate weights array to same number of scan lines as SST array.
% % %     
% % %     weights = augmented_weights(:,:,1:nScans);
% % %     locations = augmented_locations(:,:,1:nScans);
% % %     
% % %     % Now regrid.
% % %     
% % %     new_sst = zeros([nElements, nScans]);
% % %     
% % %     for iC=1:nMax
% % %         weights_temp = squeeze(weights(iC,:,:));
% % %         locations_temp = squeeze(locations(iC,:,:));
% % %         
% % %         non_zero_weights = find((weights_temp ~= 0) & (isnan(weights_temp) == 0));
% % % 
% % %         SST_temp = zeros([nElements, nScans]);
% % %         SST_temp(non_zero_weights) = weights_temp(non_zero_weights) .* SST_In(locations_temp(non_zero_weights));
% % %         
% % %         new_sst = new_sst + SST_temp;
% % %     end
% % % end

% Add 1 to region_end(end), generally region_end(4). This is because the
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