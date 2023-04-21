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

test = [2 3];
laptop = 0;
region = 2;

% Method = 'linear';
Method = 'nearest';

% Turn off warnings for duplicate values in griddata.

id = 'MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId';
warning('off',id)

% Read the data from the file if it is not already in memory.

if ~exist('fi_orbit')
    if laptop
        fi_orbit = '~/Desktop/AQUA_MODIS_orbit_41675_20100305T012144_L2_SST.nc4';
    else
        fi_orbit = '/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/03/AQUA_MODIS_orbit_41675_20100305T012144_L2_SST.nc4';
    end
    
    SST_In = ncread(fi_orbit, 'SST_In');
    lat = ncread(fi_orbit, 'latitude');
    lon = ncread(fi_orbit, 'longitude');
    regridded_lon = ncread(fi_orbit, 'regridded_longitude');
    regridded_lat = ncread(fi_orbit, 'regridded_latitude');
end

clear yy*

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
        jEnd = 2550;
end

xx = SST_In(iStart:iEnd,jStart:jEnd);
latxx = lat(iStart:iEnd,jStart:jEnd);
lonxx = lon(iStart:iEnd,jStart:jEnd);
regridded_latxx = regridded_lat(iStart:iEnd,jStart:jEnd);
regridded_lonxx = regridded_lon(iStart:iEnd,jStart:jEnd);

yy = griddata( lonxx, latxx, xx, regridded_lonxx, regridded_latxx, 'linear');

[nPixels, nScanlines] = size(xx);

locs1 = zeros(numel(xx),5);

weights = zeros(5,nPixels,nScanlines);
locations = zeros(5,nPixels,nScanlines);

if test ~= 10
    for iTest=test
        iGrid = 0;
        for iScans=1:nScanlines
            tic
            for iPixel=1:nPixels
                
                iGrid = iGrid + 1;
                
                pixloc(iGrid) = iPixel;
                scaloc(iGrid) = iScans;
                
                xxp = zeros(size(xx));
                
                switch iTest
                    case 1
                        xxp(iPixel,iScans) =  xx(iPixel,iScans);
                        yy1(iGrid,:,:) = griddata( lonxx, latxx, xxp, regridded_lonxx, regridded_latxx, Method);
                        
                    case 2
                        xxp(iPixel,iScans) =  1;
                        yy2(iGrid,:,:) = griddata( lonxx, latxx, xxp, regridded_lonxx, regridded_latxx, Method);
                        
                        nn = find( yy2(iGrid,:,:) ~= 0);
                        if ~isempty(nn)
                            for iNum=1:length(nn)
                                locs1(iGrid,iNum) = nn(iNum);
                            end
                        end
                        
                    case 3
                        xxp(iPixel,iScans) =  1;
                        yy3(:,:) = griddata( lonxx, latxx, xxp, regridded_lonxx, regridded_latxx, Method);
                        
                        nn = find( yy3(:,:) ~= 0);
                        if ~isempty(nn)
                            for iNum=1:length(nn)
                                [a, b] = ind2sub(size(xx),nn(iNum));
%                                 if weights(iNum,a,b) ~= 0
%                                     keyboard
%                                 end
                                
                                weights(iNum,a,b) = yy3(a,b);
                                locations(iNum,a,b) = sub2ind(size(xx), iPixel, iScans);
                            end
                        end
                end
                
                
            end
            
            fprintf('%f s to process iPixel %i\n', toc, iScans)
        end
        
        % Sum the arrays and plot
        
        switch iTest
            case 1
                yy1s = squeeze(sum(yy1,1,'omitnan'));
                
                figure(1)
                clf
                imagesc(yy1s')
                
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
                
                figure(2)
                clf
                imagesc(yy2s')
                
            case 3
%                 yy3s = fast_interpolate_SST_linear( weights, locations, xx);
                
                SST_Out = zeros(size(xx));
                
                for iC=1:size(weights,1)
                    weights_temp = squeeze(weights(iC,:,:));
                    locations_temp = squeeze(locations(iC,:,:));
                    
                    good_weights = find( (weights_temp ~= 0) & (isnan(weights_temp) == 0) & (locations_temp ~= 0));
                    tt = locations_temp(good_weights);
                    
                    SST_temp = zeros(size(xx));
%                     SST_temp(good_weights(isnan(tt)==0)) = weights_temp(good_weights(isnan(tt)==0)) .* SST_In(tt(isnan(tt)==0));
                    SST_temp(good_weights) = weights_temp(good_weights) .* SST_In(tt);
                    
%                     mm = find( (isnan(tt)==0) & (tt~=0));
%                     SST_temp(good_weights(mm)) = weights_temp(good_weights(mm)) .* SST_In(tt(mm));
                    
                    SST_Out = SST_Out + SST_temp;
                end
%                 
%                 figure(3)
%                 clf
%                 imagesc(SST_Out')

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
        
        for iScans=1:nScanlines
            iGrid = iGrid + 1;
            dist_along_track = sqrt( (lat(iPixel,1:end-1)-lat(10,2:end)).^2 + (cosd(lat(10,1:end-1)) .* (lon(10,1:end-1)-lon(10,2:end)))).^2
        end
        
        
        iGrid = 0;
        for Pixel=1:nPixels
            tic
            for iScans=1:nScanlines
                iGrid = iGrid + 1;
                dist_along_track = sqrt( (lat(10,1:end-1)-lat(10,2:end)).^2 + (cosd(lat(10,1:end-1)) .* (lon(10,1:end-1)-lon(10,2:end)))).^2
            end
        end
    end
end
            
            
