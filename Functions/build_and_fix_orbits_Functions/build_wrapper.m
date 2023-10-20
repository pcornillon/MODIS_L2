function build_wrapper( Option, start_date_time, end_date_time, base_diary_filename)
% build_wrapper - submit a build_and_fix_orbits job passing in start and end times - PCC
%
% INPUT
%   Option - which system are you on: 1 for Peter's laptop,
%            2 for satdat1
%            3 for AWS.
%   start_date_time - [yyyy mm dd hh mi ss] where mi is minutes.
%   end_date_time - [yyyy mm dd hh mi ss]
%   base_diary_filename - the name for the output log files.
%

global oinfo iOrbit iGranule iProblem problem_list

global mem_count mem_orbit_count mem_print print_dbStack mem_struct diary_filename

% Set up directories for this job.

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory

switch Option
    case 1 % Peter's laptop
        BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';
        granules_directory = [BaseDir 'combined/'];

        metadata_directory = [BaseDir 'metadata/Data_from_OBPG_for_PO-DAAC/'];

    case 2 % MacStudio or Satdat1 reading from MacStudio
        BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';
        granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';

        metadata_directory = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';

    case 3 % AWS for debug, not from S3
        BaseDir = '/home/ubuntu/Documents/Aqua/';
        granules_directory = [BaseDir 'original_granules/'];

        metadata_directory = [BaseDir 'metadata/Data_from_OBPG_for_PO-DAAC/'];

    case 4 % AWS from S3
        BaseDir = '/home/ubuntu/Documents/Aqua/';
        granules_directory = 's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';

        metadata_directory = [BaseDir 'metadata/Data_from_OBPG_for_PO-DAAC/'];
end

% Initialize arguments for build_and_fix

fix_mask = 1;
fix_bowtie = 1;
regrid_sst = 1;
fast_regrid = 0;
get_gradients = 1;
save_core = 1;
print_diag = 1;
save_orbits = 1;
debug = 0;

% Set directories.

output_file_directory = [BaseDir 'output/'];
fixit_directory = [BaseDir 'metadata/'];
logs_directory = [BaseDir 'Logs/'];

fprintf('Entering build_and_fix_orbits.\n')

build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, fast_regrid, get_gradients, save_core, print_diag, save_orbits, base_diary_filename)

% Save oinfo and memory structure files for this run.

save(strrep(diary_filename, '.txt', '.mat'), 'oinfo', 'mem_struct')

