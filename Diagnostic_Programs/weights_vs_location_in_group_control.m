% weights_vs_location_in_group_control - demo plots of impact of bow-tie and fixed version.
%
% Read sst input masked, fast regridded version and griddata version for an
% obit. Determine the gradient magnitudes of these, then plot them and
% histogram the differences.
%

which_test = 4;

% Define global variables

global fi
global plotem AXIS CAXIS_sst CAXIS_sst_diff_1 CAXIS_sst_diff_2 CAXIS_gm CAXIS_gm_diff
global XLIM YLIM HIST_SST HIST_GM_1 HIST_GM_2 HIST_GM_3 COUNTS_LIM ZOOM_RANGE
global title_fontsize axis_fontsize
global along_scan_seps_array along_track_seps_array

plotem = [0 1 1 0];

title_fontsize = 24;
axis_fontsize = 18;

% Get separations and angles for gradient calculations.

fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/';   % Test run.
gradient_filename = [fixit_directory 'Separation_and_Angle_Arrays.n4'];

along_scan_seps_array = ncread(gradient_filename, 'along_scan_seps_array');
along_track_seps_array = ncread(gradient_filename, 'along_track_seps_array');

% Orbit to process.

switch which_test
    case 1
        Year = '2005';
        Month = '09';
        Orbit = '17970';
        
%         fitemp = dir( ['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/' Year '/' Month '/AQUA_MODIS_orbit_' Orbit '*']);
        fitemp = dir( ['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/processed/' Year '/' Month '/AQUA_MODIS_orbit_' Orbit '*']);
        fi = [fitemp(1).folder '/' fitemp(1).name];
        
        % Define parameters specific to this orbit.
        
        AXIS = [1220 1354 8901 8930];
        CAXIS_sst = [-2 32];
        CAXIS_sst_diff_1 = [-1 1];
        CAXIS_sst_diff_2 = [-0.1 0.1];
        CAXIS_gm = [0 0.5];
        CAXIS_gm_diff = [-0.05 0.05];
        XLIM = [-.2 .2];
        YLIM = [0 1500000];
        HIST_SST = [-1:0.01:1];
        HIST_GM_1 = [-.34:0.01:.5];
        HIST_GM_2 = [-.34:0.001:.5];
        HIST_GM_3 = [-.03:0.001:.03];
        COUNTS_LIM = [0 300];
        ZOOM_RANGE = [1241 1325 8901 8930];
        
    case 2
        Year = '2005';
        Month = '09';
        Orbit = '17970';
        
%         fitemp = dir( ['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/' Year '/' Month '/AQUA_MODIS_orbit_' Orbit '*']);
        fitemp = dir( ['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/processed/' Year '/' Month '/AQUA_MODIS_orbit_' Orbit '*']);
        fi = [fitemp(1).folder '/' fitemp(1).name];
        
        % Define parameters specific to this orbit.
        
        AXIS = [621 785 27380 27835];
        CAXIS_sst = [-2 32];
        CAXIS_sst_diff_1 = [-1 1];
        CAXIS_sst_diff_2 = [-0.1 0.1];
        CAXIS_gm = [0 0.5];
        CAXIS_gm_diff = [-0.05 0.05];
        XLIM = [-.2 .2];
        YLIM = [0 1500000];
        HIST_SST = [-1:0.01:1];
        HIST_GM_1 = [-.34:0.01:.5];
        HIST_GM_2 = [-.34:0.001:.5];
        HIST_GM_3 = [-.03:0.001:.03];
        COUNTS_LIM = [0 1000];
        ZOOM_RANGE = [591 660 27551 27700];
        
    case 3
        Year = '2019';
        Month = '01';
        Orbit = '88888';
        
%         fitemp = dir( ['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/' Year '/' Month '/AQUA_MODIS_orbit_' Orbit '*']);
        fitemp = dir( ['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/processed/' Year '/' Month '/AQUA_MODIS_orbit_' Orbit '*']);
        fi = [fitemp(1).folder '/' fitemp(1).name];
        
        % Define parameters specific to this orbit.
        
        AXIS = [321 420 7251 7750];
        CAXIS_sst = [-2 32];
        CAXIS_sst_diff_1 = [-1 1];
        CAXIS_sst_diff_2 = [-0.1 0.1];
        CAXIS_gm = [0 0.5];
        CAXIS_gm_diff = [-0.05 0.05];
        XLIM = [-.2 .2];
        YLIM = [0 1500000];
        HIST_SST = [-1:0.01:1];
        HIST_GM_1 = [-.34:0.001:.5];
        HIST_GM_2 = [-.34:0.001:.5];
        HIST_GM_3 = [-.03:0.001:.03];
        COUNTS_LIM = [0 300];
        ZOOM_RANGE = [341 415 7411 7540];
        
    case 4
        Year = '2019';
        Month = '01';
        Orbit = '88890';
        
%         fitemp = dir( ['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/' Year '/' Month '/AQUA_MODIS_orbit_' Orbit '*']);
        fitemp = dir( ['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/processed/' Year '/' Month '/AQUA_MODIS_orbit_' Orbit '*']);
        fi = [fitemp(1).folder '/' fitemp(1).name];
        
        % Define parameters specific to this orbit.
        
        AXIS = [21 180 7601 9600];
        CAXIS_sst = [23 27];
        CAXIS_sst_diff_1 = [-1 1];
        CAXIS_sst_diff_2 = [-0.1 0.1];
        CAXIS_gm = [0 0.4];
        CAXIS_gm_diff = [-0.05 0.05];
        XLIM = [-.2 .2];
        YLIM = [0 2000000];
        HIST_SST = [-1:0.01:1];
        HIST_GM_1 = [-.34:0.001:.5];
        HIST_GM_2 = [-.34:0.001:.5];
        HIST_GM_3 = [-.03:0.001:.03];
        COUNTS_LIM = [0 5000];
        ZOOM_RANGE = [36 110 7601 8050];
        
    case 5
        Year = '2019';
        Month = '01';
        Orbit = '88890';
        
%         fitemp = dir( ['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/' Year '/' Month '/AQUA_MODIS_orbit_' Orbit '*']);
        fitemp = dir( ['~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/processed/' Year '/' Month '/AQUA_MODIS_orbit_' Orbit '*']);
        fi = [fitemp(1).folder '/' fitemp(1).name];
        
        % Define parameters specific to this orbit.
        
        AXIS = [1101 1350 29551 30050];
        CAXIS_sst = [20 30];
        CAXIS_sst_diff_1 = [-1 1];
        CAXIS_sst_diff_2 = [-0.1 0.1];
        CAXIS_gm = [0 0.5];
        CAXIS_gm_diff = [-0.05 0.05];
        XLIM = [-.2 .2];
        YLIM = [0 1500000];
        HIST_SST = [-1:0.01:1];
        HIST_GM_1 = [-.34:0.001:.5];
        HIST_GM_2 = [-.34:0.001:.5];
        HIST_GM_3 = [-.03:0.001:.03];
        COUNTS_LIM = [0 5000];
        ZOOM_RANGE = [1141 1260 29691 29900];
        
end

% Now call function to plot and determine stats.

% [eq_crossing_primary, eq_crossing_index, sigmas] = weights_vs_location_in_group;
[eq_crossing_primary, weights_meta, sigmas] = weights_vs_location_in_group;

% % % fprintf('\n\nNumber good pixels read in  %i; good griddata pixels %i\n', nums.num_in(1), nums.num_griddata(1))
% % % fprintf('\nNumber good fast pixels %i %i %i %i %i\n', nums.num_fast)
% % % fprintf('\nin-griddata: \x03c3(SST) %5.3f; \x03c3|\x2207SST| %5.3f; zoomed \x03c3|\x2207SST| %5.3f\n\n', sigmas.sigma_in_griddata, sigmas.sigma_gm_in_griddata, sigmas.sigma_gm_in_griddata_z)
% % % 
% % % fprintf('fast-griddata    sst: %7.4f %7.4f %7.4f %7.4f %7.4f\n', sigmas.sigma_fast_griddata)
% % % fprintf('             \x03c3|\x2207SST|: %7.4f %7.4f %7.4f %7.4f %7.4f\n', sigmas.sigma_gm_fast_griddata)
% % % fprintf('  zoomed     \x03c3|\x2207SST|: %7.4f %7.4f %7.4f %7.4f %7.4f\n', sigmas.sigma_gm_fast_griddata_z)

%% Print out figures

fig_dir = '~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Figures/';

figure(1)
print([fig_dir 'gm_fast_minus_gm_griddata_' Orbit '_' num2str(which_test)], '-dpng')

figure(2)
print([fig_dir 'gm_fast_minus_gm_sst_' Orbit '_' num2str(which_test)], '-dpng')
