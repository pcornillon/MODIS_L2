function [nums, sigmas] = weights_vs_location_in_group
% weights_vs_location_in_group - get stats for weights at different location in detector group - PCC
%  
% The function will compare the fast regridding vs Matlab regridding for
% one orbit (fi) using a significant number of the weights and locations. 
% It will calcuate the rms of the difference between the two for the entire
% file and for a selected region. The location of the equatorialorial
% crossing for the given orbit and for each of the orbits from which weights 
% and locations were calculated will be found and the separation in terms
% of the 10 detector arrays will be determined. The sigmas will be plotted
% as a function of this offset.

% Define global variables

global fi
global AXIS CAXIS_sst CAXIS_sst_diff_1 CAXIS_sst_diff_2 CAXIS_gm CAXIS_gm_diff
global XLIM YLIM HIST_SST HIST_GM_1 HIST_GM_2 HIST_GM_3 COUNTS_LIM ZOOM_RANGE
global title_fontsize axis_fontsize
global along_scan_seps_array along_track_seps_array

sst_base_dir = '~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/Processed/';

% Get original sst data, the original longitudes and latitudes and the
% regridded longitudes and latitudes.

sst_in = ncread( fi, 'SST_In_Masked');
sst_griddata = ncread( fi, 'regridded_sst_alternate');

lon_orig = ncread( fi, 'longitude');
lat_orig = ncread( fi, 'latitude');

lon_regrid = ncread( fi, 'regridded_longitude');
lat_regrid = ncread( fi, 'regridded_latitude');

% Now regrid using Matlab

% sst_regrid_matlab = griddata( lon_orig, lat_orig, sst_in, lon_regrid, lat_regrid);
load('~/Dropbox/TempforTransfer/tempregrid.mat');

dd_in_griddata = sst_in - sst_griddata;
sigmas.sigma_in_griddata = std(dd_in_griddata(:),'omitnan');

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

dd_gm_in_griddata = gm_in - gm_griddata;
dd_gm_in_griddata_z = gm_in_z - gm_griddata_z;

sigmas.sigma_gm_in_griddata = std(dd_gm_in_griddata(:),'omitnan');
sigmas.sigma_gm_in_griddata_z = std(dd_gm_in_griddata_z(:),'omitnan');

% Get list of orbits with fixed weights and locations

filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/*_weights.mat');

% Loop over this list fast regridding using the weights and locations from
% the orbits with them.

iFig = 0;

for iFile=1:length(filelist)
    
    % Find the equatorial crossing of the ascending nadir track for the
    % orbit from which these weights and locations were obtained.
    
    Year = filelist(iFile).name(7:10);
    Month = filelist(iFile).name(11:12);
    
    ii = strfind( filelist(iFile).name, '_weights');
    
    fi_sst = [sst_base_dir Year '/' Month '/AQUA_MODIS_orbit_'  filelist(iFile).name(1:ii-1) '.nc4' ];

    lat_weights = ncread( fi_sst, 'regridded_latitude', [677, 1], [1, 40271]);
% % %     lon_weights = ncread( fi_sst, 'regridded_longitude', [677, 1], [1, 40271]);
    
    ii = find(lat_weights>=0);
    eq_crossing(iFile) = min(lat_weights(ii-1:ii));
    
    % Now get the name for the file with the weights and locations in it.
    
    filename = [filelist(iFile).folder '/' filelist(iFile).name];
    
    
    nn = strfind(filelist(iFile).name, 'weights_and_locations_');
    orbit_no = filelist(iFile).name(nn+22:nn+26);
    
    fprintf('\n\n%i) Results for orbit number %s\n\n', iFile, orbit_no)
    
    % Get the weights and locations for this orbit.
    
    load(filename)
    
    % Regrid with this set of weights and locations
    
    [nElements, nScans] = size(sst_in);
    [nMax, mElements, mScans] = size(weights);
    
% % %     % Truncate weights array to same number of scan lines as SST array.
% % %     
% % %     weights = weights(:,:,1:nScans);
% % %     locations = locations(:,:,1:nScans);
    
% % %     nMax = 3;
    
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
    
    nn = find(isnan(sst_in) == 0);
    nums.num_in(iFile) = length(nn);
    nn = find(isnan(sst_fast) == 0);
    nums.num_fast(iFile) = length(nn);
    nn = find(isnan(sst_griddata) == 0);
    nums.num_griddata(iFile) = length(nn);
    
    fprintf('Number of elements in sst_in: %i, sst_griddata: %i, sst_fast: %i\n', nums.num_in(iFile), nums.num_griddata(iFile), nums.num_fast(iFile))
    
    dd_fast_griddata = sst_fast - sst_griddata;
        
    % Histogram differences
    iFig = iFile * 10 + 1;
    figure(iFig)
    clf
    
    hh = histogram(dd_in_griddata, HIST_SST);
    hold on
    hh2 = histogram(dd_fast_griddata, HIST_SST);
    
    set(gca,fontsize=axis_fontsize)
    ylim([0 100000])
    xlabel('^\circ C')
    ylabel('Counts')
    xlim(XLIM)
    ylim(YLIM)
    title(['SST Differences for Orbit ' num2str(orbit_no)], fontsize=title_fontsize)
    legend({'SST_{in} - SST_{gridata}' 'SST_{fast} - SST_{griddata}'})
    
    % Stats on sst differences
    
    sigmas.sigma_fast_griddata(iFile) = std(dd_fast_griddata(:),'omitnan');
    fprintf('100 * sigma_fast / sigma_griddata %3.0f%%\n', 100 * sigmas.sigma_fast_griddata(iFile) / sigmas.sigma_in_griddata)
    
    % Now get gradient magnitudes for each of the fields.
    
    [~, ~, gm_fast] = sobel_gradient_degrees_per_kilometer( ...
        sst_fast, ...
        along_track_seps_array(:,1:size(sst_fast,2)), ...
        along_scan_seps_array(:,1:size(sst_fast,2)));

    dd_gm_fast_griddata = gm_fast - gm_griddata;
    sigmas.sigma_gm_fast_griddata(iFile) = std(dd_gm_fast_griddata(:),'omitnan');
    
    %% Get gradient magnitudes for zoomed in region
    
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
    
    %% And differences between sst in and the fast interpolation.
    dd_gm_fast_griddata_z = gm_fast_z - gm_griddata_z;
        
    % Histogram the differences between gradient magnitudes.
    iFig = iFile * 10 + 3;
    figure(iFig)
    clf
    
    hhgm1 = histogram(dd_gm_in_griddata_z, HIST_GM_2);
    hold on
    hhgm2 = histogram(dd_gm_fast_griddata_z, HIST_GM_2);
    legend({'|\nabla{SST\_in}| - |\nabla{SST\_griddata}|' '|\nabla{SST\_fast}| - |\nabla{SST\_griddata}|'})
    set(gca,fontsize=axis_fontsize)
    xlabel('K/km')
    ylabel('Counts')
    xlim(XLIM)
    title(['Gradient Magnitude Differences for Orbit ' num2str(orbit_no)], fontsize=title_fontsize)
    
    % And stats for these difference.
    sigmas.sigma_gm_fast_griddata_z(iFile) = std(dd_gm_fast_griddata_z(:),'omitnan');
    
    fprintf('100 * sigmas.sigma_gm_in_griddata_z / sigmas.sigma_gm_fast_griddata_z = %3.0f%%\n', 100 * sigmas.sigma_gm_fast_griddata_z(iFile) / sigmas.sigma_gm_in_griddata_z)

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
    
    hh = histogram(dd_gm_fast_griddata_z, HIST_GM_3);
    numdd = sum(hh.Values);
    
    set(gca,fontsize=axis_fontsize)
    xlabel('K/km')
    ylabel('Counts')
    ylim(COUNTS_LIM)
    title(['Orbit ' num2str(orbit_no)], fontsize=title_fontsize)
    text( -0.025, 0.9*COUNTS_LIM(2), ['#: ', num2str(numdd)], fontsize=axis_fontsize-2)
    text( -0.025, 0.83*COUNTS_LIM(2), ['$\sigma$: ', num2str(sigmas.sigma_gm_fast_griddata(iFile),2)], interpreter='latex', fontsize=axis_fontsize)
    
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