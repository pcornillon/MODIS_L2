function generate_weights_and_locations(pattern_in, num_in_range, restart)
% generate_weights_and_locations - does this for inputs to fix bow-tie - PCC
%
% This function reads in the longitudes, latitudes, regridded longitudes and
% regridded latitudes for an orbit. It then builds a 7x7 element array of
% zeros with 1 in the middle, the array centered on an input pixel and scan
% line location. It performs a griddata to the 31x31 regridded fields
% centered on the same point to determine which of these pixels is impacted
% by the input value at iPixel, iScan.
%
% INPUT
%   pattern_in - to use in directory search as follows: ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/03/AQUA_MODIS_orbit_*_' pattern_in '*']
%    generally it is YYYMMDDT but it could be something different in the
%    time range.
%   num_in_range - the number of orbits in the range found with the pattern_in.
%   restart - if present and set to 1, will read in the weights and
%    locations already processed, figure out which regions have been
%    completed and restart from there.
%
% OUTPUT
%  none - the results are saved in a mat file.
%
% EXAMPLE
%   generate_weights_and_locations('20100301T', 3)
%

test_run = 0;

% If restart has not been passed in, set it to 0.

if exist('restart') == 0
    restart = 0;
end

% Define some variables

in_size_x = 4;
in_size_y = 33;
out_size_x = 4;
out_size_y = 33;

% Turn off warnings for duplicate values in griddata.

id = 'MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId';
warning('off',id)

% Get the list of files for the pattern passed in. First, get year and month
% from the pattern.

Year = pattern_in(1:4);
Month = pattern_in(5:6);
Day = pattern_in(7:8);

if test_run
    filelist = dir(['~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/AQUA_MODIS_orbit_*' pattern_in '*']);
else
%     filelist = dir(['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/03/AQUA_MODIS_orbit_*' pattern_in '*']);
    filelist = dir(['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/' Year '/' Month '/AQUA_MODIS_orbit_*' pattern_in '*']);
end
numfiles = length(filelist);

file_step = floor(numfiles / num_in_range);

% Read in the data

for iFile=1:file_step:numfiles
    jFile = iFile;
    
    % Starting with orbit associated with iFile, step through the orbits
    % one by one searching for the first orbit for which weights and
    % locations have not already been found.

    while 1==1
        filename_in = [filelist(jFile).folder '/' filelist(jFile).name];
        
        nn = strfind(filename_in, 'orbit_');
        mm = strfind(filename_in, '.nc4');
        filename_out = ['~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/' filename_in(nn+6:mm-1) '_weights.mat'];
        
        if exist(filename_out) & (restart == 0)
            jFile = jFile + 1;
            
            if jFile > numfiles
                return
            end
        else
            break
        end
    end
    
    fprintf('Working on %s\n', filename_in)
    
    % Read in the data for this orbit.
    
    lat = single(ncread(filename_in, 'latitude'));
    regridded_lat = single(ncread(filename_in, 'regridded_latitude'));
    lon = single(ncread(filename_in, 'longitude'));
    regridded_lon = single(ncread(filename_in, 'regridded_longitude'));
    
    total_number_of_scan_lines = size(lat,2);
    
    % Are the data for this orbit good?
    
    nn = find(isnan(lat)==1);
    if ~isempty(nn)
        fprintf('Sorry but nans in this file; griddata does not like this. Returning\n')
        weights = nan;
        locations = nan;
        return
    end
    
    regions_to_process = [2, 4];
    
    if restart
        
        % Read in the weights and locations if this is a restart.
        
        load(filename_out)
        
        % OK, now find what has already been processed.
        
        nn = find(weights(1,677,:) ~= 0);
        
        if nn(end) == 1990
            regions_to_process = [2, 4];
        elseif nn(end) == 20080
            regions_to_process = [4];
        elseif nn(end) == total_number_of_scan_lines
            regions_to_process = [];
        else
            fprintf('Last scan line with data is: %i; should be either 1990, 20080 or %i\n', nn(end), total_number_of_scan_lines)
            break
        end
    else
        
        % Intialize output arrays.
        
        Num          =  int16( zeros(    size(lat)));
        weights      = single( zeros( 7, size(lat,1), size(lat,2)));
        locations    =  int32( zeros( 7, size(lat,1), size(lat,2)));

        Num_nn       =  int16( zeros(    size(lat)));
        weights_nn   = single( zeros( 6, size(lat,1), size(lat,2)));
        locations_nn =  int32( zeros( 6, size(lat,1), size(lat,2)));
    end
    
    % If this is a test run, redefine the input array.
    
    if test_run
        lat = lat(1:50,:);
        regridded_lat = regridded_lat(1:50,:);
        lon = lon(1:50,:);
        regridded_lon = regridded_lon(1:50,:);
    end
    
    % Make sure that there are no nans in the input.
    
    nn = find(isnan(lat)==1);
    if ~isempty(nn)
        fprintf('Sorry but nans in this file; griddata does not like this. Returning\n')
        weights = nan;
        locations = nan;
        return
    end
    
    % Define regions. overlap in the following is many scan lines before
    % and after the polar dividing lines to regrid. The reason for the
    % overlap is to avoid the problem of missing lats and lons needed to
    % determine the regridding right up to the line of interest--the polar
    % dividing line.
    
    iAntarcticStart = 1;
    iAntarcticEnd = 1990;
    
    iArcticStart = 20081;
    iArcticEnd = 22070;
    
    if (iAntarcticEnd ~= 1990) | (iArcticStart ~= 20081)
        fprintf('You have changed the value of either iAntarcticEnd and/or iArcticStart. These values are used in restart above so need to change them there as well.\n')
        break
    end
    
    overlap = 40;
    
    region_start(1) = iAntarcticStart;
    region_end(1) = iAntarcticEnd + overlap;
    
    region_start(2) = iAntarcticEnd + 1 - overlap;
    region_end(2) = iArcticStart - 1 + overlap;
    
    region_start(3) = iArcticStart - overlap;
    region_end(3) = iArcticEnd + overlap;
    
    region_start(4) = iArcticEnd + 1 - overlap;
    region_end(4) = total_number_of_scan_lines;
    
    % Set timer
    
    tStart = tic;
    
    % Now get the weights and locations; start with the Antarctic region at
    % the beginning of the orbit.
    
    %% Region 1 - Southern Ocean, will convert lats and lons to a polar grid with ll2ps and determine weights and location from this coordinate system.
    
    % If this run is not to be restart, process from Region 1.
    
    if restart == 0
        fprintf('Processing Region 1 of %s.\n', filename_in)
        
        % Get the data for this region.
        
        [xin, yin] = ll2ps( lat(:, region_start(1):region_end(1)), lon(:, region_start(1):region_end(1)));
        [xout, yout] = ll2ps( regridded_lat(:, region_start(1):region_end(1)), regridded_lon(:, region_start(1):region_end(1)));
        
        xin = double(xin);
        yin = double(yin);
        xout = double(xout);
        yout = double(yout);
        
        [nPixels, nScanlines] = size(yin);
        
        % Intialize output arrays for this region.
        
        tNum          =  int16( zeros( size(xin)));
        tweights      = single( zeros( 7, nPixels, nScanlines));
        tlocations    =  int32( zeros( 7, nPixels, nScanlines));
        
        tNum_nn       =  int16( zeros( size(xin)));
        tweights_nn   = single( zeros( 6, nPixels, nScanlines));
        tlocations_nn =  int32( zeros( 6, nPixels, nScanlines));
        
        for iPixel=1:nPixels
            tic
            for iScan=1:nScanlines
                
                [ jPixel, jScan, isi, iei, jsi, jei, iso, jso, ieo, jeo] = get_subregion_indicies( nPixels, nScanlines, iPixel, iScan, in_size_x, in_size_y, out_size_x, out_size_y);
                
                % Build the input array of the subregion; 0s everywhere except for the
                % jPixel, jScan point, which is given a 1.
                
                vin = zeros(iei-isi+1, jei-jsi+1);
                vin(jPixel,jScan) = 1;
                
                % Regrid this array to the new lats and lons using the linear 
                % method (vout) and the nearest neighbor method (vout_nn). 
                
                vout    = griddata( xin(isi:iei,jsi:jei), yin(isi:iei,jsi:jei), vin, xout(iso:ieo,jso:jeo), yout(iso:ieo,jso:jeo), 'linear' );
                vout_nn = griddata( xin(isi:iei,jsi:jei), yin(isi:iei,jsi:jei), vin, xout(iso:ieo,jso:jeo), yout(iso:ieo,jso:jeo), 'nearest');
                
                % Now find all pixels impacted in the subregion and map these to the full
                % region. If no pixels in the output region are impacted, skip this part.
                
                [ tNum,    tweights,    tlocations]    = regrid_subregion( nPixels, nScanlines, [nPixels nScanlines], iPixel, iScan, iso, jso, vout,    tNum,    tweights,    tlocations,    0);
                [ tNum_nn, tweights_nn, tlocations_nn] = regrid_subregion( nPixels, nScanlines, [nPixels nScanlines], iPixel, iScan, iso, jso, vout_nn, tNum_nn, tweights_nn, tlocations_nn, 1);
            end
            fprintf('%f s to process iPixel %i for Region 1\n', toc, iPixel)
            tic
        end
        
        % Note that the 1st dimension of the output goes from 1 to nPixels,
        % which is the size of the 1st dimension of the input for this
        % section. For the test runs I was doing, the inputs for each
        % section were constrained to the 1st nPixels of the data read in.
        
        Num(          1:nPixels, 1:iAntarcticEnd) =       tNum(    :, 1:iAntarcticEnd);
        weights(   :, 1:nPixels, 1:iAntarcticEnd) =   tweights( :, :, 1:iAntarcticEnd);
        locations( :, 1:nPixels, 1:iAntarcticEnd) = tlocations( :, :, 1:iAntarcticEnd);
        
        Num_nn(          1:nPixels, 1:iAntarcticEnd) =       tNum_nn(    :, 1:iAntarcticEnd);
        weights_nn(   :, 1:nPixels, 1:iAntarcticEnd) =   tweights_nn( :, :, 1:iAntarcticEnd);
        locations_nn( :, 1:nPixels, 1:iAntarcticEnd) = tlocations_nn( :, :, 1:iAntarcticEnd);
        
        % Intermediate save
        
        save( filename_out, 'filename_in', 'weights', 'locations', 'weights_nn', 'locations_nn', '-v7.3')
        
    end
    
    %% Regions 2 and 4
    
    for iRegion=regions_to_process
        
        fprintf('Processing Region %i of %s.\n', iRegion, filename_in)
        
        % Get the data for this region.
        
        xin = double( lon(:, region_start(iRegion):region_end(iRegion)));
        yin = double( lat(:, region_start(iRegion):region_end(iRegion)));
        xout = double( regridded_lon(:, region_start(iRegion):region_end(iRegion)));
        yout = double( regridded_lat(:, region_start(iRegion):region_end(iRegion)));
        
        [nPixels, nScanlines] = size(yin);
        
        % Intialize output arrays for this region.
        
        tNum          =  int16( zeros( size(xin)));
        tweights      = single( zeros( 7, nPixels, nScanlines));
        tlocations    =  int32( zeros( 7, nPixels, nScanlines));

        tNum_nn       =  int16( zeros(size(xin)));
        tweights_nn   = single( zeros( 6, nPixels, nScanlines));
        tlocations_nn =  int32( zeros( 6, nPixels, nScanlines));
        
        for iPixel=1:nPixels
            tic
            for iScan=1:nScanlines
                
                [ jPixel, jScan, isi, iei, jsi, jei, iso, jso, ieo, jeo] = get_subregion_indicies( nPixels, nScanlines, iPixel, iScan, in_size_x, in_size_y, out_size_x, out_size_y);
                
                % Build the input array of the subregion; 0s everywhere except for the
                % jPixel, jScan point, which is given a 1.
                
                vin = zeros(iei-isi+1, jei-jsi+1);
                vin(jPixel,jScan) = 1;
                
                % Regrid this array to the new lats and lons.
                
                vout    = griddata( xin(isi:iei,jsi:jei), yin(isi:iei,jsi:jei), vin, xout(iso:ieo,jso:jeo), yout(iso:ieo,jso:jeo), 'linear' );
                vout_nn = griddata( xin(isi:iei,jsi:jei), yin(isi:iei,jsi:jei), vin, xout(iso:ieo,jso:jeo), yout(iso:ieo,jso:jeo), 'nearest');
               
                % Now find all pixels impacted in the subregion and map these to the full
                % region. If no pixels in the output region are impacted, skip this part.
                
                [ tNum,    tweights,    tlocations]    = regrid_subregion( nPixels, nScanlines, [nPixels nScanlines], iPixel, iScan, iso, jso, vout,    tNum,    tweights,    tlocations,    0);
                [ tNum_nn, tweights_nn, tlocations_nn] = regrid_subregion( nPixels, nScanlines, [nPixels nScanlines], iPixel, iScan, iso, jso, vout_nn, tNum_nn, tweights_nn, tlocations_nn, 1);
            end
            fprintf('%f s to process iPixel %i for Region %i\n', toc, iPixel, iRegion)
            tic
        end
        
        % Get the starting and ending scan lines to use from the input file
        % and for the output file. Region 4 needs to go all the way to the
        % end of the orbit so need to handle it a little differently.
                
        jStart_in = overlap;
        jStart_out = region_start(iRegion) - 1 + overlap;
        
        if iRegion == 2
            jEnd_in = size(tNum,2) - overlap;
            jEnd_out = region_end(iRegion) - overlap;
        else
            jEnd_in = size(tNum,2);
            jEnd_out = region_end(iRegion);
        end
        
        Num(             1:nPixels, jStart_out:jEnd_out) = tNum(             :, jStart_in:jEnd_in);
        weights(      :, 1:nPixels, jStart_out:jEnd_out) = tweights(      :, :, jStart_in:jEnd_in);
        locations(    :, 1:nPixels, jStart_out:jEnd_out) = tlocations(    :, :, jStart_in:jEnd_in) + 1354 * (region_start(iRegion) - 1);
        
        Num_nn(          1:nPixels, jStart_out:jEnd_out) = tNum_nn(          :, jStart_in:jEnd_in);
        weights_nn(   :, 1:nPixels, jStart_out:jEnd_out) = tweights_nn(   :, :, jStart_in:jEnd_in);
        locations_nn( :, 1:nPixels, jStart_out:jEnd_out) = tlocations_nn( :, :, jStart_in:jEnd_in) + 1354 * (region_start(iRegion) - 1);

        % Intermediate save
        
        save( filename_out, 'filename_in', 'weights', 'locations', 'weights_nn', 'locations_nn', '-v7.3')
    end
    
    %% Region 3 Arctic, will convert lats and lons to a polar grid with ll2psn and determine weights and location from this coordinate system.
    
    fprintf('Processing Region 4 of %s.\n', filename_in)
    
    % Get the data for this region.
    
    [xin, yin] = ll2psn( lat(:, region_start(3):region_end(3)), lon(:, region_start(3):region_end(3)) );
    [xout, yout] = ll2psn( regridded_lat(:, region_start(3):region_end(3)), regridded_lon(:, region_start(3):region_end(3)) );
    
    xin = double(xin);
    yin = double(yin);
    xout = double(xout);
    yout = double(yout);
    
    [nPixels, nScanlines] = size(yin);
    
    % Intialize output arrays for this region.
    
    tNum          = int16( zeros(size(xin)));
    tweights      = single( zeros( 7, nPixels, nScanlines));
    tlocations    =  int32( zeros( 7, nPixels, nScanlines));
    
    tNum_nn       =  int16( zeros(size(xin)));
    tweights_nn   = single( zeros( 6, nPixels, nScanlines));
    tlocations_nn =  int32( zeros( 6, nPixels, nScanlines));
    
    for iPixel=1:nPixels
        tic
        for iScan=1:nScanlines
            
            [ jPixel, jScan, isi, iei, jsi, jei, iso, jso, ieo, jeo] = get_subregion_indicies( nPixels, nScanlines, iPixel, iScan, in_size_x, in_size_y, out_size_x, out_size_y);
            
            % Build the input array of the subregion; 0s everywhere except for the
            % jPixel, jScan point, which is given a 1.
            
            vin = zeros(iei-isi+1, jei-jsi+1);
            vin(jPixel,jScan) = 1;
            
            % Regrid this array to the new lats and lons.
            
            vout    = griddata( xin(isi:iei,jsi:jei), yin(isi:iei,jsi:jei), vin, xout(iso:ieo,jso:jeo), yout(iso:ieo,jso:jeo), 'linear' );
            vout_nn = griddata( xin(isi:iei,jsi:jei), yin(isi:iei,jsi:jei), vin, xout(iso:ieo,jso:jeo), yout(iso:ieo,jso:jeo), 'nearest');
            
            % Now find all pixels impacted in the subregion and map these to the full
            % region. If no pixels in the output region are impacted, skip this part.
            
            [ tNum,    tweights,    tlocations]    = regrid_subregion( nPixels, nScanlines, [nPixels nScanlines], iPixel, iScan, iso, jso, vout,    tNum,    tweights,    tlocations,    0);
            [ tNum_nn, tweights_nn, tlocations_nn] = regrid_subregion( nPixels, nScanlines, [nPixels nScanlines], iPixel, iScan, iso, jso, vout_nn, tNum_nn, tweights_nn, tlocations_nn, 1);
        end
        fprintf('%f s to process iPixel %i for Region 3.\n', toc, iPixel)
        tic
    end
    
    jStart = region_start(3)-1+overlap;
    jEnd = region_end(3)-overlap;
    
    Num(             1:nPixels, jStart:jEnd) =          tNum(    :, overlap:end-overlap);
    weights(      :, 1:nPixels, jStart:jEnd) =      tweights( :, :, overlap:end-overlap);
    locations(    :, 1:nPixels, jStart:jEnd) =    tlocations( :, :, overlap:end-overlap) + 1354 * (region_start(3) - 1);
    
    Num_nn(          1:nPixels, jStart:jEnd) =       tNum_nn(    :, overlap:end-overlap);
    weights_nn(   :, 1:nPixels, jStart:jEnd) =   tweights_nn( :, :, overlap:end-overlap);
    locations_nn( :, 1:nPixels, jStart:jEnd) = tlocations_nn( :, :, overlap:end-overlap) + 1354 * (region_start(3) - 1);
    
    % Intermediate save
    
    save( filename_out, 'filename_in', 'weights', 'locations', 'weights_nn', 'locations_nn', '-v7.3')
    
    %% Sort the weights and locations arrays on the 1st dimension in descending order.
    
    % The idea here is for the 1st weight in the set of 5 to be the largest,
    % the 2nd the 2nd largest,... and then to sort locations in the same
    % order as weights. First, set any location for which the weights sum
    % to zero to nan; there was no interpolated value for this location.
    
    sum_weights = squeeze(sum(weights,1));
    [isum, jsum] = find(sum_weights == 0);
    for ksum=1:length(isum)
        weights(:,isum(ksum),jsum(ksum)) = nan;
    end
    
    % Next, permute, I think that the sorting requires the column soted on
    % to be the last dimension.
    
    temp = permute( weights, [2, 3, 1]);
    clear weights
    
    % Sort
    
    [m,n,o] = size(temp);
    
    [~,ix] = sort(temp,3,'descend');
    
    temp2 = temp((ix-1)*m*n + reshape(1:m*n,m,[]));
    
    % Permute back to the expected order
    
    weights = permute(temp2, [3, 1, 2]);
    
    % Now do the locations.
    
    temp = permute( locations, [2, 3, 1]);
    temp2 = temp((ix-1)*m*n + reshape(1:m*n,m,[]));
    
    locations = permute(temp2, [3, 1, 2]);
    
    %% Save the results
    
    save( filename_out, 'filename_in', 'weights', 'locations', 'weights_nn', 'locations_nn', '-v7.3')
    
    clear weights locations locations_nn temp*
    
    fprintf('Took %f s to process the entire run.\n', toc(tStart))
end
