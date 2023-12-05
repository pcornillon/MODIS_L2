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

% Open the project if on AWS, otherwise, assume that it is already open.

% machine = pwd;
% if ~isempty(strfind(machine, 'ubuntu'))
%     prj = openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj')
% end

% Set up directories for this job.

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory_local output_file_directory_remote

% Set directories.

switch Option
    case 1 % MacStudio or Satdat1 reading from NAS and writing to the NAS
        BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';

        metadata_directory = [BaseDir 'metadata/Data_from_OBPG_for_PO-DAAC/'];
        fixit_directory = [BaseDir 'metadata/'];

        % % % granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';
        granules_directory    = '/Volumes/MODIS_L2_original/OBPG/combined/';
        output_file_directory_local = '/Volumes/MODIS_L2_Modified/OBPG/SST/';
        output_file_directory_remote = '/Volumes/MODIS_L2_Modified/OBPG/SST/';
    
    case 2 % MacStudio or Satdat1 reading from Aqua-1 and writing to the Cornillon_NAS
        BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';

        metadata_directory = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
        fixit_directory = [BaseDir 'metadata/'];

        % granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';
        granules_directory    = '/Volumes/MODIS_L2_original/OBPG/combined/';
        output_file_directory_local = '/users/petercornillon/Desktop/SST/';
        output_file_directory_remote = '/Volumes/MODIS_L2_Modified/OBPG/SST/';

    case 3 % MacStudio or Satdat1 reading and writing to the Cornillon_NAS
        BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';

        metadata_directory = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
        fixit_directory = [BaseDir 'metadata/'];

        % granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';
        granules_directory    = '/Volumes/MODIS_L2_original/OBPG/combined/';
        output_file_directory_local = '/Volumes/MODIS_L2_Modified/OBPG/SST/';
        output_file_directory_remote = '/Volumes/MODIS_L2_Modified/OBPG/SST/';

    case 4 % MacStudio or Satdat1 reading from MacStudio
        BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';
        granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';

        metadata_directory = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
        fixit_directory = [BaseDir 'metadata/'];
        output_file_directory_local = [BaseDir 'output/'];

    case 5 % AWS for debug, not from S3
        BaseDir = '/home/ubuntu/Documents/Aqua/';
        granules_directory = [BaseDir 'original_granules/'];

        metadata_directory = [BaseDir 'metadata/Data_from_OBPG_for_PO-DAAC/'];
        fixit_directory = [BaseDir 'metadata/'];
        output_file_directory_local = [BaseDir 'output/'];

    case 6 % AWS from S3
        % Set directories for s3 run with metadata.

        % % % BaseDir = '/home/ubuntu/Documents/Aqua/';
        granules_directory = 's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';

        BaseDir = '/mnt/s3-uri-gso-pcornillon/';

        metadata_directory = '/mnt/s3-uri-gso-pcornillon/Data_from_OBPG_for_PO-DAAC/';
        fixit_directory = '/mnt/s3-uri-gso-pcornillon/';
        % output_file_directory_local = '/home/ubuntu/Documents/output/';
        output_file_directory_local = '/mnt/uri-nfs-cornillon/';
        % % % 
        % % % % BaseDir = '/home/ubuntu/Documents/Aqua/';
        % % % 
        % % % output_file_directory_local = '/mnt/s3-uri-gso-pcornillon/output/';
        % % % logs_directory = '/mnt/s3-uri-gso-pcornillon/Logs/';
end

logs_directory = [BaseDir 'Logs/'];

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

fprintf('Entering build_and_fix_orbits.\n')

build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, fast_regrid, get_gradients, save_core, print_diag, save_orbits, base_diary_filename)

% % % % Save oinfo and memory structure files for this run.
% % % 
% % % save(strrep(diary_filename, '.txt', '.mat'), 'oinfo', 'mem_struct')
