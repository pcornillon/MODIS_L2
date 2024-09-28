function gradStructure = plot_gradient_trends( figNo, yearsToProcess, temporalIntervals, Title_to_Plot)
%

axisFontSize = 18;
titleFontSize = 30;

plot_with_imagesc = 0;
plot_peaks = 1;
generateLandMask = 0;
generateBathy = 0;

cmap = jet(256); % Example colormap (jet) with 256 colors
colormap(cmap);

% Set color for NaN values (gray) using the axes background color
set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values

load coastlines; % MATLAB built-in coastline data

% New meander peaks found in 2008-2012 & 2008-2009

gradStructure.mpx = [28.5359
    34.5236
    41.0287
    45.9076
    52.5606
    57.3655
    61.5791
    68.4538
    73.7023];


gradStructure.mpy = [-36.8403
    -37.1145
    -38.1563
    -38.9239
    -39.0336
    -40.8979
    -42.9267
    -41.0624
    -42.7622];

lonTrough = (gradStructure.mpx(1:length(gradStructure.mpx)-1) + gradStructure.mpx(2:length(gradStructure.mpx))) / 2;
latTrough = (gradStructure.mpy(1:length(gradStructure.mpy)-1) + gradStructure.mpy(2:length(gradStructure.mpy))) / 2;

% Calculate separation of peaks.

gradStructure.peak_separation_lon = diff(gradStructure.mpx);
gradStructure.peak_separation_lat = diff(gradStructure.mpy);
gradStructure.peak_separation = sqrt(gradStructure.peak_separation_lat.^2 + (cosd(latTrough) .* gradStructure.peak_separation_lon).^2) * 111;

if plot_peaks
    figure(1)
    clf
    % plot(gradStructure.peak_separation, linewidth=1)
    % hold on
    plot(gradStructure.peak_separation, 'ok', markerfacecolor='r', markersize=20)
    ylim([0 750])
    xlim([0 9])
    hold on
    grid on
    plot( [0 length(gradStructure.peak_separation)+1], [1 1]*mean(gradStructure.peak_separation), 'k')
    xlabel('Trough Number')
    ylabel('Separation of Peaks (km)')
    text( 8, mean(gradStructure.peak_separation)+20, ['$\overline{\lambda}$: ' num2str(mean(gradStructure.peak_separation),3) ' km '], fontsize=titleFontSize, Interpreter='latex')
    for iTrough=1:length(lonTrough)
        text( iTrough, gradStructure.peak_separation(iTrough)-40, ['(' num2str(lonTrough(iTrough),4) ', ' num2str(latTrough(iTrough),4) ') '], fontsize=axisFontSize, Interpreter='latex', HorizontalAlignment='center')
    end
    set(gca,fontsize=axisFontSize)
    title('Separation of Meander Peaks', FontSize=titleFontSize)
end

% Initialize arrays

gradStructure.day_counts = ncread(filename, 'day_pixel_count');
gradStructure.night_counts = ncread(filename, 'day_pixel_count');

gradStructure.dayMeanEastGrad = nan((2024-2001)*12, 180, 360);
gradStructure.dayMeanNorthGrad = nan((2024-2001)*12, 180, 360);
gradStructure.dayMeanGradMag = nan((2024-2001)*12, 180, 360);

gradStructure.nightMeanEastGrad = nan((2024-2001)*12, 180, 360);
gradStructure.nightMeanNorthGrad = nan((2024-2001)*12, 180, 360);
gradStructure.nightMeanGradMag = nan((2024-2001)*12, 180, 360);

gradStructure.meanEastGrad = nan((2024-2001)*12, 180, 360);
gradStructure.meanNorthGrad = nan((2024-2001)*12, 180, 360);
gradStructure.meanGradMag = nan((2024-2001)*12, 180, 360);

xDateTimeIndex = 1:(2024-2001) * 12;

latVector = -89.5:1:89.5;
lonVector = -179.5:1:179.5;

load('/Users/petercornillon/Dropbox/Data/MODIS_L2/gradient_stats_by_period/landMask')

filelist = dir('~/Dropbox/Data/MODIS_L2/gradient_stats_by_period/monthly_stats_*');

lastYearMonthIndex = 0;

numMonths = 0;
% for iFile=1:length(filelist)
for iFile=1:5
    filename = [filelist(iFile).folder '/' filelist(iFile).name];

    monthYearString = extractBetween( filename, 'monthly_stats_', '.nc');

    monthIndex = str2num(monthYearString{1}(1:2));
    yearIndex = str2num(monthYearString{1}(4:7)) - 2001;
    dateTimeIndex = (yearIndex - 1) * 12 + monthIndex;

    lastYearMonthIndex = max(lastYearMonthIndex, dateTimeIndex);

    gradStructure.day_counts(dateTimeIndex,:,:) = ncread(filename, 'day_pixel_count');
    gradStructure.night_counts(dateTimeIndex,:,:) = ncread(filename, 'day_pixel_count');

    gradStructure.dayMeanEastGrad(dateTimeIndex,:,:) = ncread(filename, 'day_sum_eastward_gradient') ./ gradStructure.day_counts;
    gradStructure.dayMeanNorthGrad(dateTimeIndex,:,:) = ncread(filename, 'day_sum_northward_gradient') ./ gradStructure.day_counts;
    gradStructure.dayMeanGradMag(dateTimeIndex,:,:) = ncread(filename, 'day_sum_magnitude_gradient') ./ gradStructure.day_counts;

    gradStructure.nightMeanEastGrad(dateTimeIndex,:,:) = ncread(filename, 'night_sum_eastward_gradient') ./ gradStructure.night_counts;
    gradStructure.nightMeanNorthGrad(dateTimeIndex,:,:) = ncread(filename, 'night_sum_northward_gradient') ./ gradStructure.night_counts;
    gradStructure.nightMeanGradMag(dateTimeIndex,:,:) = ncread(filename, 'night_sum_magnitude_gradient') ./ gradStructure.night_counts;

    gradStructure.meanEastGrad(dateTimeIndex,:,:) = (ncread(filename, 'day_sum_eastward_gradient') + ncread(filename, 'night_sum_eastward_gradient')) ./ (gradStructure.day_counts + gradStructure.night_counts);
    gradStructure.meanNorthGrad(dateTimeIndex,:,:) = (ncread(filename, 'day_sum_northward_gradient') + ncread(filename, 'night_sum_northward_gradient')) ./ (gradStructure.day_counts + gradStructure.night_counts);
    gradStructure.meanGradMag(dateTimeIndex,:,:) = (ncread(filename, 'day_sum_magnitude_gradient') + ncread(filename, 'night_sum_magnitude_gradient')) ./ (gradStructure.day_counts + gradStructure.night_counts);
end

%% Get trends

for iLon=1:360
    for iLat=1:180
        y = gradStructure.meanGradMag(:,iLat,iLon);
        nn = find(isnan(y)==0);
        yGood = y(nn);
        xGood = xDateTimeIndex(nn);
        
        pp = polyfit( xGood, yGood, 1);
        gradStructure.slope(iLat,iLon) = pp(1);
        intercept(iLat,iLon) = pp(2);
    end
end

        
%% Plot slope of gradient magnitude

figure(figNo)
clf

if plot_with_imagesc
    imagesc(lonVector, latVector, gradStructure.slope)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = gradStructure.slope;
    maskedData(inLand) = NaN;

    pcolor(lonVector, latVector, maskedData)
    shading flat

    cmap = jet(256); % Example colormap (jet) with 256 colors
    colormap(cmap);

    % Set color for NaN values (gray) using the axes background color
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values
end
colorbar
caxis([-0.03 0.03])
xlabel('Longitude')
ylabel('Latitude')
set(gca, fontsize=axisFontSize, ydir="normal")
title(['Daytime Eastward Gradient (' yearsText ')'], fontsize=titleFontSize)

%% Plot gradient magnitudes.

figure(figNo+1)
clf
subplot(211)
if plot_with_imagesc
    imagesc(lonVector, latVector, gradStructure.dayMeanGradMag)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = gradStructure.dayMeanGradMag;
    maskedData(inLand) = NaN;
    pcolor(lonVector, latVector, maskedData)
    shading flat
    cmap = jet(256); % Example colormap (jet) with 256 colors
    colormap(cmap);
    % Set color for NaN values (gray) using the axes background color
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values
end
colorbar
caxis([0 0.15])
xlabel('Longitude')
ylabel('Latitude')
set(gca, fontsize=axisFontSize, ydir="normal")
title('Daytime Gradient Magnitude', fontsize=titleFontSize)

subplot(212)
if plot_with_imagesc
    imagesc(lonVector, latVector, gradStructure.nightMeanGradMag)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = gradStructure.nightMeanGradMag;
    maskedData(inLand) = NaN;
    pcolor(lonVector, latVector, maskedData)
    shading flat
    cmap = jet(256); % Example colormap (jet) with 256 colors
    colormap(cmap);
    % Set color for NaN values (gray) using the axes background color
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values
end
colorbar
caxis([0 0.15])
xlabel('Longitude')
ylabel('Latitude')
set(gca, fontsize=axisFontSize, ydir="normal")
title(['Nighttime Gradient Magnitude (' yearsText ')'], fontsize=titleFontSize)

%% Plot day and night gradient magnitudes together, first with pcolor

figure(figNo+2)
clf

if plot_with_imagesc
    imagesc(lonVector, latVector, gradStructure.meanGradMag)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = gradStructure.meanGradMag;
    maskedData(inLand) = NaN;
    pcolor(lonVector, latVector, maskedData)
    shading flat
    cmap = jet(256); % Example colormap (jet) with 256 colors
    colormap(cmap);
    % Set color for NaN values (gray) using the axes background color
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values
end
colorbar
caxis([0 0.15])
xlabel('Longitude')
ylabel('Latitude')
set(gca, fontsize=axisFontSize, ydir="normal")
title(['Mean Gradient Magnitude (' yearsText ')'], fontsize=titleFontSize)

%% Plot the combined number of counts from day and night

figure(figNo+3)
clf

if plot_with_imagesc
    imagesc(lonVector, latVector, log10((gradStructure.dayCountSum + gradStructure.nightCountSum)/(2 * numMonths)))
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = log10((gradStructure.dayCountSum + gradStructure.nightCountSum)/length(filelist));
    maskedData(inLand) = NaN;
    pcolor(lonVector, latVector, maskedData)
    shading flat
    cmap = jet(256); % Example colormap (jet) with 256 colors
    colormap(cmap);
    % Set color for NaN values (gray) using the axes background color
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values

    % Set the color scale to be a couple of orders of orders of magnitude
    % larger than the largest value.
    maxVal = max(log10((gradStructure.dayCountSum + gradStructure.nightCountSum)/(2 * numMonths)), [], 'all', 'omitnan');
    caxis([0 floor(maxVal)+2])
end
colorbar
xlabel('Longitude')
ylabel('Latitude')
set(gca, fontsize=axisFontSize, ydir="normal")
title(['log_{10} of Monthly Average of Number of Day + Night Counts (' yearsText ')'], fontsize=titleFontSize)

%% Plot day and night eastward gradients together.
figure(figNo+4)
clf

if plot_with_imagesc
    imagesc(lonVector, latVector, gradStructure.meanEastGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = gradStructure.meanEastGrad;
    maskedData(inLand) = NaN;
    pcolor(lonVector, latVector, maskedData)
    shading flat
    cmap = jet(256); % Example colormap (jet) with 256 colors
    colormap(cmap);
    % Set color for NaN values (gray) using the axes background color
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values
end
colorbar
caxis([-0.03 0.03])
xlabel('Longitude')
ylabel('Latitude')
set(gca, fontsize=axisFontSize, ydir="normal")
title(['Mean Eastward Gradient (' yearsText ')'], fontsize=titleFontSize)

%% Plot day and night northward gradients together.
figure(figNo+5)
clf

if plot_with_imagesc
    imagesc(lonVector, latVector, gradStructure.meanNorthGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = gradStructure.meanNorthGrad;
    maskedData(inLand) = NaN;
    pcolor(lonVector, latVector, maskedData)
    shading flat
    cmap = jet(256); % Example colormap (jet) with 256 colors
    colormap(cmap);
    % Set color for NaN values (gray) using the axes background color
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values
end
colorbar
caxis([-0.03 0.03])
xlabel('Longitude')
ylabel('Latitude')
set(gca, fontsize=axisFontSize, ydir="normal")
title(['Mean Northward Gradient (' yearsText ')'], fontsize=titleFontSize)

%% Plot bathy - get bathy data first

if generateBathy
    FIBathy = '~/Dropbox/Data/gebco_2020_netcdf/GEBCO_2020.nc';

    bathyLon = ncread(FIBathy, 'lon', 1, 86399/10, 10);
    bathyLat = ncread(FIBathy, 'lat', 1, 43199/10, 10);
    elevation = ncread( FIBathy, 'elevation', [1 1], [86399/10 43199/10], [10 10]);
else
    load('/Users/petercornillon/Dropbox/Data/MODIS_L2/gradient_stats_by_period/bathymetry', 'bathyLon', 'bathyLat', 'elevation')
end

figure(999)
clf

% if plot_with_imagesc
imagesc(bathyLon, bathyLat, elevation')
colormap("jet")
% else
%     % Set land areas to NaN
%     % maskedData = elevation;
%     % maskedData(inLand) = NaN;
%     pcolor(bathyLon, bathyLat, elevation')
%     shading flat
%     cmap = jet(256); % Example colormap (jet) with 256 colors
%     colormap(cmap);
%     % set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values
% end
hold on
plot(gradStructure.mpx, gradStructure.mpy, 'ok', markerfacecolor='k', markersize=10)
plot(coastlon, coastlat,'w',linewidth=3)

set(gca,fontsize=18, ydir='normal')
colorbar
caxis([-8000 1000])
axis([10 100 -70 -30])
xlabel('Longitude')
ylabel('Latitude')
set(gca, fontsize=axisFontSize, ydir="normal")
title('Bathymetry', fontsize=titleFontSize)

%% Additional annotation

% Add meander peak locations from 2008 to mean grad mag for day + night as
% well as in the daytime eastward gradient.

figure(figNo)
subplot(221)
hold on
plot(gradStructure.mpx, gradStructure.mpy, 'ok', markerfacecolor='k', markersize=5)
axis([10 100 -70 -30])

figure(figNo+2)
hold on
plot(gradStructure.mpx, gradStructure.mpy, 'ok', markerfacecolor='r', markersize=5)

for iPlotIndex=[4 5]
    figure(figNo+iPlotIndex)
    hold on
    plot(gradStructure.mpx, gradStructure.mpy, 'ok', markerfacecolor='k', markersize=5)
    axis([10 100 -70 -30])
end

%% Compare periods. Run after running the periods to compare.

plot_comparison = 0;
if plot_comparison

    % Set up for plotting

    load coastlines; % MATLAB built-in coastline data
    axisFontSize = 18;
    titleFontSize = 30;
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values

    % Load variables that don't change from run to run.

    gradStructure.mpx = gradStructure_2008_through_2010.mpx;
    gradStructure.mpy = gradStructure_2008_through_2010.mpy;
    gradStructure.peak_separation_lon = gradStructure_2008_through_2010.peak_separation_lon;
    gradStructure.peak_separation_lat = gradStructure_2008_through_2010.peak_separation_lat;
    gradStructure.peak_separation = gradStructure_2008_through_2010.peak_separation;
    latVector = -89.5:1:89.5;
    lonVector = -179.5:1:179.5;

    load('/Users/petercornillon/Dropbox/Data/MODIS_L2/gradient_stats_by_period/landMask')

    % Define the difference variable to plot.

    diffnightGradMagSum = gradStructure_2018_through_2020.meanGradMag - gradStructure_2008_through_2010.meanGradMag;
    maskedData = diffnightGradMagSum;
    maskedData(inLand) = NaN;

    % Initialize the figure and plot it.
    
    figure(901)
    clf

    pcolor(lonVector, latVector, maskedData)
    shading flat
    cmap = jet(256);
    colormap(cmap);
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values
    colorbar
    caxis([0 0.15])
    xlabel('Longitude')
    ylabel('Latitude')
    set(gca, fontsize=axisFontSize, ydir="normal")
    title(['Mean Gradient Magnitude Difference'], fontsize=titleFontSize)
    caxis([-1 1]*0.1)
    caxis([-1 1]*0.02)
    caxis([-1 1]*0.01)
    title(['Mean Gradient Magnitude (2018-2020) minus (2008-2020)'], fontsize=titleFontSize)
    
    % Now plot the percentage change.

    figure(902)
    clf

    maskedData = 100 * diffnightGradMagSum./((gradStructure_2018_through_2020.meanGradMag + gradStructure_2008_through_2010.meanGradMag)/2);
    maskedData(inLand) = NaN;
    
    pcolor(lonVector, latVector, maskedData)
    shading flat
    cmap = jet(256);
    colormap(cmap);
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values
    colorbar
    xlabel('Longitude')
    ylabel('Latitude')
    set(gca, fontsize=axisFontSize, ydir="normal")
    title(['Mean Gradient Magnitude Difference'], fontsize=titleFontSize)
    caxis([-1 1]*20)
    title(['Percent Mean Gradient Magnitude Change for (2018-2020) minus (2008-2020)'], fontsize=titleFontSize)
end