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

% % Old meander peak locations found in Agulhas in 2008
% 
% gradStructure.mpx = [28.5183
%    34.1728
%    42.0890
%    48.1204
%    52.8325
%    57.7330
%    62.2565
%    68.4538
%    74.5154];
% 
% gradStructure.mpy = [-36.8863
%   -37.1499
%   -37.9407pu
%   -38.8633
%   -39.5222
%   -40.8402
%   -41.6310
%   -41.0075
%   -42.4880];

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

%% Initialize counters

gradStructure.dayCountSum = zeros(180,360);
gradStructure.dayEastGrad =  zeros(180,360);
gradStructure.dayNorthGrad =  zeros(180,360);
gradStructure.dayGradMagSum = zeros(180,360);

gradStructure.dayGradMagHist = zeros(1,300);

gradStructure.nightCountSum = zeros(180,360);
gradStructure.nightEastGrad =  zeros(180,360);
gradStructure.nightNorthGrad =  zeros(180,360);
gradStructure.nightGradMagSum = zeros(180,360);

gradStructure.nightGradMagHist = zeros(1,300);

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
elseif length(yearsToProcess) == 2
    yearsText = [num2str(yearsToProcess(1)) ' & ' num2str(yearsToProcess(2))];
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

                gradStructure.dayCountSum = gradStructure.dayCountSum + ncread(filename, 'day_pixel_count');
                gradStructure.dayEastGrad = gradStructure.dayEastGrad + ncread(filename, 'day_sum_eastward_gradient');
                gradStructure.dayNorthGrad = gradStructure.dayNorthGrad + ncread(filename, 'day_sum_northward_gradient');
                gradStructure.dayGradMagSum = gradStructure.dayGradMagSum + ncread(filename, 'day_sum_magnitude_gradient');

                gradStructure.nightCountSum = gradStructure.nightCountSum + ncread(filename, 'night_pixel_count');
                gradStructure.nightEastGrad = gradStructure.nightEastGrad + ncread(filename, 'night_sum_eastward_gradient');
                gradStructure.nightNorthGrad = gradStructure.nightNorthGrad + ncread(filename, 'night_sum_northward_gradient');
                gradStructure.nightGradMagSum = gradStructure.nightGradMagSum + ncread(filename, 'night_sum_magnitude_gradient');

                [N, edges] = histcounts(ncread(filename, 'day_sum_magnitude_gradient')./ncread(filename, 'day_pixel_count'), 0:0.001:0.3);
                gradStructure.dayGradMagHist = gradStructure.dayGradMagHist + N;

                [N, edges] = histcounts(ncread(filename, 'night_sum_magnitude_gradient')./ncread(filename, 'night_pixel_count'), 0:0.001:0.3);
                gradStructure.nightGradMagHist = gradStructure.nightGradMagHist + N;

            case 'Seasons'

            case 'Months'

            otherwise
        end
    end
end

gradStructure.dayMeanEastGrad = gradStructure.dayEastGrad ./ gradStructure.dayCountSum;
gradStructure.dayMeanNorthGrad = gradStructure.dayNorthGrad ./ gradStructure.dayCountSum;
gradStructure.dayMeanGradMag = gradStructure.dayGradMagSum ./ gradStructure.dayCountSum;

gradStructure.nightMeanEastGrad = gradStructure.nightEastGrad ./ gradStructure.nightCountSum;
gradStructure.nightMeanNorthGrad = gradStructure.nightNorthGrad ./ gradStructure.nightCountSum;
gradStructure.nightMeanGradMag = gradStructure.nightGradMagSum ./ gradStructure.nightCountSum;

gradStructure.meanEastGrad = (gradStructure.dayEastGrad + gradStructure.nightEastGrad) ./ (gradStructure.dayCountSum + gradStructure.nightCountSum);
gradStructure.meanNorthGrad = (gradStructure.dayNorthGrad + gradStructure.nightNorthGrad) ./ (gradStructure.dayCountSum + gradStructure.nightCountSum);
gradStructure.meanGradMag = (gradStructure.dayGradMagSum + gradStructure.nightGradMagSum) ./ (gradStructure.dayCountSum + gradStructure.nightCountSum);

% gradStructure.dayMeanEastGrad = dayMeanEastGrad;
% gradStructure.dayMeanNorthGrad = dayMeanNorthGrad;
% gradStructure.dayMeanGradMag = dayMeanGradMag;
% 
% gradStructure.dayGradMagHist = dayGradMagHist;
% gradStructure.edges = edges;
% 
% gradStructure.nightMeanEastGrad = nightMeanEastGrad;
% gradStructure.nightMeanNorthGrad = nightMeanNorthGrad;
% gradStructure.nightMeanGradMag = nightMeanGradMag;
% 
% gradStructure.nightGradMagHist = nightGradMagHist;

%% Plot eastward and northward gradient images

figure(figNo)
clf

subplot(221)
if plot_with_imagesc
    imagesc(lonVector, latVector, gradStructure.dayMeanEastGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = gradStructure.dayMeanEastGrad;
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
    imagesc(lonVector, latVector, gradStructure.dayMeanNorthGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = gradStructure.dayMeanNorthGrad;
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
    imagesc(lonVector, latVector, gradStructure.nightMeanEastGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = gradStructure.nightMeanEastGrad;
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
    imagesc(lonVector, latVector, gradStructure.nightMeanNorthGrad)
    colormap("jet")
else
    % Set land areas to NaN
    maskedData = gradStructure.nightMeanNorthGrad;
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

