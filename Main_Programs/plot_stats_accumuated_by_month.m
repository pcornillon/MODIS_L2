function gradStructure = plot_stats_accumuated_by_month( figNo, yearsToProcess, temporalIntervals)
%

figNo = figNo - 1;
axisFontSize = 18;
titleFontSize = 30;

plot_with_imagesc = 0;
generateLandMask = 0;

cmap = jet(256); % Example colormap (jet) with 256 colors
colormap(cmap);

% Set color for NaN values (gray) using the axes background color
set(gca, 'Color', [0.7 0.7 0.7]); % Gray background for NaN values

load coastlines; % MATLAB built-in coastline data

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

filelist = dir('~/Dropbox/Data/MODIS_L2/gradient_stats_by_period/monthly_stats_*');

for iFile=1:length(filelist)
    filename = [filelist(iFile).folder '/' filelist(iFile).name];

    monthYearString = extractBetween( filename, 'monthly_stats_', '.nc');

    monthThisFile = str2num(monthYearString{1}(1:2));
    yearThisFile = str2num(monthYearString{1}(4:7));

    if sum(yearThisFile == yearsToProcess) > 0

        switch temporalIntervals
            case 'Years'
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

meanGradMag = (dayGradMagSum + nightGradMagSum) ./ (dayCountSum + nightCountSum);

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

figNo = figNo + 1;
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
title('Daytime Eastward Gradient', fontsize=titleFontSize)

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
title('Daytime Northward Gradient', fontsize=titleFontSize)

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
title('Nighttime Eastward Gradient', fontsize=titleFontSize)

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
title('Nighttime Northward Gradient', fontsize=titleFontSize)

%% Plot gradient magnitudes.

figNo = figNo + 1;
figure(figNo)
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
title('Nighttime Gradient Magnitude', fontsize=titleFontSize)

%% Plot day and night gradient magnitudes together, first with pcolor

figNo = figNo + 1;
figure(figNo)
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
title('Mean Gradient Magnitude', fontsize=titleFontSize)

%% Plot the combined number of counts from day and night

figNo = figNo + 1;
figure(figNo)
clf

if plot_with_imagesc
    imagesc(lonVector, latVector, log10((dayCountSum + nightCountSum)/length(filelist)))
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
    maxVal = max(log10((dayCountSum + nightCountSum)/length(filelist)), [], 'all', 'omitnan');
    caxis([0 floor(maxVal)+2])
end
colorbar
xlabel('Longitude')
ylabel('Latitude')
set(gca, fontsize=axisFontSize, ydir="normal")
title('log_{10} of Monthly Average of Number of Day + Night Counts', fontsize=titleFontSize)
