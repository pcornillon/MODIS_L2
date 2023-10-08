function submit_a_job( start_date_time, end_date_time)
% submit_a_job - submit a build_and_fix_orbits job passing in start and end times - PCC
%
% INPUT
%   start_date_time - [yyyy mm dd hh mi ss] where mi is minutes.
%   end_date_time - [yyyy mm dd hh mi ss]
%

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory

% First make sure that the MODIS_L2 project has been openend and that the
% Main_programs directory is on the path.

Option = 1;

% keyboard

if Option == 1
    ProgDir = '/Users/petercornillon/MATLAB/Projects/MODIS_L2/';
    BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';
    granules_directory = [BaseDir 'combined/'];
else
    ProgDir = '/home/ubuntu/Documents/MODIS_L2/';
    BaseDir = '/home/ubuntu/Documents/Aqua/';
    granules_directory = 's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';
end

% Diary_File = [BaseDir 'Logs/temp_log_1.txt'];
% diary(Diary_File)

addpath([ProgDir 'Main_Programs/'])

prj = openProject([ProgDir 'MODIS_L2.prj']);

fix_mask = 1;  % Test run.
fix_bowtie = 1;  % Test run.
regrid_sst = 1;  % Test run.
fast_regrid = 0; % Test run
get_gradients = 1;  % Test run.
save_core = 1;  % Test run.
print_diag = 1;  % Test run.% %  addpath([ProgDir 'Main_Programs/'])

debug = 1;

metadata_directory = [BaseDir 'metadata/Data_from_OBPG_for_PO-DAAC/'];
output_file_directory = [BaseDir 'output/'];

fixit_directory = [BaseDir 'metadata/'];
logs_directory = [BaseDir 'Logs/'];

% start_date_time = [2010 06 19 4 0 0];
% end_date_time = [2010 06 19 7 0 0];

whos

% keyboard

fprintf('Entering build_and_fix_orbits.\n')

build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, fast_regrid, get_gradients, save_core, print_diag)