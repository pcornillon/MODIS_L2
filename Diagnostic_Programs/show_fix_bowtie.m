function show_fix_bowtie
% show_fix_bowtie - function that plots the actual bow-tie stuff - PCC
%  

% Define global variables

global fi
global AXIS CAXIS_sst CAXIS_sst_diff_1 CAXIS_sst_diff_2 CAXIS_gm CAXIS_gm_diff
global XLIM HIST_SST HIST_GM_1 HIST_GM_2 HIST_GM_3 COUNTS_LIM ZOOM_RANGE
global title_fontsize axis_fontsize
global along_scan_seps_array along_track_seps_array

% Get sst data

sst_in = ncread( fi, 'SST_In_Masked');
sst_griddata = ncread( fi, 'regridded_sst_alternate');

dd_in_griddata = sst_in - sst_griddata;

% And get the gradient magnitudes and zoom in on the area of interest.

[~, ~, gm_in] = sobel_gradient_degrees_per_kilometer( ...
    sst_in, ...
    along_track_seps_array(:,1:size(sst_in,2)), ...
    along_scan_seps_array(:,1:size(sst_in,2)));

gm_in_z = gm_in(ZOOM_RANGE(1):ZOOM_RANGE(2), ZOOM_RANGE(3):ZOOM_RANGE(4));

[~, ~, gm_griddata] = sobel_gradient_degrees_per_kilometer( ...
    sst_griddata, ...
    along_track_seps_array(:,1:size(sst_griddata,2)), ...
    along_scan_seps_array(:,1:size(sst_griddata,2)));

gm_griddata_z = gm_griddata(ZOOM_RANGE(1):ZOOM_RANGE(2), ZOOM_RANGE(3):ZOOM_RANGE(4));


% Get list of orbits with fixed weights and locations

filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/*fixed.mat*');

% Loop over this list fast regridding using the weights and locations from
% the orbits with them.

iFig = 0;

for iFile=1:length(filelist)
    filename = [filelist(iFile).folder '/' filelist(iFile).name];
    
    nn = strfind(filelist(iFile).name, 'weights_and_locations_');
    orbit_no = filelist(iFile).name(nn+22:nn+26);
    
    fprintf('\n\n%i) Results for orbit number %s\n\n', iFile, orbit_no)
    
    % Get the weights and locations for this orbit.
    
    load(filename)
    
    % Regrid with this set of weights and locations
    
    [nElements, nScans] = size(sst_in);
    [nMax, mElements, mScans] = size(augmented_weights);
    
    % Truncate weights array to same number of scan lines as SST array.
    
    weights = augmented_weights(:,:,1:nScans);
    locations = augmented_locations(:,:,1:nScans);
    
    % Now regrid.
    
    sst_fast = zeros([nElements, nScans]);
    
    for iC=1:nMax
        weights_temp = squeeze(weights(iC,:,:));
        locations_temp = squeeze(locations(iC,:,:));
        
        non_zero_weights = find(weights_temp ~= 0);
        
        SST_temp = zeros([nElements, nScans]);
        SST_temp(non_zero_weights) = weights_temp(non_zero_weights) .* sst_in(locations_temp(non_zero_weights));
        
        sst_fast = sst_fast + SST_temp;
    end
    
    %% Now get stats and plot
    
    dd_in_fast = sst_in - sst_fast;
    dd_fast_griddata = sst_fast - sst_griddata;
    
%     % Plot sst differences betwee sst in and fast iterpolated version.
%     figure(1)
%     clf
%     
%     subplot(2,2,1)
%     
%     imagesc(sst_in')
%     set(gca,fontsize=axis_fontsize)
%     title('SST_{in}', fontsize=title_fontsize)
%     axis(AXIS)
%     caxis(CAXIS_sst)
%     colorbar
%     
%     subplot(2,2,2)
%     
%     imagesc(sst_fast')
%     set(gca,fontsize=axis_fontsize)
%     title('SST_{fast}', fontsize=title_fontsize)
%     axis(AXIS)
%     caxis(CAXIS_sst)
%     colorbar
%     
%     subplot(2,2,3)
%     
%     imagesc(dd_in_fast')
%     set(gca,fontsize=axis_fontsize)
%     title('In - Fast', fontsize=title_fontsize)
%     axis(AXIS)
%     caxis(CAXIS_sst_diff_1)
%     colorbar
%     
%     % Plot sst differences betwee fast iterpolated and griddata version.
%     subplot(2,2,4)
%     
%     imagesc(dd_fast_griddata')
%     set(gca,fontsize=axis_fontsize)
%     title('Fast - Griddata', fontsize=title_fontsize)
%     axis(AXIS)
%     caxis(CAXIS_sst_diff_2)
%     colorbar
    
    % Histogram differences
    iFig = iFile * 10 + 1;
    figure(iFig)
    clf
    
    hh = histogram(dd_in_fast, HIST_SST);
    hold on
    hh2 = histogram(dd_fast_griddata, HIST_SST);
    
    set(gca,fontsize=axis_fontsize)
    ylim([0 100000])
    xlabel('^\circ C')
    ylabel('Counts')
    xlim(XLIM)
    title(['SST Differences for Orbit ' num2str(orbit_no)], fontsize=title_fontsize)
    
    % Stats on sst differences
    
    sigma_in_fast = std(dd_in_fast(:),'omitnan');
    sigma_fast_griddata = std(dd_fast_griddata(:),'omitnan');
    fprintf('100 * sigma_fast / sigma_griddata %3.0f%%\n', 100 * sigma_fast_griddata / sigma_in_fast)
    
    % Now get gradient magnitudes for each of the fields.
    
    [~, ~, gm_fast] = sobel_gradient_degrees_per_kilometer( ...
        sst_fast, ...
        along_track_seps_array(:,1:size(sst_fast,2)), ...
        along_scan_seps_array(:,1:size(sst_fast,2)));
    
    % Get gradient magnitudes for zoomed in region
    
    gm_fast_z = gm_fast(ZOOM_RANGE(1):ZOOM_RANGE(2), ZOOM_RANGE(3):ZOOM_RANGE(4));

    % Plot gradients
    iFig = iFile * 10 + 2;
    figure(iFig)
    clf
    
    subplot(2,2,1)
    
    imagesc(gm_in_z')
    colorbar
    set(gca,fontsize=axis_fontsize)
    title('|\nabla SST_{in}|', fontsize=title_fontsize, interpreter='tex')
%     axis(AXIS)
    caxis(CAXIS_gm)
    colorbar
    
    subplot(2,2,2)
    
    imagesc((gm_griddata_z - gm_fast_z)')
    colorbar
    set(gca,fontsize=axis_fontsize)
    title('|\nabla SST_{griddata}| - |\nabla SST_{fast}|', fontsize=title_fontsize, interpreter='tex')
%     axis(AXIS)
    caxis(CAXIS_gm_diff)
    colorbar
    
    subplot(2,2,3)
    imagesc(gm_griddata_z')
    set(gca,fontsize=axis_fontsize)
    title('|\nabla SST_{griddata}|', fontsize=title_fontsize, interpreter='tex')
%     axis(AXIS)
    caxis(CAXIS_gm)
    colorbar
    
    subplot(2,2,4)
    imagesc(gm_fast_z')
    set(gca,fontsize=axis_fontsize)
    title('|\nabla SST_{fast}|', fontsize=title_fontsize, interpreter='tex')
%     axis(AXIS)
    caxis(CAXIS_gm)
    colorbar
      
    sgtitle(['Gradient Magnitudes for Orbit ' num2str(orbit_no)], fontsize=30)
    
    % And differences between sst in and the fast interpolation.
    dd_gm_in_fast = gm_in_z - gm_fast_z;
    dd_gm_fast_griddata = gm_fast_z - gm_griddata_z;
    
    % Histogram the differences between gradient magnitudes.
    iFig = iFile * 10 + 3;
    figure(iFig)
    clf
    
    hhgm1 = histogram(dd_gm_in_fast, HIST_GM_1);
    hold on
    hhgm2 = histogram(dd_gm_fast_griddata, HIST_GM_2);
    legend({'|\nabla{SST\_in}| - |\nabla{SST\_fast}|' '|\nabla{SST\_fast}| - |\nabla{SST\_griddata}|'})
    set(gca,fontsize=axis_fontsize)
    xlabel('K/km')
    ylabel('Counts')
    xlim(XLIM)
    title(['Gradient Magnitude Differences for Orbit ' num2str(orbit_no)], fontsize=title_fontsize)
    
    % And stats for these difference.
    sigma_gm_in_fast = std(dd_gm_in_fast(:),'omitnan');
    sigma_gm_fast_griddata = std(dd_gm_fast_griddata(:),'omitnan');
    
    fprintf('100 * sigma_gm_in_fast / sigma_gm_fast_griddata = %3.0f%%\n', 100 * sigma_gm_fast_griddata / sigma_gm_in_fast)

    %% Next histogram gradients for various parts of the distance from nadir
    iFig = iFile * 10 + 4;
    figure(iFig)
    clf
    
    subplot(131)
    
    xx1 = gm_in(1:300,:);
    xx2 = gm_fast(1:300,:);
    mm = find(xx1>0 & xx2>0);
    histogram(xx1(mm), [0:0.01:0.6])
    hold on
    histogram(xx2(mm), [0:0.01:0.6])
    
    set(gca,fontsize=axis_fontsize)
    xlabel('K/km')
    ylabel('Counts')
    title( 'Pixels 1-300', fontsize=title_fontsize)
    legend({'|\nabla{SST\_in}|' '|\nabla{SST\_fast}|'})
    
    subplot(132)
    
    xx1 = gm_in(677-150:677+150,:);
    xx2 = gm_fast(677-150:677+150,:);
    mm = find(xx1>0 & xx2>0);
    histogram(xx1(mm), [0:0.01:0.6])
    hold on
    histogram(xx2(mm), [0:0.01:0.6])
    
    set(gca,fontsize=axis_fontsize)
    xlabel('K/km')
    ylabel('Counts')
    title( ['Pixels ' num2str(677-150) '-' num2str(677+150)], fontsize=title_fontsize)
    legend({'|\nabla{SST\_in}|' '|\nabla{SST\_fast}|'})
    
    subplot(133)
    
    xx1 = gm_in(1054:1354,:);
    xx2 = gm_fast(1054:1354,:);
    mm = find(xx1>0 & xx2>0);
    histogram(xx1(mm), [0:0.01:0.6])
    hold on
    histogram(xx2(mm), [0:0.01:0.6])
    
    set(gca,fontsize=axis_fontsize)
    xlabel('K/km')
    ylabel('Counts')
    title( 'Pixels 1054-1354', fontsize=title_fontsize)
    legend({'|\nabla{SST\_in}|' '|\nabla{SST\_fast}|'})
    
    sgtitle(['Gradient Magnitudes for Orbit ' num2str(orbit_no)], fontsize=30)

    %% Now plot all of the fast-griddata histograms in one plot.
    
    figure(1)
    subplot(2,3,iFile)
    
    histogram(dd_gm_fast_griddata, HIST_GM_3)
    
    set(gca,fontsize=axis_fontsize)
    xlabel('K/km')
    ylabel('Counts')
    ylim(COUNTS_LIM)
    title(['Orbit ' num2str(orbit_no)], fontsize=title_fontsize)

    % And all of the fast-griddata fields in one plot.
    
    figure(2)
    subplot(2,3,iFile)
    
    imagesc((gm_griddata_z - gm_fast_z)')   
    set(gca,fontsize=axis_fontsize)
    title(['Orbit ' num2str(orbit_no)], fontsize=title_fontsize)
    colorbar
    caxis(CAXIS_gm_diff)    
end

figure(1)
sgtitle('|\nabla{SST\_griddata}| - |\nabla{SST\_fast}|', fontsize=30)

figure(2)
sgtitle('|\nabla{SST\_griddata}| - |\nabla{SST\_fast}|', fontsize=30)

end