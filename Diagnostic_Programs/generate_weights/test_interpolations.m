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

test = 4;
laptop = 1;
region = 1;
generate_weights = 1;
test_file = 1;

iFile_offset = 0;

debug = 0;

Method = 'linear';
% Method = 'nearest';

in_size_x = 3;
in_size_y = 12;
out_size_x = 3;
out_size_y = 12;

iPlot = 3;
iFig = 100;

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
        %         iStart = 1311;
        %         iEnd = 1340;
        %         jStart = 2521;
        %         jEnd = 2555;
        iStart = 1311;
        iEnd = 1350;
        jStart = 2521;
        jEnd = 2555;
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
                fi_orbit = '~/Desktop/AQUA_MODIS_orbit_41675_20100305T012144_L2_SST.nc4';
            else
                fi_orbit = '/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/03/AQUA_MODIS_orbit_41675_20100305T012144_L2_SST.nc4';
            end
        else
            fi_orbit = [filelist(jFile).folder '/' filelist(jFile).name];
        end
        
        
        SST_In = ncread(fi_orbit, 'SST_In');
        
        xx = SST_In(iStart:iEnd,jStart:jEnd);
        nn = find( (xx==0) | (isnan(xx) == 1) );
        if length(nn) ~= numel(xx)
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
    
    xx = SST_In(iStart:iEnd,jStart:jEnd);
    latxx = lat(iStart:iEnd,jStart:jEnd);
    lonxx = lon(iStart:iEnd,jStart:jEnd);
    regridded_latxx = regridded_lat(iStart:iEnd,jStart:jEnd);
    regridded_lonxx = regridded_lon(iStart:iEnd,jStart:jEnd);
    
    [nPixels, nScanlines] = size(xx);
    
    % Plot the input field and its Sobel gradient.
    
    figure(iFile+iFile_offset)
    clf
    
    numPlots = 3 + length(test);
    
    subplot(2,numPlots,1)
    imagesc(xx')
    set(gca,fontsize=20)
    title('xx', fontsize=30)
    colorbar
    
    [~, ~, gmagxx] = Sobel(xx, 1);
    
    subplot(2,numPlots,numPlots+1)
    
    imagesc(gmagxx(2:end-1,2:end-1)')
    set(gca,fontsize=20)
    title('\nabla{xx}', fontsize=30)
    colorbar
    
    % Do nearest neighbor griddata on the array to be fixed and plot it and its gradient.
    
    yynearest = griddata( lonxx, latxx, xx, regridded_lonxx, regridded_latxx, 'nearest');
    
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
    
    yylinear = griddata( lonxx, latxx, xx, regridded_lonxx, regridded_latxx, 'linear');
    
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
    
    locs1 = zeros(numel(xx),5);
    
    weights = zeros(5,nPixels,nScanlines);
    locations = zeros(5,nPixels,nScanlines);
    Num = zeros(nPixels,nScanlines);
    
    start_timer = tic;
    
    if test ~= 10
        for iTest=test
            
            if generate_weights
                
                iGrid = 0;
                
                %                 for iScan=1:nScanlines
                %                     tic
                for iPixel=1:nPixels
                    tic
                    for iScan=1:nScanlines
                        
                        iGrid = iGrid + 1;
                        
                        xxp = zeros(size(xx));
                        
                        switch iTest
                            case 1
                                xxp(iPixel,iScan) =  xx(iPixel,iScan);
                                yy1(iGrid,:,:) = griddata( lonxx, latxx, xxp, regridded_lonxx, regridded_latxx, Method);
                                
                            case 2
                                xxp(iPixel,iScan) =  1;
                                yy2(iGrid,:,:) = griddata( lonxx, latxx, xxp, regridded_lonxx, regridded_latxx, Method);
                                
                                nn = find( yy2(iGrid,:,:) ~= 0);
                                if ~isempty(nn)
                                    for iNum=1:length(nn)
                                        locs1(iGrid,iNum) = nn(iNum);
                                    end
                                end
                                
                            case 3
                                xxp(iPixel,iScan) =  1;
                                yy3 = griddata( lonxx, latxx, xxp, regridded_lonxx, regridded_latxx, Method);
                                
                                nn = find( (yy3 ~= 0) & (isnan(yy3) == 0) );
                                if ~isempty(nn)
                                    for iNum=1:length(nn)
                                        Num(nn(iNum)) = Num(nn(iNum)) + 1;
                                        k = Num(nn(iNum));
                                        
                                        [a, b] = ind2sub(size(yy3),nn(iNum));
                                        weights(k,a,b) = yy3(nn(iNum));
                                        locations(k,a,b) = sub2ind(size(xx), iPixel, iScan);
                                    end
                                end
                                
                            case 4
                                
                                isi = max([1 iPixel-in_size_x]);
                                iei = min([iPixel+in_size_x nPixels]);
                                
                                jsi = max([1 iScan-in_size_y]);
                                jei = min([iScan+in_size_y nScanlines]);
                                
                                iso = max([1 iPixel-out_size_x]);
                                ieo = min([iPixel+out_size_x nPixels]);
                                
                                jso = max([1 iScan-out_size_y]);
                                jeo = min([iScan+out_size_y nScanlines]);
                                
                                vin = zeros(iei-isi+1, jei-jsi+1);
                                
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
                                
                                vin(jPixel,jScan) = 1;
                                
                                yy4 = griddata( lonxx(isi:iei,jsi:jei), latxx(isi:iei,jsi:jei), vin, regridded_lonxx(iso:ieo,jso:jeo), regridded_latxx(iso:ieo,jso:jeo));
                                
                                nn = find( (yy4 ~= 0) & (isnan(yy4) == 0) );
                                
                                if ~isempty(nn)
                                    [iot, jot] = find( (yy4 ~= 0) & (isnan(yy4) == 0) );
                                    
                                    % Get the subscripts for the
                                    % found pixels in the input
                                    % array.
                                    
                                    at = iot + isi - 1;
                                    bt = jot + jsi - 1;
                                    
                                    a = max([ones(size(at')); at'])';
                                    a = min([at'; ones(size(at')) * nPixels])';
                                    
                                    b = max([ones(size(bt')); bt'])';
                                    b = min([bt'; ones(size(bt')) * nScanlines])';
                                    
                                    sol = sub2ind(size(xx), a, b);
                                    
                                    for iNum=1:length(sol)
                                        Num(sol(iNum)) = Num(sol(iNum)) + 1;
                                        k = Num(sol(iNum));
                                        
                                        weights(k,a(iNum),b(iNum)) = yy4(nn(iNum));
                                        locations(k,a(iNum),b(iNum)) = sub2ind(size(xx), iPixel, iScan);
                                    end
                                end
                        end
                    end
                    fprintf('%f s to process iPixel %i\n', toc, iScan)
                end
            else
                % Get weights and locations
                
                load /Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/test_weights.mat
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
                        yy2p(iGrid,:,:) = zeros(size(xx));
                        
                        nn = find(locs1(iGrid,:) > 0);
                        if ~isempty(nn)
                            for iNum=nn
                                [a, b] = ind2sub(size(xx),locs1(iGrid,iNum));
                                yy2p(iGrid,a,b) = squeeze(yy2(iGrid,a,b)) .* xx(ind2sub(size(xx),iGrid));
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
                    
                case {3, 4}
                    yy3s = fast_interpolate_SST_linear( weights, locations, xx);
%                     yy3s = zeros(size(xx));
%                     
%                     for iC=1:size(weights,1)
%                         weights_temp = squeeze(weights(iC,:,:));
%                         locations_temp = squeeze(locations(iC,:,:));
%                         
%                         good_weights = find( (weights_temp ~= 0) & (isnan(weights_temp) == 0) & (locations_temp ~= 0));
%                         tt = locations_temp(good_weights);
%                         
%                         yy3s(good_weights) = yy3s(good_weights) + xx(tt) .* weights_temp(good_weights);
%                     end
                    
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

extra_plot = 0;
if extra_plot
    
    % Set some parameters.
    
    xoffset = 0.004;
    yoffset = 0;
    
    [a, b] = ind2sub( size(latxx), nn);
    [a'; b']

    % Get the points of interest on the input array
    
    nn = find( abs(latxx - regridded_latxx(26,10))<0.015 &  abs(lonxx - regridded_lonxx(26,10))<0.2 );
    
    xxtest = xx(nn);
    lattest = latxx(nn);
    lontest = lonxx(nn);
    regridded_lattest = regridded_latxx(26,10);
    regridded_lontest = regridded_lonxx(26,10);
    
    % Now plot them
    
    figure
    clf

    plot(lontest,lattest,'.k',markersize=20)
    hold on
    plot( regridded_lontest, regridded_lattest , 'ok', markerfacecolor='c', markersize=20)
    grid on
    plot( regridded_lontest, regridded_lattest , '.k')

    % Connect the dots.
    
    plot( [lonxx(27,5) lonxx(26,5)], [latxx(27,5) latxx(26,5)], 'k')
    plot( [lonxx(27,5) lonxx(26,11)], [latxx(27,5) latxx(26,11)], 'k')
    plot( [lonxx(26,11) lonxx(26,5)], [latxx(26,11) latxx(26,5)], 'k')
    
    % Add numbers of grid points to the plot.
    
    for i=1:length(a)
        text( lonxx(a(i),b(i))+xoffset, latxx(a(i),b(i))+yoffset, [num2str(a(i)) ', ' num2str(b(i))])
    end
end
    

