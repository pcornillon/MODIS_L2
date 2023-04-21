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

test = 1;

% Turn off warnings for duplicate values in griddata.

id = 'MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId';
warning('off',id)

% Read the data from the file if it is not already in memory.

if ~exist('fi_orbit')
    fi_orbit = '~/Desktop/AQUA_MODIS_orbit_41675_20100305T012144_L2_SST.nc4';
    SST_In = ncread(fi_orbit, 'SST_In');
    lat = ncread(fi_orbit, 'latitude');
    lon = ncread(fi_orbit, 'longitude');
    regridded_lon = ncread(fi_orbit, 'regridded_longitude');
    regridded_lat = ncread(fi_orbit, 'regridded_latitude');
end

% Carve out the area of interest.

xx = SST_In(1301:1350,2381:2600);
latxx = lat(1301:1350,2381:2600);
lonxx = lon(1301:1350,2381:2600);
regridded_latxx = regridded_lat(1301:1350,2381:2600);
regridded_lonxx = regridded_lon(1301:1350,2381:2600);

[nPixels, nScanlines] = size(xx);

if test ~= 0
    for test=1:3
        iGrid = 0;
        for iPixel=1:nPixels
            tic
            for iScans=1:nScanlines
                iGrid = iGrid + 1;
                
                xxp = zeros(size(xx));
                
                switch test
                    case 1
                        xxp(iPixel,iScans) =  xx(iPixel,iScans);
                        yy1(iGrid,:,:) = griddata( lonxx, latxx, xxp, regridded_lonxx, regridded_latxx, 'nearest');
                        
                    case 2
                        xxp(iPixel,iScans) =  1;
                        yy2(iGrid,:,:) = griddata( lonxx, latxx, xxp, regridded_lonxx, regridded_latxx, 'nearest');
                        
                    case 3
                        xxp(iPixel,iScans) =  1;
                        yy3(iGrid,:,:) = griddata( regridded_lonxx, regridded_latxx, xxp, lonxx, latxx, 'nearest');
                        
                end
                
                
            end
            
            fprintf('%f s to process iPixel %i\n', toc, iPixel)
        end
        
        % Sum the arrays and plot
        
        switch test
            case 1
                yy1s = squeeze(sum(yy1,1,'omitnan'));
                
                figure(1)
                clf
                imagesc(yy1s')
                
                figure(11)
                clf
                imagesc(squeeze(yy1(1000,:,:)))
                
            case 2
                for iPix=1:size(yy2,1)
                    yyp2(iPix,:,:) = squeeze(yy2(iPix,:,:)) .* xx;
                end
                yy2s = squeeze(sum(yyp2,1,'omitnan'));
                
                figure(2)
                clf
                imagesc(yy2s')
                
                figure(12)
                clf
                imagesc(squeeze(yyp2(1000,:,:)))
                
            case 3
                for iPix=1:size(yy3,1)
                    yyp3(iPix,:,:) = squeeze(yy3(iPix,:,:)) .* xx;
                end
                yy3s = squeeze(sum(yyp3,1,'omitnan'));
                
                figure(3)
                clf
                imagesc(yy3s')
                
                figure(13)
                clf
                imagesc(squeeze(yy3(1000,:,:)))
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
            
            
