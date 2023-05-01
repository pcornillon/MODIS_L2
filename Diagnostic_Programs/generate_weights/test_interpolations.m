% test_interpolations - contains code to test griddata interpolations - PCC
%
% The following tests are for orbit file: AQUA_MODIS_orbit_41675_20100305T012144_L2_SST.nc4
% The region on which the tests focus for this orbit is: (1301:1350,2381:2600)
%
% test=1 Applies griddata pixel-by-pixel (everything else set to 0 except
%  for the pixel being worked on) to regrid to the regridded_lat, lon. Each
%  application of griddata returns a field on the regridded coordinates,
%  which is loaded into a new 3d array. These are summed of the dimension of
%  the iterations (not pixel and scan line).
%
% test=2 The same as above except that instead of the original SST it uses
%  a 1 at each pixel location. The resulting arrays are then multiplied by
%  the original SSTs and summed.
%

set(0,'DefaultFigureWindowStyle','docked')
set(groot,'DefaultFigureColormap',jet)

Polar = 0;

test = 6;
laptop = 0;
region = 5;
generate_weights = 1;
test_file = 1;

iFile_offset = 0;
if Polar
    iFile_offset = 11;
end

debug = 0;

Method = 'linear';
% Method = 'nearest';

in_size_x = 4;
in_size_y = 33;
out_size_x = 4;
out_size_y = 33;

% in_size_x = 4;
% in_size_y = 15;
% out_size_x = 4;
% out_size_y = 15;

sPix = 14;
sScan = 17;

% bad_griddata_threshold = 0.01;
bad_griddata_threshold = -1;

iPlot = 3;
iFig = 100;
iFig200 = 200;

% Turn off warnings for duplicate values in griddata.

id = 'MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId';
warning('off',id)

% Carve out the area of interest.

switch region
    case 1
        iStart = 1301;
        iEnd = 1350;
        jStart = 2381;
        jEnd = 2600;
        
    case 2
        iStart = 1311;
        iEnd = 1340;
        jStart = 2521;
        jEnd = 2555;
        
    case 3
        iStart = 1;
        iEnd = 10;
        jStart = 1;
        jEnd = 40271;
        
    case 4
        iStart = 1;
        iEnd = 1354;
        jStart = 1;
        jEnd = 40271;
        
    case 5
        iStart = 111-30;
        iEnd = 140+30;
        jStart = 20751-15;
        jEnd = 20790+15;
end

if ~test_file
    filelist = dir('/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/03/AQUA_MODIS*');
    files_to_do = 1:10:200;
else
    files_to_do = 1;
end

for iFile=files_to_do
    jFile = iFile;
    
    % Read the data from the file if it is not already in memory.
    
    while 1==1
        % if ~exist('fi_orbit')
        
        if test_file
            if laptop
                %                 fi_orbit = '~/Desktop/AQUA_MODIS_orbit_41675_20100305T012144_L2_SST.nc4';
                fi_orbit = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/AQUA_MODIS_orbit_41616_20100301T000736_L2_SST.nc4';
            else
                %                 fi_orbit = '/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/03/AQUA_MODIS_orbit_41675_20100305T012144_L2_SST.nc4';
                fi_orbit = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/AQUA_MODIS_orbit_41616_20100301T000736_L2_SST.nc4';
            end
        else
            fi_orbit = [filelist(jFile).folder '/' filelist(jFile).name];
        end
        
        
        SST_In_temp = ncread(fi_orbit, 'SST_In');
        
        SST_In = SST_In_temp(iStart:iEnd,jStart:jEnd);
        nn = find( (SST_In==0) | (isnan(SST_In) == 1) );
        if length(nn) ~= numel(SST_In)
            break
        end
        jFile = jFile + 1;
    end
    
    fprintf('%i) Working on %s\n', iFile, fi_orbit)
    
    lat = ncread(fi_orbit, 'latitude');
    lon = ncread(fi_orbit, 'longitude');
    regridded_lon = ncread(fi_orbit, 'regridded_longitude');
    regridded_lat = ncread(fi_orbit, 'regridded_latitude');
    % end
    
    clear yy*
    
    SST_In = SST_In_temp(iStart:iEnd,jStart:jEnd);
    latitude = lat(iStart:iEnd,jStart:jEnd);
    longitude = lon(iStart:iEnd,jStart:jEnd);
    regridded_latitude = regridded_lat(iStart:iEnd,jStart:jEnd);
    regridded_longitude = regridded_lon(iStart:iEnd,jStart:jEnd);
    
    if Polar
        [longitude, latitude] = ll2psn(longitude, latitude);
        [regridded_longitude, regridded_latitude] = ll2psn(regridded_longitude, regridded_latitude);
    end

    [nPixels, nScanlines] = size(SST_In);
    
    % Plot the input field and its Sobel gradient.
    
    figure(iFile+iFile_offset)
    clf
    
    numPlots = 3 + length(test);
    
    subplot(2,numPlots,1)
    imagesc(SST_In')
    set(gca,fontsize=20)
    title('SST\_In', fontsize=30)
    colorbar
    
    [~, ~, gmagSST_In] = Sobel(SST_In, 1);
    
    subplot(2,numPlots,numPlots+1)
    
    imagesc(gmagSST_In(2:end-1,2:end-1)')
    set(gca,fontsize=20)
    title('\nabla{SST\_In}', fontsize=30)
    colorbar
    
    % Do nearest neighbor griddata on the array to be fixed and plot it and its gradient.
    
    yynearest = griddata( longitude, latitude, SST_In, regridded_longitude, regridded_latitude, 'nearest');
    
    subplot(2,numPlots,2)
    
    imagesc(yynearest')
    set(gca,fontsize=20)
    title('yy - Nearest Neighbor', fontsize=30)
    colorbar
    
    [~, ~, gmagnearest] = Sobel(yynearest, 1);
    
    subplot(2,numPlots,numPlots+2)
    
    imagesc(gmagnearest(2:end-1,2:end-1)')
    set(gca,fontsize=20)
    title('\nabla{yy} - Nearest Neighbor', fontsize=30)
    colorbar
    
    % Now do linear griddata on the array to be fixed and plot it and its gradient.
    
    yylinear = griddata( longitude, latitude, SST_In, regridded_longitude, regridded_latitude, 'linear');
    
    subplot(2,numPlots,3)
    
    imagesc(yylinear')
    set(gca,fontsize=20)
    title('yy - Linear', fontsize=30)
    colorbar
    
    % Use this colorbar for the rest of the SST plots.
    
    CLIM_SST = get(gca,'clim');
    CLIM_SST(1) = floor(CLIM_SST(1));
    CLIM_SST(2) = ceil(CLIM_SST(2));
    caxis(CLIM_SST)
    
    subplot(2,numPlots,1)
    caxis(CLIM_SST)
    
    subplot(2,numPlots,2)
    caxis(CLIM_SST)
    
    [~, ~, gmaglinear] = Sobel(yylinear, 1);
    
    subplot(2,numPlots,numPlots+3)
    
    imagesc(gmaglinear(2:end-1,2:end-1)')
    set(gca,fontsize=20)
    title('\nabla{yy} - Linear', fontsize=30)
    colorbar
    
    % Use this colorbar for the rest of the gradient plots.
    
    CLIM_gradient = get(gca,'clim');
    CLIM_gradient(1) = floor(CLIM_gradient(1));
    CLIM_gradient(2) = ceil(CLIM_gradient(2));
    caxis(CLIM_gradient)
    
    subplot(2,numPlots,numPlots+1)
    caxis(CLIM_gradient)
    
    subplot(2,numPlots,numPlots+2)
    caxis(CLIM_gradient)
    
    % Initialize parameters needed for the run.
    
    locs1 = zeros(numel(SST_In),5);
    
    weights = zeros(5,nPixels,nScanlines);
    locations = zeros(5,nPixels,nScanlines);
    Num = zeros(nPixels,nScanlines);
    
    iFrame = 0;
    
    start_timer = tic;
    
    if test ~= 10
        for iTest=test
            
            if generate_weights
                
                iGrid = 0;
                
                yy5 = zeros(size(SST_In));
                
                %                 for iScan=1:nScanlines
                %                     tic
                for iPixel=1:nPixels
                    tic
                    for iScan=1:nScanlines
                        
                        iGrid = iGrid + 1;
                        
                        SST_Inp = zeros(size(SST_In));
                        
                        switch iTest
                            case 1
                                SST_Inp(iPixel,iScan) =  SST_In(iPixel,iScan);
                                yy1(iGrid,:,:) = griddata( longitude, latitude, SST_Inp, regridded_longitude, regridded_latitude, Method);
                                
                            case 2
                                SST_Inp(iPixel,iScan) =  1;
                                yy2(iGrid,:,:) = griddata( longitude, latitude, SST_Inp, regridded_longitude, regridded_latitude, Method);
                                
                                nn = find( yy2(iGrid,:,:) ~= 0);
                                if ~isempty(nn)
                                    for iNum=1:length(nn)
                                        locs1(iGrid,iNum) = nn(iNum);
                                    end
                                end
                                
                            case 3
                                SST_Inp(iPixel,iScan) =  1;
                                yy3 = griddata( longitude, latitude, SST_Inp, regridded_longitude, regridded_latitude, Method);
                                
                                nn = find( (yy3 ~= 0) & (isnan(yy3) == 0) );
                                if ~isempty(nn)
                                    for iNum=1:length(nn)
                                        Num(nn(iNum)) = Num(nn(iNum)) + 1;
                                        k = Num(nn(iNum));
                                        
                                        [a, b] = ind2sub(size(yy3),nn(iNum));
                                        weights(k,a,b) = yy3(nn(iNum));
                                        locations(k,a,b) = sub2ind(size(SST_In), iPixel, iScan);
                                    end
                                end
                                
                            case 4
                                
                                % Get the starting and ending indices of
                                % the subregion in the original array on
                                % which griddata is being applied.
                                
                                isi = max([1 iPixel-in_size_x]);
                                iei = min([iPixel+in_size_x nPixels]);
                                
                                jsi = max([1 iScan-in_size_y]);
                                jei = min([iScan+in_size_y nScanlines]);
                                
                                iso = max([1 iPixel-out_size_x]);
                                ieo = min([iPixel+out_size_x nPixels]);
                                
                                jso = max([1 iScan-out_size_y]);
                                jeo = min([iScan+out_size_y nScanlines]);
                                
                                % Find the location at which the value of 1
                                % is to be places in the subregion being
                                % regridded.
                                
                                if iei <= 2*in_size_x
                                    jPixel = iei - in_size_x;
                                else
                                    jPixel = in_size_x + 1;
                                end
                                
                                if jei <= 2*in_size_y
                                    jScan = jei - in_size_y;
                                else
                                    jScan = in_size_y + 1;
                                end
                                
                                % Build the input array of the subregion;
                                % 0s everywhere except fo the jPixel, jScan
                                % point, which is given a 1.
                                
                                vin = zeros(iei-isi+1, jei-jsi+1);
                                vin(jPixel,jScan) = 1;
                                
                                % Regrid this array to the new lats and lons.
                                
                                lont = longitude(isi:iei,jsi:jei);
                                %                                 lontd = diff(lont);
                                %                                 nn = find(abs(lontd) >100);
                                %                                 if ~isempty(nn)
                                %                                     yy4t = griddata( lont, latitude(isi:iei,jsi:jei), vin, regridded_longitude(iso:ieo,jso:jeo), regridded_latitude(iso:ieo,jso:jeo));
                                %                                     lont(lont > mean(lont, 'all', 'omitnan')) = lont(lont > mean(lont, 'all', 'omitnan')) -360;
                                %                                 end
                                
                                % % %                                 yy4 = griddata( longitude(isi:iei,jsi:jei), latitude(isi:iei,jsi:jei), vin, regridded_longitude(iso:ieo,jso:jeo), regridded_latitude(iso:ieo,jso:jeo));
                                yy4 = griddata( lont, latitude(isi:iei,jsi:jei), vin, regridded_longitude(iso:ieo,jso:jeo), regridded_latitude(iso:ieo,jso:jeo));
                                
                                % Now find all pixels impacted in the
                                % subregion and map these to the full
                                % region. If no pixels in the output region
                                % are impacted, skip this part.
                                
                                mm = find( (yy4 ~= 0) & (isnan(yy4) == 0) );
                                
                                if ~isempty(mm)
                                    
                                    % First get the i, j location of the
                                    % impacted pixels in the subregion of
                                    % the new grid. Unfortunately, nan
                                    % qualifies as a non zero value so need
                                    % to test for both.
                                    
                                    [iot, jot] = find( (yy4 ~= 0) & (isnan(yy4) == 0) );
                                    
                                    % Get the subscripts for the impacted
                                    % pixels in the full new array.
                                    
                                    at = iot + iso - 1;
                                    bt = jot + jso - 1;
                                    
                                    % % %                                     a = max([ones(size(at')); at'])';
                                    % % %                                     a = min([at'; ones(size(at')) * nPixels])';
                                    % % %
                                    % % %                                     b = max([ones(size(bt')); bt'])';
                                    % % %                                     b = min([bt'; ones(size(bt')) * nScanlines])';
                                    
                                    % Make sure that the location of pixels
                                    % in the full output array are not out
                                    % of bounds.
                                    
                                    kk = find((at > 0) & (at <= nPixels) & (bt > 0) & (bt <= nScanlines));
                                    
                                    a = at(kk);
                                    b = bt(kk);
                                    nn = mm(kk);
                                    
                                    % Hopefully, some pixels remain.
                                    
                                    if length(a) > 0
                                        
                                        % Get the indices of the impacted
                                        % pixels in the full array.
                                        
                                        sol = sub2ind(size(SST_In), a, b);
                                        
                                        %                                     if iPixel==19 & iScan==11
                                        %                                         for kp=1:length(sol)
                                        %                                             fprintf('%i) Input loc (%i, %i). sol(i)=%i, (a(i), b(i))=(%i, %i)\n', kp, iPixel, iScan, sol(kp), a(kp), b(kp))
                                        %                                         end
                                        %                                         ttemp = 1;
                                        %                                     end
                                        
                                        % Loop over all impacted pixels
                                        % saving their weight and location.
                                        
                                        for iNum=1:length(sol)
                                            
                                            % Eliminate phantom hits from the list.
                                            
                                            if abs(yy4(nn(iNum))) > bad_griddata_threshold
                                                Num(sol(iNum)) = Num(sol(iNum)) + 1;
                                                k = Num(sol(iNum));
                                                
                                                weights(k,a(iNum),b(iNum)) = yy4(nn(iNum));
                                                locations(k,a(iNum),b(iNum)) = sub2ind(size(SST_In), iPixel, iScan);
                                                
                                                if a(iNum)==sPix & b(iNum)==sScan
                                                    fprintf('%i) regridded loc: (%i, %i), input loc (%i, %i). weight=%f loc=%i, sst_in=%f\n', iNum, a(iNum), b(iNum), iPixel, iScan, weights(k,a(iNum),b(iNum)), locations(k,a(iNum),b(iNum)), SST_In(iPixel,iScan))
                                                end
                                            end
                                        end
                                        
                                        qq = find(a == sPix & b == sScan);
                                        if ~isempty(qq)
                                            iFig200 = iFig200 + 1;
                                            debugPlot(iFig200, [162 163.5 86.80 86.86], longitude, latitude, regridded_longitude, regridded_latitude, iPixel, iScan, a(abs(yy4(nn)) > bad_griddata_threshold), b(abs(yy4(nn)) > bad_griddata_threshold))
                                            keyboard
                                        end
                                    end
                                end
                                
                            case 5
                                                                
                                vin = zeros(size(SST_In));
                                vin(iPixel,iScan) = SST_In(iPixel,iScan);
                                
                                % Regrid this array to the new lats and lons.
                                
                                yy5f = griddata( longitude, latitude, vin, regridded_longitude, regridded_latitude);
                                nn = find(isnan(yy5f) == 1);
                                yy5f(nn) = 0;
                                yy5 = yy5 + yy5f;
                                
                                % Does this pixel impact sPix, sScan in the
                                % output array?
                                
                                [iot, jot] = find( (yy5f ~= 0) & (isnan(yy5f) == 0) );
                                nn = find(iot == sPix & jot == sScan);
                                if ~isempty(nn)
                                    for kp=1:length(iot)
                                        fprintf('%i) Input loc (%i, %i). weight: %f, normalized weight: %f, (a(i), b(i))=(%i, %i)\n', kp, iPixel, iScan, yy5f(iot(kp),jot(kp)), yy5f(iot(kp),jot(kp))/SST_In(iPixel,iScan), iot(kp), jot(kp))
                                    end
                                    
                                    iFrame = iFrame + 1;
                                    yy5fs(iFrame,:,:) = yy5f;
                                    
                                    figure(iFrame+10)
                                    clf
                                    imagesc(yy5f')
                                    caxis([-27 -19])
                                    
                                    figure(15)
                                    imagesc(yy5')
                                    caxis([-27 -19])
                                    
                                    keyboard
                                end
                                
                            case 6
                                
                                % Get the starting and ending indices of
                                % the subregion in the original array on
                                % which griddata is being applied.
                                
                                isi = max([1 iPixel-in_size_x]);
                                iei = min([iPixel+in_size_x nPixels]);
                                
                                jsi = max([1 iScan-in_size_y]);
                                jei = min([iScan+in_size_y nScanlines]);
                                
                                iso = max([1 iPixel-out_size_x]);
                                ieo = min([iPixel+out_size_x nPixels]);
                                
                                jso = max([1 iScan-out_size_y]);
                                jeo = min([iScan+out_size_y nScanlines]);
                                
                                % Find the location at which the value of 1
                                % is to be places in the subregion being
                                % regridded.
                                
                                if iei <= 2*in_size_x
                                    jPixel = iei - in_size_x;
                                else
                                    jPixel = in_size_x + 1;
                                end
                                
                                if jei <= 2*in_size_y
                                    jScan = jei - in_size_y;
                                else
                                    jScan = in_size_y + 1;
                                end
                                
                                % Build the input array of the subregion;
                                % 0s everywhere except fo the jPixel, jScan
                                % point, which is given a 1.
                                
                                vin = zeros(iei-isi+1, jei-jsi+1);
%                                 vin(jPixel,jScan) = SST_In(iPixel,iScan);
                                vin(jPixel,jScan) = 1;	
                                
                                % Regrid this array to the new lats and lons.
                                
                                yy6 = griddata( longitude(isi:iei,jsi:jei), latitude(isi:iei,jsi:jei), vin, regridded_longitude(iso:ieo,jso:jeo), regridded_latitude(iso:ieo,jso:jeo));
                                
                                % Now find all pixels impacted in the
                                % subregion and map these to the full
                                % region. If no pixels in the output region
                                % are impacted, skip this part.
                                
                                [iot, jot] = find(yy6 ~= 0);
                                
                                if ~isempty(iot)
                                                                        
                                    % Get the subscripts for the impacted
                                    % pixels in the full regridded array.
                                    
                                    at = iot + iso - 1;
                                    bt = jot + jso - 1;
                                    
% % %                                     % DEBUG *******************************
% % % 
% % %                                     nn = find(at == sPix & bt == sScan);
% % %                                     if ~isempty(nn)
% % %                                         for kp=1:length(iot)
% % %                                             fprintf('%i) Input loc (%i, %i). weight: %f, normalized weight: %f, (a(i), b(i))=(%i, %i)\n', kp, iPixel, iScan, yy6(iot(kp),jot(kp)), yy6(iot(kp),jot(kp))/SST_In(iPixel,iScan), at(kp), bt(kp))
% % %                                         end
% % % %                                         keyboard
% % %                                     end
% % %                                     
% % %                                     % DEBUG *******************************
                                    
                                    % Make sure that the location of pixels
                                    % in the full output array are not out
                                    % of bounds.
                                    
                                    kk = find((at > 0) & (at <= nPixels) & (bt > 0) & (bt <= nScanlines));
                                    
                                    if length(kk) ~= length(at)
                                        fprintf('\n******************\n******************\n at or bt out of bounds for (iPixel, iScan) = (%i, %i)\n******************\n******************\n\n', iPixel, iScan)
                                    end
                                    
                                    a = at(kk);
                                    b = bt(kk);
                                    
                                    % Hopefully, some pixels remain.
                                    
                                    if length(a) > 0
                                        
                                        % Get the indices of the impacted
                                        % pixels in the full array.
                                        
                                        sol = sub2ind(size(SST_In), a, b);
                                        
                                        % Loop over all impacted pixels
                                        % saving their weight and location.
                                        
                                        for iNum=1:length(sol)
                                            
                                            % Eliminate phantom hits from the list.
                                            
                                            if abs(yy6(iot(iNum),jot(iNum))) > bad_griddata_threshold
                                                Num(sol(iNum)) = Num(sol(iNum)) + 1;
                                                k = Num(sol(iNum));
                                                
%                                                 weights(k,a(iNum),b(iNum)) = yy6(iot(iNum),jot(iNum)) / SST_In(iPixel,iScan);
                                                weights(k,a(iNum),b(iNum)) = yy6(iot(iNum),jot(iNum));
                                                locations(k,a(iNum),b(iNum)) = sub2ind(size(SST_In), iPixel, iScan);
                                                
% % %                                                 if a(iNum)==sPix & b(iNum)==sScan
% % %                                                     fprintf('%i) regridded loc: (%i, %i), input loc (%i, %i). weight=%f loc=%i, sst_in=%f\n', iNum, a(iNum), b(iNum), iPixel, iScan, weights(k,a(iNum),b(iNum)), locations(k,a(iNum),b(iNum)), SST_In(iPixel,iScan))
% % %                                                 end
                                            end
                                        end
                                    end
                                end
                                
                        end
                    end
                    fprintf('%f s to process iPixel %i\n', toc, iPixel)
                end
                
            else
                % Get weights and locations
                
                load /Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/test_weights.mat
            end
            
            % Sort the weights and locations arrays on the 1st dimension in
            % descending order. The idea here is for the 1st weight in the
            % set of 5 to be the largest, the 2nd the 2nd largest,... and
            % then to sort locations in the same order as weights.
            
            switch test
                case {3, 4, 6}
                    
                    % First, set any location for which the weights sum to
                    % zero to nan; there was no interpolated value for this
                    % location.
                    
                    sum_weights = squeeze(sum(weights,1));
                    [isum, jsum] = find(sum_weights == 0);
                    for ksum=1:length(isum)
                        weights(:,isum(ksum),jsum(ksum)) = nan;
                    end
                    
                    % First, permute, I think that the sorting requires the column
                    % soted on to be the last dimension.
                    
                    temp = permute( weights, [2, 3, 1]);
                    clear weights
                    
                    % Next sort
                    
                    [m,n,o] = size(temp);
                    
                    [~,ix] = sort(temp,3,'descend');

                    temp2 = temp((ix-1)*m*n + reshape(1:m*n,m,[]));
                    
                    % Permute back to the expected order
                    
                    weights = permute(temp2, [3, 1, 2]);
                    
                    % Now do the locations.
                    
                    temp = permute( locations, [2, 3, 1]);
                    temp2 = temp((ix-1)*m*n + reshape(1:m*n,m,[]));
                    
                    locations = permute(temp2, [3, 1, 2]);
                    
                    clear temp temp2
            end
            
            % Sum the arrays and plot
            
            switch iTest
                case 1
                    yy1s = squeeze(sum(yy1,1,'omitnan'));
                    
                    figure(iFig+1)
                    clf
                    imagesc(yy1s')
                    set(gca,fontsize=20)
                    title('yy1', fontsize=30)
                    
                    [~, ~, gmag1] = Sobel(yy1s, 1);
                    
                    figure(iFig+21)
                    imagesc(gmag1')
                    set(gca,fontsize=20)
                    title('\nabla{yy1}', fontsize=30)
                    
                case 2
                    for iGrid=1:size(yy2,1)
                        yy2p(iGrid,:,:) = zeros(size(SST_In));
                        
                        nn = find(locs1(iGrid,:) > 0);
                        if ~isempty(nn)
                            for iNum=nn
                                [a, b] = ind2sub(size(SST_In),locs1(iGrid,iNum));
                                yy2p(iGrid,a,b) = squeeze(yy2(iGrid,a,b)) .* SST_In(ind2sub(size(SST_In),iGrid));
                            end
                        end
                    end
                    yy2s = squeeze(sum(yy2p,1,'omitnan'));
                    
                    iPlot = iPlot + 1;
                    subplot(2,numPlots,iPlot)
                    
                    imagesc(yy2s')
                    set(gca,fontsize=20)
                    title('yy2', fontsize=30)
                    colorbar
                    caxis(CLIM_SST)
                    
                    [~, ~, gmag2] = Sobel(yy2s, 1);
                    
                    subplot(2,numPlots,numPlots+iPlot)
                    
                    imagesc(gmag2(2:end-1,2:end-1)')
                    set(gca,fontsize=20)
                    title('\nabla{yy2}', fontsize=30)
                    colorbar
                    caxis(CLIM_gradient)
                    
                case {3, 4, 6}
                    yy3s = fast_interpolate_SST_linear( weights, locations, SST_In);
                    
                    figure(iFile+iFile_offset)
                    iPlot = iPlot + 1;
                    subplot(2,numPlots,iPlot)
                    
                    imagesc(yy3s')
                    set(gca,fontsize=20)
                    title('yy3', fontsize=30)
                    colorbar
                    caxis(CLIM_SST)
                    
                    [~, ~, gmag3] = Sobel(yy3s, 1);
                    
                    subplot(2,numPlots,numPlots+iPlot)
                    
                    imagesc(gmag3(2:end-1,2:end-1)')
                    set(gca,fontsize=20)
                    title('\nabla{yy3}', fontsize=30)
                    colorbar
                    caxis(CLIM_gradient)
                                        
                case 5
                    figure(iFile+iFile_offset)
                    iPlot = iPlot + 1;
                    subplot(2,numPlots,iPlot)
                    
                    imagesc(yy5')
                    set(gca,fontsize=20)
                    title('yy5', fontsize=30)
                    colorbar
                    caxis(CLIM_SST)
                    
                    [~, ~, gmag5] = Sobel(yy5, 1);
                    
                    subplot(2,numPlots,numPlots+iPlot)
                    
                    imagesc(gmag5(2:end-1,2:end-1)')
                    set(gca,fontsize=20)
                    title('\nabla{yy5}', fontsize=30)
                    colorbar
                    caxis(CLIM_gradient)
            end
        end
    else
        iGrid = 0;
        for iPixel=1:nPixels
            tic
            
            sep_lat_along_scan = lat(1:end-1,iPixel) - lat(2:end,iPixel);
            sep_lon_along_scan = cosd(lat(1:end-1,iPixel)) .* (lon(1:end-1,iPixel) - lon(2:end,iPixel));
            
            sep_lat_along_track_in = lat(iPixel,1:end-1) - lat(iPixel,2:end);
            sep_lon_along_track_in = cosd(lat(iPixel,1:end-1)) .* (lon(iPixel,1:end-1) - lon(iPixel,2:end));
            
            seps_along_track_in = sqrt( sep_lat_along_track_in.^2 + sep_lon_along_track_in.^2) * 111;
            dist_along_track_in = cumsum(seps_along_track_in);
            
            sep_lat_along_track_regridded = regridded_lat(iPixel,1:end-1) - regridded_lat(iPixel,2:end);
            sep_lon_along_track_regridded = cosd(regridded_lat(iPixel,1:end-1)) .* (regridded_lon(iPixel,1:end-1) - regridded_lon(iPixel,2:end));
            
            seps_along_track_regridded = sqrt( sep_lat_along_track_regridded.^2 + sep_lon_along_track_regridded.^2) * 111;
            dist_along_track_regridded = cumsum(seps_along_track_regridded);
            
            for iScan=1:nScanlines
                iGrid = iGrid + 1;
                dist_along_track = sqrt( (lat(iPixel,1:end-1)-lat(10,2:end)).^2 + (cosd(lat(10,1:end-1)) .* (lon(10,1:end-1)-lon(10,2:end)))).^2
            end
            
            
            iGrid = 0;
            for Pixel=1:nPixels
                tic
                for iScan=1:nScanlines
                    iGrid = iGrid + 1;
                    dist_along_track = sqrt( (lat(10,1:end-1)-lat(10,2:end)).^2 + (cosd(lat(10,1:end-1)) .* (lon(10,1:end-1)-lon(10,2:end)))).^2
                end
            end
        end
    end
    fprintf('Time for this run: %f s\n', toc(start_timer))
end

% Plot point with a problem.

extra_plot1 = 0;
if extra_plot1
    
    % %     % Set some parameters.
    % %
    % %     xoffset = 0.004;
    % %     yoffset = 0;
    % %
    % %     [a, b] = ind2sub( size(latitude), nn);
    % %     [a'; b']
    % %
    % %     % Get the points of interest on the input array
    % %
    % %     nn = find( abs(latitude - regridded_latitude(26,10))<0.015 &  abs(longitude - regridded_longitude(26,10))<0.2 );
    % %
    % %     SST_Intest = SST_In(nn);
    % %     lattest = latitude(nn);
    % %     lontest = longitude(nn);
    % %     regridded_lattest = regridded_latitude(26,10);
    % %     regridded_lontest = regridded_longitude(26,10);
    % %
    % %     % Now plot them
    % %
    % %     figure
    % %     clf
    % %
    % %     plot(lontest,lattest,'.k',markersize=20)
    % %     hold on
    % %     plot( regridded_lontest, regridded_lattest , 'ok', markerfacecolor='c', markersize=20)
    % %     grid on
    % %     plot( regridded_lontest, regridded_lattest , '.k')
    % %
    % %     % Connect the dots.
    % %
    % %     plot( [longitude(27,5) longitude(26,5)], [latitude(27,5) latitude(26,5)], 'k')
    % %     plot( [longitude(27,5) longitude(26,11)], [latitude(27,5) latitude(26,11)], 'k')
    % %     plot( [longitude(26,11) longitude(26,5)], [latitude(26,11) latitude(26,5)], 'k')
    % %
    % %     % Add numbers of grid points to the plot.
    % %
    % %     for i=1:length(a)
    % %         text( longitude(a(i),b(i))+xoffset, latitude(a(i),b(i))+yoffset, [num2str(a(i)) ', ' num2str(b(i))])
    % %     end
    
    hold off
    
    plot(longitude(isi:iei,jsi:jei), latitude(isi:iei,jsi:jei), 'ok', markerfacecolor='y', markersize=10)
    hold on
    
    plot(regridded_longitude(isi:iei,jsi:jei), regridded_latitude(isi:iei,jsi:jei), 'ok', markerfacecolor='g', markersize=10)
    plot(regridded_longitude(sPix,sScan), regridded_latitude(sPix,sScan), 'ok', markerfacecolor='r', markersize=10)
    [iPixel iScan]
    plot(longitude(iPixel,iScan), latitude(iPixel,iScan), 'ok', markerfacecolor='b', markersize=10)
    plot(longitude(iPixel,iScan+1), latitude(iPixel,iScan+1), 'ok', markerfacecolor='r', markersize=10)
    plot(longitude(iPixel,iScan-1), latitude(iPixel,iScan-1), 'ok', markerfacecolor='r', markersize=10)
    plot(longitude(iei,jsi), latitude(iei,jsi), 'ok', markerfacecolor='m', markersize=10)
    plot(longitude(iei,jei), latitude(iei,jei), 'ok', markerfacecolor='k', markersize=10)
    plot(longitude(isi,jsi), latitude(isi,jsi), 'ok', markerfacecolor='b', markersize=10)
    plot(longitude(14,16), latitude(14,16), 'ok', markerfacecolor='m', markersize=10)
    plot(regridded_longitude(14,17), regridded_latitude(14,17), 'ok', markerfacecolor='m', markersize=15)
    plot(longitude(14,17), latitude(14,17), 'ok', markerfacecolor='b', markersize=15)
    
    xoffset = 0.004;
    yoffset = 0;
    for i=9:17
        for j=17:47
            text( longitude(i,j)+xoffset, latitude(i,j)+yoffset, [num2str(i) ', ' num2str(j)])
        end
    end
    
    xoffset = -0.2;
    yoffset = 0;
    for i=9:17
        for j=17:47
            text( regridded_longitude(i,j)+xoffset, regridded_latitude(i,j)+yoffset, [num2str(i) ', ' num2str(j)], color=[1,0,0])
        end
    end
    
    [sPix sScan]
    [iPixel iScan]
    [isi iei;jsi jei; iso jso; ieo jeo]
end

% Plot the location of pixels in geographic coordinates. break at line 330 for iNum=1:length(sol).

extra_plot2 = 0;
if extra_plot2
    figure
    
    plot(longitude(isi:iei,jsi:jei), latitude(isi:iei,jsi:jei), 'ok', markerfacecolor='k', markersize=10)
    hold on
    plot( regridded_longitude(iso:ieo,jso:jeo), regridded_latitude(iso:ieo,jso:jeo), 'ok', markerfacecolor='c', markersize=10)
    plot(longitude(iei,jsi), latitude(iei,jsi), 'ok', markerfacecolor='g', markersize=10)
    plot( regridded_longitude(iso,jeo), regridded_latitude(iso,jso), 'ok', markerfacecolor='y', markersize=10)
    plot( regridded_longitude(iso,jso), regridded_latitude(iso,jso), 'ok', markerfacecolor='y', markersize=10)
    plot( regridded_longitude(ieo,jso), regridded_latitude(ieo,jso), 'ok', markerfacecolor='b', markersize=10)
    kk = find(vin~=0);
    [iplt, jplt] = ind2sub(size(vin), kk);
    iplt = iplt + isi;
    jplt = jplt + jsi;
    [iplt jplt]
    [isi iei; jsi jei; iso ieo; jso jeo]
    plot(longitude(iplt,jplt), latitude(iplt,jplt), 'ok', markerfacecolor='m', markersize=10)
end
