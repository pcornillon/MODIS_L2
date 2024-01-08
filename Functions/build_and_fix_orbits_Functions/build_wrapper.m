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
    case 1 % MacStudio or Satdat1 
        % reading 
        %   fixit metadata from Dropbox, 
        %   OBPG metadata from Dropbox, 
        %   granules from Cornillon_NAS 
        % and writing 
        %   local output to the Cornillon_NAS
        %   remote outut to the Cornillon_NAS
        %   logs output to Dropbobx

        BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';

        fixit_directory = [BaseDir 'metadata/'];
        metadata_directory = [BaseDir 'metadata/Data_from_OBPG_for_PO-DAAC/'];

        granules_directory    = '/Volumes/MODIS_L2_original/OBPG/combined/';
        
        output_file_directory_local = '/Volumes/MODIS_L2_Modified/OBPG/SST/';
        output_file_directory_remote = '/Volumes/MODIS_L2_Modified/OBPG/SST/';

        logs_directory = [BaseDir 'Logs/'];
    
    case 2 % MacStudio or Satdat1 
        % reading 
        %   fixit metadata from Dropbox, 
        %   OBPG metadata from Aqua-1, 
        %   granules from Cornillon_NAS 
        % and writing 
        %   local output to the Desktop
        %   remote outut to the Cornillon_NAS
        %   logs output to Dropbobx

        BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';

        fixit_directory = [BaseDir 'metadata/'];
        metadata_directory = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';

        granules_directory    = '/Volumes/MODIS_L2_Original/OBPG/combined/';

        output_file_directory_local = '/users/petercornillon/Desktop/SST/';
        output_file_directory_remote = '/Volumes/MODIS_L2_Modified/OBPG/SST/';

        logs_directory = [BaseDir 'Logs/'];

    case 3 % MacStudio or Satdat1
        %   fixit metadata from Dropbox, 
        %   OBPG metadata from Cornillon_NAS, 
        %   granules from Cornillon_NAS 
        % and writing 
        %   local output to the Desktop
        %   remote outut to the Cornillon_NAS
        %   logs output to Dropbobx

        BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';

        fixit_directory = [BaseDir 'metadata/'];
        metadata_directory = '/Volumes/MODIS_L2_modified/OBPG/Data_from_OBPG_for_PO-DAAC/';

        granules_directory    = '/Volumes/MODIS_L2_Original/OBPG/combined/';

%         output_file_directory_local = '/Volumes/MODIS_L2_Modified/OBPG/SST/';
%         output_file_directory_remote = '';
        output_file_directory_local = '/Users/petercornillon/Data/temp_MODIS_L2_output_directory/SST/';
        output_file_directory_remote = '/Volumes/MODIS_L2_Modified/OBPG/SST/';

        logs_directory = '/Volumes/MODIS_L2_Modified/OBPG/Logs/';

    case 4 % MacStudio or Satdat1 -- see sister for AWS test case.
        %   fixit metadata from Dropbox, 
        %   OBPG metadata from Aqua-1, 
        %   granules from Aqua-1 
        % and writing 
        %   local output to Peter's Data folder
        %   No remote outut
        %   logs output to Dropbobx

        BaseDir = '/Users/petercornillon/Data/temp_MODIS_L2_output_directory/';

        fixit_directory                 = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/metadata/';
        metadata_directory              = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';

        granules_directory              = '/Volumes/Aqua-1/MODIS_R2019/combined/';

        output_file_directory_local     = [BaseDir 'output/'];
        output_file_directory_remote    = '';

        logs_directory                  = [BaseDir 'Logs/'];

    case 5 % AWS for debug, not from S3
        %   fixit metadata from Dropbox, 
        %   OBPG metadata from Dropbox, 
        %   granules from Dropbox 
        % and writing 
        %   local output to Dropbox
        %   remote outut to []
        %   logs output to Dropbobx

       BaseDir = '/home/ubuntu/Documents/Aqua/';

        fixit_directory = [BaseDir 'metadata/'];
        metadata_directory = [BaseDir 'metadata/Data_from_OBPG_for_PO-DAAC/'];

        granules_directory = [BaseDir 'original_granules/'];

        output_file_directory_local = [BaseDir 'output/'];
        output_file_directory_remote = '';

        logs_directory = [BaseDir 'Logs/'];

    case 6 % AWS from S3
        %   fixit metadata from s3-uri-gso-pcornillon
        %   OBPG metadata  from s3-uri-gso-pcornillon 
        %   granules       from NASA S3
        % and writing 
        %   local output   to   /home/ubuntu/Documents/Aqua/output/
        %   remote outut   to   Cornillon_NAS
        %   logs output    to   s3-uri-gso-pcornillonDropbobx

        fixit_directory              = '/mnt/s3-uri-gso-pcornillon/';
        metadata_directory           = '/mnt/s3-uri-gso-pcornillon/Data_from_OBPG_for_PO-DAAC/';

        granules_directory           = 's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';

        output_file_directory_local  = '/home/ubuntu/Documents/Aqua/output/';
        output_file_directory_remote = '/mnt/uri-nfs-cornillon/';

        logs_directory               = '/mnt/s3-uri-gso-pcornillon/Logs/';
        
        % % % 
        % % % % BaseDir = '/home/ubuntu/Documents/Aqua/';
        % % % 
        % % % output_file_directory_local = '/mnt/s3-uri-gso-pcornillon/output/';

    case 7 % Laptop
        %   fixit metadata from s3-uri-gso-pcornillon
        %   OBPG metadata  from Data_1
        %   granules       from Data_1
        % and writing 
        %   local output   to   Data_1
        %   remote outut   to   Data_1
        %   logs output    to   Data_1

        BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';

        fixit_directory              = [BaseDir 'metadata/'];
        metadata_directory           = '/Volumes/Data_1/Data_from_OBPG_for_PO-DAAC/';

        granules_directory           = '/Volumes/Data_1/combined/';

        output_file_directory_local  = '/Volumes/Data_1/output/';
        output_file_directory_remote = '';

        logs_directory               = '/Volumes/Data_1/Logs/';

    case 8 % AWS sister to case 4 MacStudio or Satdat1
        %   fixit metadata from Dropbox, 
        %   OBPG metadata from Aqua-1, 
        %   granules from Aqua-1 
        % and writing 
        %   local output to Peter's Data folder
        %   No remote outut
        %   logs output to Dropbobx

        BaseDir = '/home/ubuntu/Documents/Aqua/';

        fixit_directory                 = '/mnt/s3-uri-gso-pcornillon/';        
        
        metadata_directory              = '/mnt/s3-uri-gso-pcornillon/Data_from_OBPG_for_PO-DAAC/';

        granules_directory              = 's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';

        output_file_directory_local     = [BaseDir 'output/'];
        output_file_directory_remote    = '';

        logs_directory                  = [BaseDir 'Logs/'];

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

fprintf('Entering build_and_fix_orbits.\n')

build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, fast_regrid, get_gradients, save_core, print_diag, save_orbits, base_diary_filename)

% % % % Save oinfo and memory structure files for this run.
% % % 
% % % save(strrep(diary_filename, '.txt', '.mat'), 'oinfo', 'mem_struct')
