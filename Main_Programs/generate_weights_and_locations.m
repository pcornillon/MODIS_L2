function generate_weights_and_locations(pattern_in, num_in_range)
% generate_weights_and_locations - does this for inputs to fix bow-tie - PCC
%
% This function reads in the longitudes, latitude, regridded longitudes and
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
%   num_in_range - the number of orbits in the range found with the
%    patter_in.
%
% OUTPUT
%  none - the results are saved in a mat file.
%
% EXAMPLE
%   generate_weights_and_locations('20100301T', 3)
%

test_run = 0;

% Define some variables

in_size_x = 4;
in_size_y = 33;
out_size_x = 4;
out_size_y = 33;

bad_griddata_threshold = -1;

% Turn off warnings for duplicate values in griddata.

id = 'MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId';
warning('off',id)

% Get the list of files for the pattern passed in.

if test_run
    filelist = dir(['~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/AQUA_MODIS_orbit_*' pattern_in '*']);
else
    filelist = dir(['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/03/AQUA_MODIS_orbit_*' pattern_in '*']);
end
numfiles = length(filelist);

file_step = floor(numfiles / num_in_range);

% Read in the data

for iFile=1:file_step:numfiles
    jFile = iFile;
    
    while 1==1
        filename_in = [filelist(jFile).folder '/' filelist(jFile).name];
        
        nn = strfind(filename_in, 'orbit_');
        mm = strfind(filename_in, '.nc4');
        filename_out = ['~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/' filename_in(nn+7:mm-1) '_weights.mat'];
        
        if exist(filename_out)
            jFile = jFile + 1;
            
            if jFile > numfiles
                return
            end
        else
            break
        end
    end
    
    fprintf('Working on %s\n', filename_in)
    % Read in the data for this file.
    
    lat = single(ncread(filename_in, 'latitude'));
    regridded_lat = single(ncread(filename_in, 'regridded_latitude'));
    lon = single(ncread(filename_in, 'longitude'));
    regridded_lon = single(ncread(filename_in, 'regridded_longitude'));
       
    % Are the data for this orbit good?
    
    nn = find(isnan(lat)==1);
    if ~isempty(nn)
        fprintf('Sorry but nans in this file; griddata does not like this. Returning\n')
        weights = nan;
        locations = nan;
        return
    end
    
    % Intialize output arrays.
    
    Num = int16(zeros(size(lat)));
    weights = single(zeros(6,size(lat,1),size(lat,2)));
    locations = int32(zeros(6,size(lat,1),size(lat,2)));
    
    % If this is a test run, redefine the input array.
    
    if test_run
        lat = lat(1:50,:);
        regridded_lat = regridded_lat(1:50,:);
        lon = lon(1:50,:);
        regridded_lon = regridded_lon(1:50,:);
    end
    
    % Make sure that there are not nan's in the input.
    
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
    
    overlap = 40;
    
    region_start(1) = iAntarcticStart;
    region_end(1) = iAntarcticEnd + overlap;
    
    region_start(2) = iAntarcticEnd + 1 - overlap;
    region_end(2) = iArcticStart - 1 + overlap;
    
    region_start(3) = iArcticStart - overlap;
    region_end(3) = iArcticEnd + overlap;
    
    region_start(4) = iAntarcticEnd + 1 - overlap;
    region_end(4) = size(lat,2);
    
    % Set timer
    
    tStart = tic;
    
    % Now get the weights and locations; start with the Antarctic region at
    % the beginning of the orbit.
    
    %% Region 1
        
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

    tNum = int16(zeros(size(xin)));
    tweights = single(zeros(6, nPixels, nScanlines));
    tlocations = int32(zeros(6, nPixels, nScanlines));
    
    % % %     for iScan=1:nScanlines
    % % %         tic
    for iPixel=1:nPixels
        tic
        for iScan=1:nScanlines
            
            % % %             % Get the indices for the subregion to grid.
            % % %
            % % %             isi = max([1 iPixel-in_size_x]);
            % % %             iei = min([iPixel+in_size_x nPixels]);
            % % %
            % % %             jsi = max([1 iScan-in_size_y]);
            % % %             jei = min([iScan+in_size_y nScanlines]);
            % % %
            % % %             iso = max([1 iPixel-out_size_x]);
            % % %             ieo = min([iPixel+out_size_x nPixels]);
            % % %
            % % %             jso = max([1 iScan-out_size_y]);
            % % %             jeo = min([iScan+out_size_y nScanlines]);
            % % %
            % % %             if iei <= 2*in_size_x
            % % %                 jPixel = iei - in_size_x;
            % % %             else
            % % %                 jPixel = in_size_x + 1;
            % % %             end
            % % %
            % % %             if jei <= 2*in_size_y
            % % %                 jScan = jei - in_size_y;
            % % %             else
            % % %                 jScan = in_size_y + 1;
            % % %             end
            % % %
            % % %             % Define the input array to regrid - all zeros except for one
            % % %             % point, which is set to 1. This point is in the center of the
            % % %             % array except when near the edges.
            % % %
            % % %             vin = zeros(iei-isi+1, jei-jsi+1);
            % % %             vin(jPixel,jScan) = 1;
            % % %
            % % %             % Regrid.
            % % %
            % % %             lon_temp = double(longitude(isi:iei,jsi:jei));
            % % %             lat_temp = double(latitude(isi:iei,jsi:jei));
            % % %             regridded_lon_temp = double(regridded_longitude(iso:ieo,jso:jeo));
            % % %             regridded_lat_temp = double(regridded_latitude(iso:ieo,jso:jeo));
            % % %
            % % %             vout = griddata( lon_temp, lat_temp, vin, regridded_lon_temp, regridded_lat_temp);
            % % %             % % %             vout = griddata( longitude(isi:iei,jsi:jei), latitude(isi:iei,jsi:jei), vin, regridded_longitude(iso:ieo,jso:jeo), regridded_latitude(iso:ieo,jso:jeo));
            % % %
            % % %             nn = find( (vout ~= 0) & (isnan(vout) == 0) );
            % % %
            % % %             if ~isempty(nn)
            % % %                 [iot, jot] = find( (vout ~= 0) & (isnan(vout) == 0) );
            % % %
            % % %                 % Get the subscripts for the found pixels in the input array.
            % % %
            % % %                 at = iot + isi - 1;
            % % %                 bt = jot + jsi - 1;
            % % %
            % % %                 a = max([ones(size(at')); at'])';
            % % %                 a = min([at'; ones(size(at')) * nPixels])';
            % % %
            % % %                 b = max([ones(size(bt')); bt'])';
            % % %                 b = min([bt'; ones(size(bt')) * nScanlines])';
            % % %
            % % %                 sol = sub2ind(size(latitude), a, b);
            % % %
            % % %                 % Add the weight values and location values to the weights
            % % %                 % and locations arrays at the point in output array
            % % %                 % affected by this input value.
            % % %
            % % %                 for iNum=1:length(sol)
            % % %                     Num(sol(iNum)) = Num(sol(iNum)) + 1;
            % % %                     k = Num(sol(iNum));
            % % %
            % % %                     weights(k,a(iNum),b(iNum)) = vout(nn(iNum));
            % % %                     locations(k,a(iNum),b(iNum)) = sub2ind(size(latitude), iPixel, iScan);
            % % %
            % % %                     if locations(k,a(iNum),b(iNum)) > numel(latitude)
            % % %                         keyboard
            % % %                     end
            % % %                 end
            % % %             end
            % % %         end
            
            [ jPixel, jScan, isi, iei, jsi, jei, iso, jso, ieo, jeo] = get_subregion_indicies( nPixels, nScanlines, iPixel, iScan, in_size_x, in_size_y, out_size_x, out_size_y);
            
            % Build the input array of the subregion; 0s everywhere except for the
            % jPixel, jScan point, which is given a 1.
            
            vin = zeros(iei-isi+1, jei-jsi+1);
            vin(jPixel,jScan) = 1;
            
            % Regrid this array to the new lats and lons.
            
            vout = griddata( xin(isi:iei,jsi:jei), yin(isi:iei,jsi:jei), vin, xout(iso:ieo,jso:jeo), yout(iso:ieo,jso:jeo));
            
            % Now find all pixels impacted in the subregion and map these to the full
            % region. If no pixels in the output region are impacted, skip this part.

            [tNum, tweights, tlocations] = regrid_subregion( nPixels, nScanlines, [nPixels nScanlines], iPixel, iScan, iso, jso, vout, tNum, tweights, tlocations);
        end
        fprintf('%f s to process iPixel %i\n', toc, iPixel)
        tic
    end
    
    Num(1:nPixels,1:iAntarcticEnd)  = tNum(:,1:iAntarcticEnd);
    weights(:,1:nPixels,1:iAntarcticEnd) = tweights(:,:,1:iAntarcticEnd);
    locations(:,1:nPixels,1:iAntarcticEnd) = tlocations(:,:,1:iAntarcticEnd);

    % Intermediate save
    
    save( filename_out, 'filename_in', 'weights', 'locations', '-v7.3')

    %% Regions 2 and 3
    
    for iRegion=2,4
               
      fprintf('Processing Region %i of %s.\n', iRegion, filename_in)

      % Get the data for this region.
        
        xin = double( lon(:, region_start(iRegion):region_end(iRegion)));
        yin = double( lat(:, region_start(iRegion):region_end(iRegion)));
        xout = double( regridded_lon(:, region_start(iRegion):region_end(iRegion)));
        yout = double( regridded_lat(:, region_start(iRegion):region_end(iRegion)));
        
        [nPixels, nScanlines] = size(yin);
        
        % Intialize output arrays for this region.
        
        tNum = int16(zeros(size(xin)));
        tweights = single(zeros(6, nPixels, nScanlines));
        tlocations = int32(zeros(6, nPixels, nScanlines));
        
        for iPixel=1:nPixels
            tic
            for iScan=1:nScanlines
                
                [ jPixel, jScan, isi, iei, jsi, jei, iso, jso, ieo, jeo] = get_subregion_indicies( nPixels, nScanlines, iPixel, iScan, in_size_x, in_size_y, out_size_x, out_size_y);
                
                % Build the input array of the subregion; 0s everywhere except for the
                % jPixel, jScan point, which is given a 1.
                
                vin = zeros(iei-isi+1, jei-jsi+1);
                vin(jPixel,jScan) = 1;
                
                % Regrid this array to the new lats and lons.
                
                vout = griddata( xin(isi:iei,jsi:jei), yin(isi:iei,jsi:jei), vin, xout(iso:ieo,jso:jeo), yout(iso:ieo,jso:jeo));
                
                % Now find all pixels impacted in the subregion and map these to the full
                % region. If no pixels in the output region are impacted, skip this part.
                
                [tNum, tweights, tlocations] = regrid_subregion( nPixels, nScanlines, [nPixels nScanlines], iPixel, iScan, iso, jso, vout, tNum, tweights, tlocations);
            end
            fprintf('%f s to process iPixel %i\n', toc, iPixel)
            tic
        end
        
        Num(1:nPixels,region_start(iRegion)+overlap:region_end(iRegion)-overlap)  = tNum(:,overlap:end-overlap);
        weights(:,1:nPixels,region_start(iRegion)+overlap:region_end(iRegion)-overlap) = tweights(:,:,overlap:end-overlap);
        locations(:,1:nPixels,region_start(iRegion)+overlap:region_end(iRegion)-overlap) = tlocations(:,:,overlap:end-overlap);
        
        % Intermediate save
        
        save( filename_out, 'filename_in', 'weights', 'locations', '-v7.3')
    end
    
    %% Region 4
        
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

    tNum = int16(zeros(size(xin)));
    tweights = single(zeros(6, nPixels, nScanlines));
    tlocations = int32(zeros(6, nPixels, nScanlines));
    
    for iPixel=1:nPixels
        tic
        for iScan=1:nScanlines
            
            [ jPixel, jScan, isi, iei, jsi, jei, iso, jso, ieo, jeo] = get_subregion_indicies( nPixels, nScanlines, iPixel, iScan, in_size_x, in_size_y, out_size_x, out_size_y);
            
            % Build the input array of the subregion; 0s everywhere except for the
            % jPixel, jScan point, which is given a 1.
            
            vin = zeros(iei-isi+1, jei-jsi+1);
            vin(jPixel,jScan) = 1;
            
            % Regrid this array to the new lats and lons.
            
            vout = griddata( xin(isi:iei,jsi:jei), yin(isi:iei,jsi:jei), vin, xout(iso:ieo,jso:jeo), yout(iso:ieo,jso:jeo));
            
            % Now find all pixels impacted in the subregion and map these to the full
            % region. If no pixels in the output region are impacted, skip this part.

            [tNum, tweights, tlocations] = regrid_subregion( nPixels, nScanlines, [nPixels nScanlines], iPixel, iScan, iso, jso, vout, tNum, tweights, tlocations);
        end
        fprintf('%f s to process iPixel %i\n', toc, iPixel)
        tic
    end
    
    Num(1:nPixels,region_start(3)+overlap:region_end(iRegion))  = tNum(:,overlap:end);
    weights(:,1:nPixels,region_start(3)+overlap:region_end(iRegion)) = tweights(:,:,overlap:end);
    locations(:,1:nPixels,region_start(3)+overlap:region_end(iRegion)) = tlocations(:,:,overlap:end);

    % Intermediate save
    
    save( filename_out, 'filename_in', 'weights', 'locations', '-v7.3')
    
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
    
    save( filename_out, 'filename_in', 'weights', 'locations', '-v7.3')

    clear weights locations temp*

    fprintf('Took %f s to process the entire run.\n', toc(tStart))
end
