function gradStructure = plot_stats_accumuated_by_month( figNo, yearsToProcess, temporalIntervals)
%
% Usage: To plot a number of years use the following. 
%
% This will run the plotting function three times, plotting 4 figures. The
% figure number will be the year - 2000 with 1 to 4 appended to the end. So
% for 2008 they will be figures 81, 82, 83, 84 and for 2018, 181. 182, 183,
% 184
%
% for iYear=[2008 2011 2018]
%     yearS = num2str(iYear);
%     year2dS = num2str(iYear - 2000);
%     eval(['gradStructure = plot_stats_accumuated_by_month( ' year2dS '1, [' yearS '], ''Years'');'])
% end
%
% You can, of course just run it on its own. To do plots for 2008 through 2010
% starting with figure #1: gradStructure = plot_stats_accumuated_by_month( 1, [2008:2010], 'Years')

axisFontSize = 18;
titleFontSize = 30;

plot_with_imagesc = 0;
generateLandMask = 0;

cmap = jet(256); % Example colormap (jet) with 256 colors
colormap(cmap);

% Set color for NaN values (gray) using the axes background color
set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values

load coastlines; % MATLAB built-in coastline data

% Meander peak locations found in Agulhas in 2008

mpx = [28.5183
   34.1728
   42.0890
   48.1204
   52.8325
   57.7330
   62.2565];

mpy = [-36.8863
  -37.1499
  -37.9407
  -38.8633
  -39.5222
  -40.8402
  -41.6310];

dayCountSum = zeros(180,360);
dayEastGrad =  zeros(180,360);
dayNorthGrad =  zeros(180,360);
dayGradMagSum = zeros(180,360);

dayGradMagHist = zeros(1,300);

nightCountSum = zeros(180,360);
nightEastGrad =  zeros(180,360);
nightNorthGrad =  zeros(180,360);
nightGradMagSum = zeros(180,360);

nightGradMagHist = zeros(1,300);

latVector = -89.5:1:89.5;
lonVector = -179.5:1:179.5;

% Use the `inpolygon` function to mask land areas
if generateLandMask
    [xGrid, yGrid] = meshgrid(lonVector, latVector);
    inLand = inpolygon(xGrid, yGrid, coastlon, coastlat);
else
    load('/Users/petercornillon/Dropbox/Data/MODIS_L2/gradient_stats_by_period/landMask')
end

yearsText = '';
if length(yearsToProcess) == 1
    yearsText = num2str(yearsToProcess);
end

filelist = dir('~/Dropbox/Data/MODIS_L2/gradient_stats_by_period/monthly_stats_*');

numMonths = 0;
for iFile=1:length(filelist)
    filename = [filelist(iFile).folder '/' filelist(iFile).name];

    monthYearString = extractBetween( filename, 'monthly_stats_', '.nc');

    monthThisFile = str2num(monthYearString{1}(1:2));
    yearThisFile = str2num(monthYearString{1}(4:7));

    if sum(yearThisFile == yearsToProcess) > 0

        switch temporalIntervals
            case 'Years'
                numMonths = numMonths + 1;

                dayCountSum = dayCountSum + ncread(filename, 'day_pixel_count');
                dayEastGrad = dayEastGrad + ncread(filename, 'day_sum_eastward_gradient');
                dayNorthGrad = dayNorthGrad + ncread(filename, 'day_sum_northward_gradient');
                dayGradMagSum = dayGradMagSum + ncread(filename, 'day_sum_magnitude_gradient');

                nightCountSum = nightCountSum + ncread(filename, 'night_pixel_count');
                nightEastGrad = nightEastGrad + ncread(filename, 'night_sum_eastward_gradient');
                nightNorthGrad = nightNorthGrad + ncread(filename, 'night_sum_northward_gradient');
                nightGradMagSum = nightGradMagSum + ncread(filename, 'night_sum_magnitude_gradient');

                [N, edges] = histcounts(ncread(filename, 'day_sum_magnitude_gradient')./ncread(filename, 'day_pixel_count'), 0:0.001:0.3);
                dayGradMagHist = dayGradMagHist + N;

                [N, edges] = histcounts(ncread(filename, 'night_sum_magnitude_gradient')./ncread(filename, 'night_pixel_count'), 0:0.001:0.3);
                nightGradMagHist = nightGradMagHist + N;

            case 'Seasons'

            case 'Months'

            otherwise
        end
    end
end

dayMeanEastGrad = dayEastGrad ./ dayCountSum;
dayMeanNorthGrad = dayNorthGrad ./ dayCountSum;
dayMeanGradMag = dayGradMagSum ./ dayCountSum;

nightMeanEastGrad = nightEastGrad ./ nightCountSum;
nightMeanNorthGrad = nightNorthGrad ./ nightCountSum;
nightMeanGradMag = nightGradMagSum ./ nightCountSum;

meanEastGrad = (dayEastGrad + nightEastGrad) ./ (dayCountSum + nightCountSum);
meanNorthGrad = (dayNorthGrad + nightNorthGrad) ./ (dayCountSum + nightCountSum);

meanEastwardGradient = (dayGradMagSum + nightGradMagSum) ./ (dayCountSum + nightCountSum);

gradStructure.dayMeanEastGrad = dayMeanEastGrad;
gradStructure.dayMeanNorthGrad = dayMeanNorthGrad;
gradStructure.dayMeanGradMag = dayMeanGradMag;

gradStructure.dayGradMagHist = dayGradMagHist;
gradStructure.edges = edges;

gradStructure.nightMeanEastGrad = nightMeanEastGrad;
gradStructure.nightMeanNorthGrad = nightMeanNorthGrad;
gradStructure.nightMeanGradMag = nightMeanGradMag;

gradStructure.nightGradMagHist = nightGradMagHist;

%% Plot eastward and northward gradient images

figure(figNo)
clf

subplot(221)
if plot_with_imagesc
    imagesc(lonVector, latVector, dayMeanEastGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = dayMeanEastGrad;
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

subplot(222)
if plot_with_imagesc
    imagesc(lonVector, latVector, dayMeanNorthGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = dayMeanNorthGrad;
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
title(['Daytime Northward Gradient (' yearsText ')'], fontsize=titleFontSize)

subplot(223)
if plot_with_imagesc
    imagesc(lonVector, latVector, nightMeanEastGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = nightMeanEastGrad;
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
title(['Nighttime Eastward Gradient (' yearsText ')'], fontsize=titleFontSize)

subplot(224)
if plot_with_imagesc
    imagesc(lonVector, latVector, nightMeanNorthGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = nightMeanNorthGrad;
    maskedData(inLand) = NaN;

    pcolor(lonVector, latVector, maskedData)
    shading flat

    cmap = jet(256); % Example colormap (jet) with 256 colors
    colormap(cmap);

    % Set color for NaN values (gray) using the axes background color
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values
end
colormap("jet")
colorbar
caxis([-0.03 0.03])
xlabel('Longitude')
ylabel('Latitude')
set(gca, fontsize=axisFontSize, ydir="normal")
title(['Nighttime Northward Gradient (' yearsText ')'], fontsize=titleFontSize)

%% Plot gradient magnitudes.

figure(figNo+1)
clf
subplot(211)
if plot_with_imagesc
    imagesc(lonVector, latVector, dayMeanGradMag)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = dayMeanGradMag;
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
    imagesc(lonVector, latVector, nightMeanGradMag)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = nightMeanGradMag;
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
    imagesc(lonVector, latVector, meanGradMag)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = meanGradMag;
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
    imagesc(lonVector, latVector, log10((dayCountSum + nightCountSum)/(2 * numMonths)))
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = log10((dayCountSum + nightCountSum)/length(filelist));
    maskedData(inLand) = NaN;
    pcolor(lonVector, latVector, maskedData)
    shading flat
    cmap = jet(256); % Example colormap (jet) with 256 colors
    colormap(cmap);
    % Set color for NaN values (gray) using the axes background color
    set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values

    % Set the color scale to be a couple of orders of orders of magnitude
    % larger than the largest value.
    maxVal = max(log10((dayCountSum + nightCountSum)/(2 * numMonths)), [], 'all', 'omitnan');
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
    imagesc(lonVector, latVector, meanEastGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = meanEastGrad;
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
title(['Mean Eastward Gradient (' yearsText ')'], fontsize=titleFontSize)

%% Plot day and night northward gradients together.
figure(figNo+5)
clf

if plot_with_imagesc
    imagesc(lonVector, latVector, meanNorthGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = meanNorthGrad;
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
title(['Mean Northward Gradient (' yearsText ')'], fontsize=titleFontSize)

%% Additional annotation

% Add meander peak locations from 2008 to mean grad mag for day + night as
% well as in the daytime eastward gradient.

figure(figNo)
subplot(221)
hold on
plot(mpx, mpy, 'ok', markerfacecolor='k', markersize=5)
axis([10 100 -70 -30])

for iPlotIndex=[2 4 5]
    figure(figNo+iPlotIndex)
    hold on
    plot(mpx, mpy, 'ok', markerfacecolor='r', markersize=5)
end

