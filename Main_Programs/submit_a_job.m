% submit_a_job - submit a build_and_fix_orbits job passing in start and end times - PCC
%
%

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory

% First make sure that the MODIS_L2 project has been openend and that the
% Main_programs directory is on the path.

keyboard

Option = 1;

if Option == 1
    ProgDir = '/Users/petercornillon/MATLAB/Projects/MODIS_L2/';
    BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';
    granules_directory = [BaseDir 'combined'];
else
    ProgDir = '/home/ubuntu/Documents/MODIS_L2/';
    BaseDir = '/home/ubuntu/Documents/Aqua/';
    granules_directory = 's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';
end

% % % Diary_File = [ProgDir 'Logs/temp_log_1.txt'];
% % % diary(Diary_File)

 addpath([ProgDir 'Main_Programs/'])

 prj = openProject([ProgDir 'MODIS_L2.prj'])

 fix_mask = 1;  % Test run.
 fix_bowtie = 1;  % Test run.
 regrid_sst = 1;  % Test run.
 fast_regrid = 0; % Test run
 get_gradients = 1;  % Test run.
 save_core = 1;  % Test run.
 print_diag = 1;  % Test run.

 debug = 1;


% % %  metadata_directory = '/home/ubuntu/Documents/Aqua/metadata/Data_from_OBPG_for_PO-DAAC/';
% % %  output_file_directory = '/home/ubuntu/Documents/Aqua/output/';
% % % 
% % %  fixit_directory = '/home/ubuntu/Documents/Aqua/metadata/';
% % %  logs_directory = '/home/ubuntu/Documents/Aqua/Logs/';

 metadata_directory = [BaseDir 'metadata/Data_from_OBPG_for_PO-DAAC/'];
 output_file_directory = [BaseDir 'output/'];

 fixit_directory = [BaseDir 'metadata/'];
 logs_directory = [BaseDir 'Logs/'];

%  start_date_time = [2010 04 19 02 0 0];
%  end_date_time = [2010 04 19 05 0 0];

 start_date_time = [2010 06 19 4 0 0];
 end_date_time = [2010 06 19 7 0 0];

 whos

 build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, fast_regrid, get_gradients, save_core, print_diag)