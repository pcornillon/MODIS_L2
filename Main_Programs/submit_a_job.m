% submit_a_job - submit a build_and_fix_orbits job passing in start and end times - PCC
%
%

% First make sure that the MODIS_L2 project has been openend and that the
% Main_programs directory is on the path.

 addpath /home/ubuntu/Documents/MODIS_L2/Main_Programs/

 prj = openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj')

 fix_mask = 1;  % Test run.
 fix_bowtie = 1;  % Test run.
 regrid_sst = 1;  % Test run.
 fast_regrid = 0; % Test run
 get_gradients = 1;  % Test run.
 save_core = 1;  % Test run.
 print_diagnostics = 1;  % Test run.

 debug = 1;

 metadata_directory = '/home/ubuntu/Documents/Aqua/metadata/Data_from_OBPG_for_PO-DAAC/';
 granules_directory = 's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';
 output_file_directory = '/home/ubuntu/Documents/Aqua/output/';

 fixit_directory = '/home/ubuntu/Documents/Aqua/metadata/';
 logs_directory = '/home/ubuntu/Documents/Aqua/Logs/';

 % % % YearStart = '$1';
 % % % YearEnd = '$2';

 start_date_time = [2010 04 19 02 0 0];
 end_date_time = [2010 04 19 05 0 0];

 whos

 build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, fast_regrid, get_gradients, save_core, print_diag)