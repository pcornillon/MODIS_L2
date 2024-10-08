function get_data_and_metadata_NAS_lists(satellite, startYear, endYear, override)
% get_data_and_metadata_NAS_lists - generate files with lists of granules for data and metadata on the NAS - PCC
%
% For each year in the specified range, this function will create a file 
% listing all metadata granules in 
% /Volumes/MODIS_L2_Modified/SAT/Data_from_OBPG_for_PO-DAAC/YYYY 
% and a second file for data granules in 
% /Volumes/MODIS_L2_Original/SAT/YYYY.
%
% The created files will be save in 
% /Volumes/MODIS_L2_Modified/SAT/Logs/YYYY_SAT_metadata_list.txt for the metadata files and in 
% /Volumes/MODIS_L2_Original/SAT/Logs/YYYY_SAT_NAS_granule_list.txt
%
% These files take a long time to create so it will check if the files have
% already been created. For each one that has, it will only recreate it if
% override is true, otherwise it will skip.
%
% INPUT
%   satellite - AQUA or TERRA
%   startYear - the first year to process
%   endYear - the last year to process.
%   override - true to recreate the file if it already exist, otherwise, skip.
%
% OUTPUT
%   none
%

% Set override to false if it was not passed in; i.e., don't recreate files.
if ~exist('override')
    override = false;
end

% Define directories
if strfind(satellite, 'AQUA')
    metadata_dir = '/Volumes/MODIS_L2_Modified/AQUA/Data_from_OBPG_for_PO-DAAC/';
    granule_dir = '/Volumes/MODIS_L2_Original/AQUA/';
elseif strfind(satellite, 'TERRA')
    metadata_dir = '/Volumes/MODIS_L2_Modified/TERRA/Data_from_OBPG_for_PO-DAAC/';
    granule_dir = '/Volumes/MODIS_L2_Original/TERRA/combined/';
else
    fprintf('You entered %s for the satellite. This is bad, it must be either AQUA or TERRA\n', satellite)
    return
end

% Loop through the specified years
for year = startYear:endYear
    yearS = num2str(year);

    fprintf('Working on %s at %s\n', yearS, datestr(now))
    
    % Create the metadata list file for the current year
    metadata_file_list = [metadata_dir 'Logs/' yearS '_' satellite 'metadata_list.txt'];
    granule_file_list = [granule_dir 'Logs/' yearS '_' satellite 'granule_list.txt'];

    % Get all metadata files for the current year if the metadata file list does not already exist. 
    if ~exist(metadata_file_list) | override
        metadata_files = dir( [metadata_dir '/' num2str(year) '/' satellite '_MODIS_' num2str(year) '*_L2_SST_OBPG_extras.nc4']);
        fid_meta = fopen(metadata_file_list, 'w');

        for i = 1:length(metadata_files)
            fprintf(fid_meta, '%s\n', metadata_files(i).name);
        end
        fclose(fid_meta);
    end

    % Get all granule files for the current year if the granule file list does not already exist. AQUA_MODIS.20020704T000015.L2.SST.nc 
    if ~exist(granule_file_list) | override
        granule_files = dir( [granule_dir '/' num2str(year) '/' satellite '_MODIS.' num2str(year) '*.L2.SST.nc']);
        fid_granule = fopen(granule_file_list, 'w');

        for i = 1:length(granule_files)
            fprintf(fid_granule, '%s\n', granule_files(i).name);
        end
        fclose(fid_granule);
    end
end

end