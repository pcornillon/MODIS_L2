% show_fix_bowtie_control - demo plots of impact of bow-tie and fixed version.
%
% Read sst input masked, fast regridded version and griddata version for an
% obit. Determine the gradient magnitudes of these, then plot them and
% histogram the differences.
%

% Define global variables

global fi
global AXIS CAXIS_sst CAXIS_sst_diff_1 CAXIS_sst_diff_2 CAXIS_gm CAXIS_gm_diff
global XLIM YLIM HIST_SST HIST_GM_1 HIST_GM_2 HIST_GM_3 COUNTS_LIM ZOOM_RANGE
global title_fontsize axis_fontsize
global along_scan_seps_array along_track_seps_array

title_fontsize = 24;
axis_fontsize = 18;

% Get separations and angles for gradient calculations.

fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/';   % Test run.
gradient_filename = [fixit_directory 'Separation_and_Angle_Arrays.n4'];

along_scan_seps_array = ncread(gradient_filename, 'along_scan_seps_array');
along_track_seps_array = ncread(gradient_filename, 'along_track_seps_array');

% Orbit to process.

fi = '~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/2005/09/AQUA_MODIS_orbit_17970_20050919T054735_L2_SST.nc4';

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

% Now call function to plot and determine stats.

[num_in, num_griddata, num_fast] = show_fix_bowtie

