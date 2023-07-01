% test_build_and_fix_regridding
% test_build_and_fix_regridding - 
%
% Will run build and fix in test mode for three periods, all day 19 but in
% January for 2005, June for 2010 and September for 2019. The output will
% be written to ~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/
%
% build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, get_gradients, save_core, print_diag)
%
% INPUT
%   start_date_time - build orbits with the first orbit to be built
%    including this time specified as: [YYYY, MM, DD, HH, Min, 00].
%   end_date_time - last orbit to be built includes this time.
%   fix_mask - if 1 fixes the mask. If absent, will set to 1.
%   fix_bowtie - if 1 fixes the bow-tie problem, otherwise bow-tie effect
%    not fixed.
%   regrid_sst - 1 to regrid SST after bowtie effect has been addressed.
%   get_gradients - 1 to calculate eastward and northward gradients, 0
%    otherwise.
%   save_core - 1 to save only the core values, regridded lon, lat, SST,
%    refined mask and nadir info, 0 otherwise.
%   print_diagnostics - 1 to print timing diagnostics, 0 otherwise.

fix_mask = 1;  % Test run.
fix_bowtie = 1;  % Test run.
regrid_sst = 1;  % Test run.
get_gradients = 1;  % Test run.
save_core = 0;  % Test run.
print_diag = 1;  % Test run.

debug = 1;

% 2009

clear global 

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory oinfo problem_list

granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';
metadata_directory = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
% output_file_directory = '/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/';
output_file_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/';  % Test run.

fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/';   % Test run.
logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';  % Test run.

start_date_time = [2005 9 19 0 0 0]; % Test run.
end_date_time = [2005 9 20 0 0 0 ];  % Test run.

build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, get_gradients, save_core, print_diag)

% 2010

clear global

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory oinfo problem_list

granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';
metadata_directory = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
% output_file_directory = '/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/';
output_file_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/';  % Test run.

fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/';   % Test run.
logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';  % Test run.

start_date_time = [2010 6 19 0 0 0]; % Test run.
end_date_time = [2010 6 20 0 0 0 ];  % Test run.

build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, get_gradients, save_core, print_diag)

% 2019

clear global

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory oinfo problem_list

granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';
metadata_directory = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
% output_file_directory = '/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/';
output_file_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/';  % Test run.

fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/';   % Test run.
logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';  % Test run.

start_date_time = [2019 1 19 0 0 0]; % Test run.
end_date_time = [2019 1 20 0 0 0 ];  % Test run.

build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, get_gradients, save_core, print_diag)

