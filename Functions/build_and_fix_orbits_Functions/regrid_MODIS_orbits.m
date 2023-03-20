function [ status, new_lon, new_lat, new_sst, region_start, region_end,  easting, northing, new_easting, new_northing] = ...
    regrid_MODIS_orbits( regrid_sst, augmented_weights, augmented_locations, longitude, latitude, SST_In)
%  regrid_MODIS_orbits - regrid MODIS orbit - PCC
%
% INPUT
%   regrid_sst - if 1 will regrid SST. If 0 will just determine new
%    latitudes and longitudes, which involves simple interpolations along
%    the track line; no need for griddate.
%   augmented_weights - weights used for fast regridding of SST. If empty,
%    will skip do 'slow' regridding. Fast regridding uses weights and
%    locations to determine regridded SST values; simple multiplications
%    instead of using griddata, which can be painfully slow.
%   augmented_locations - used with augmented weights for fast regridding.
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

global iOrbit oinfo iGranule problem_list
global scan_line_times start_line_index num_scan_lines_in_granule sltimes_avg nlat_avg
global latlim secs_per_day secs_per_orbit secs_per_scan_line orbit_length npixels

% Initialize return variables.

status = 0;

% Initialize other variables.

Debug = 0;

if Debug
    tic_regrid_start = tic;
end

if regrid_sst == 1
    if isempty(augmented_weights)
        in_loop = 0;
    else
        in_loop = -1;  % Set to -1 to use fast regridding **************************
    end
else
    in_loop = -999;
end

% Get the data

% load('~/Dropbox/Data/canonical_orbit/Orbit_2010_06_19', 'longitude', 'latitude', 'SST_In')
% load ~/Dropbox/Data/canonical_orbit/Orbit_2010_06_19
%   fi_in - fully specified the input netCDF filename.
% load(fi_in)

[mpixels nscans] = size(longitude);

if mpixels ~= npixels
    fprintf('***** There are %i pixels/scan line in this granule but there should be %i. Skipping this granule. Error code 3.\n', mpixels, npixels)
    
    status = populate_problem_list( 3, fi_granule);
    return
end

dummy_scans = reshape([1:10*npixels], npixels, 10);

% % new_lat = nan(size(latitude));
% % new_lon = nan(size(longitude));

num_detectors = 10;
num_steps = num_detectors - 1;

%% Next find the four sections of this orbit. 

% Assume that the orbits start descending at 75 S. The orbit will be broken 
% up into 4 sections:
%   1) scan lines with nadir values south of 75 S east-to-west,
%   2) lines with nadir values ascending from 75 S to 75 N,
%   3) lines with nadir values north of 75 N east-to-west and
%   4) lines with nadir values from 75 N descending to 75 S.

latn = latitude(677,:);  % Latitude of the nadir track. 

% First the part near the beginning of the orbit.

north_lat_limit = 75;
south_lat_limit = -75;

nn = find(latn(1:floor(nscans/4)) < south_lat_limit); 

region_start(1) = 1;
region_end(1) = floor(nn(end)/10) * 10;

nn = find(latn(1:end) > north_lat_limit);

region_start(2) = region_end(1) + 1;
region_end(2) = floor(nn(1) / 10) * 10;

region_start(3) = region_end(2) + 1;
region_end(3) = floor(nn(end) / 10) * 10;

region_start(4) = region_end(3) + 1;
region_end(4) = nscans-1;

if Debug
    disp(['Regions to process'])
    for iRegion=1:4
        disp([' Region ' num2str(iRegion) ': ' num2str(region_start(iRegion)) ' to ' num2str(region_end(iRegion)) ])
    end
    disp([' '])
end

%% Preallocate output arrays

new_lon = nan(size(longitude));
new_lat = new_lon;
new_sst = single(new_lon);

easting = single(new_lon);
northing = single(new_lon);

new_easting = single(new_lon);
new_northing = single(new_lon);

%% Now regrid segment 1

% Start by converting from lat,lon to easting, northing. Note that the
% conversion goes one line beyond the end. That's to get the corresponding
% line of the next cycle (10 detector set) beyond the end.

scans_to_do = [region_start(1):region_end(1)+1];
[easting(:,scans_to_do), northing(:,scans_to_do)] = ll2ps(latitude(:,scans_to_do), longitude(:,scans_to_do));

% Do the scan lines up to the first complete set of 10 detectors.

mult = [0:9] / num_detectors;

scans_this_section = [];
for iScan=region_start(1):num_detectors:region_end(1)-9
    if mod(iScan,101) == 0 & Debug
        disp(['Am working on scan ' num2str(iScan) ' at time ' num2str(toc(tic_regrid_start))])
    end
    
    northing_separation = northing(:,iScan+10) - northing(:,iScan);
    easting_separation  = easting(:,iScan+10)  - easting(:,iScan);
    
    iScanVec = [iScan:iScan+9];
    scans_this_section = [scans_this_section iScanVec];
    
    new_northing(:,iScanVec) = northing(:,iScan) + northing_separation * mult;
    new_easting(:,iScanVec)  = easting(:,iScan)  + easting_separation  * mult;
    
    if in_loop == 1
%         new_sst(:,iScanVec) = griddata(double(easting(:,iScanVec)), double(northing(:,iScanVec)), double(SST_In(:,iScanVec)), double(new_easting(:,iScanVec)), double(new_northing(:,iScanVec)), 'nearest');
        nn_reorder = griddata(double(easting(:,iScanVec)), double(northing(:,iScanVec)), dummy_scans, double(new_easting(:,iScanVec)), double(new_northing(:,iScanVec)), 'nearest');
        
        temp = SST_In(:,iScanVec);
        new_sst(:,iScanVec) = temp(nn_reorder);        
    end
end

if in_loop==0
    xx = double(easting(:,scans_this_section)); 
    yy = double(northing(:,scans_this_section));
    ss = double(SST_In(:,scans_this_section));
    
    pp = find(isnan(xx) == 0);

    new_sst(:,scans_this_section) = griddata( xx(pp), yy(pp), ss(pp), double(new_easting(:,scans_this_section)), double(new_northing(:,scans_this_section)), 'natural');
end

% And convert from polar to lat, lon.

[new_lat(:,scans_this_section), new_lon(:,scans_this_section)] = ps2ll(new_easting(:,scans_this_section), new_northing(:,scans_this_section));

% % toc

%% Regrid segments 2 and 4.

for iSection=[2,4]
    if Debug
        disp(['Doing section ' num2str(iSection) ': ' num2str(toc(tic_regrid_start))])
        disp(' ')
    end
    
    imult = [0:9] / num_detectors;
    
    scans_this_section = [];
    for iScan=region_start(iSection):num_detectors:region_end(iSection)-9
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
                
        if in_loop == 1
            nn_reorder = griddata( double(longitude(:,iScanVec)), double(latitude(:,iScanVec)), dummy_scans, new_lon(:,iScanVec), new_lat(:,iScanVec), 'nearest');
            
            temp = SST_In(:,iScanVec);
            new_sst(:,iScanVec) = temp(nn_reorder);
        end
    end
    
    % And add the last scan line in the orbit (Section 4). It will be
    % very nearly unaffected by the bowtie effect since it it a middle
    % detector in the set of 10.
        
    if iSection == 4
        new_lat(:,end) = latitude(:,end);
        new_lon(:,end) = longitude(:,end);
        
        if in_loop == 1
            new_sst(:,end) = SST_In(:,end);
        end
    end
    
    % Regrid SST.
    
    if in_loop==0
        xx = double(longitude(:,scans_this_section));
        yy = double(latitude(:,scans_this_section));
        ss = double(SST_In(:,scans_this_section));
        
        pp = find(isnan(xx) == 0);
        
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
    
    if in_loop == 1
%         new_sst(:,iScan:iScan+9) = griddata(double(easting(:,iScanVec)), double(northing(:,iScanVec)), double(SST_In(:,iScanVec)), double(new_easting(:,iScanVec)), double(new_northing(:,iScanVec)), 'nearest');
        nn_reorder = griddata(double(easting(:,iScanVec)), double(northing(:,iScanVec)), dummy_scans, double(new_easting(:,iScanVec)), double(new_northing(:,iScanVec)), 'nearest');
        
        temp = SST_In(:,iScanVec);
        new_sst(:,iScanVec) = temp(nn_reorder);
    end
end

[new_lat(:,scans_this_section), new_lon(:,scans_this_section)] = psn2ll(new_easting(:,scans_this_section), new_northing(:,scans_this_section));

if in_loop==0
    xx = double(easting(:,scans_this_section)); 
    yy = double(northing(:,scans_this_section));
    ss = double(SST_In(:,scans_this_section));
    
    pp = find(isnan(xx) == 0);

    new_sst(:,scans_this_section) = griddata( xx(pp), yy(pp), ss(pp), double(new_easting(:,scans_this_section)), double(new_northing(:,scans_this_section)), 'natural');
end

%% Regrid SST using fast grid if requested.

if in_loop == -1
    
    [nElements, nScans] = size(SST_In);
    [nMax, mElements, mScans] = size(augmented_weights);
    
    % Truncate weights array to same number of scan lines as SST array.
    
    weights = augmented_weights(:,:,1:nScans);
    locations = augmented_locations(:,:,1:nScans);
    
    % Now regrid.
    
    new_sst = zeros([nElements, nScans]);
    
    for iC=1:nMax
        weights_temp = squeeze(weights(iC,:,:));
        locations_temp = squeeze(locations(iC,:,:));
        
        non_zero_weights = find(weights_temp ~= 0);
        
        SST_temp = zeros([nElements, nScans]);
        SST_temp(non_zero_weights) = weights_temp(non_zero_weights) .* SST_In(locations_temp(non_zero_weights));
        
        new_sst = new_sst + SST_temp;
    end
end

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