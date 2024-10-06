function find_missing_granules_from_OBPG(startYear, endYear)
% find_missing_granules_from_OBPG - compare filelist from OBPG with that for metadata files to AWS - PCC
%
% This function will create a list of all metadata files in
% Aqua_Data_from_OBPG_for_PO-DAAC for each year in the range. The script
% will then read through the list of granules obtained from OBPG with: 
% wget --no-check-certificate --user=pcornillon --ask-password --auth-no-challenge=on -i /Volumes/MODIS_L2_Original/granule_lists_from_OBPG/2011_TERRA_filelist-10-01-2024.txt  -nv -o /Volumes/MODIS_L2_Original/granule_lists_from_OBPG/2011_TERRA_log_10-03-2024.txt 
% for the same year and write out the line from this file if there is not a
% line in the metadata file; i.e., if the metadata granule is missing. This
% means either that the data granule was acquired but that the
% corresponding metadata granule was not writte or that the data granule
% was not acquired.
%
% INPUT
%   startYear - the first year to process
%   endYear - the last year to process.
%
% OUTPUT
%   none
%

% Define directories
metadata_dir = '/Volumes/MODIS_L2_Modified/OBPG/Aqua_Data_from_OBPG_for_PO-DAAC';
granule_list_dir = '/Volumes/MODIS_L2_Original/granule_lists_from_OBPG';

% Loop through the specified years
for year = startYear:endYear
    % Create the metadata list file for the current year
    metadata_list_file = fullfile(granule_list_dir, sprintf('%d_AQUA_metadata_list.txt', year));
    granule_list_pattern = fullfile(granule_list_dir, sprintf('%d_AQUA_filelist-*.txt', year));

    % Get all metadata files for the current year
    metadata_files = dir(fullfile(metadata_dir, sprintf('AQUA_MODIS_*_L2_SST_OBPG_extras.nc4')));
    fid_meta = fopen(metadata_list_file, 'w');

    for i = 1:length(metadata_files)
        fprintf(fid_meta, '%s\n', metadata_files(i).name);
    end
    fclose(fid_meta);

    % Find the granule file list for the current year
    granule_file_list = dir(granule_list_pattern);
    if isempty(granule_file_list)
        fprintf('No granule list found for year %d\n', year);
        continue;
    end

    % Read granule list file for the year
    granule_list_file = fullfile(granule_file_list(1).folder, granule_file_list(1).name);
    fid_granule = fopen(granule_list_file, 'r');
    granule_lines = textscan(fid_granule, '%s', 'Delimiter', '\n');
    granule_lines = granule_lines{1};
    fclose(fid_granule);

    % Read metadata list
    fid_meta = fopen(metadata_list_file, 'r');
    metadata_lines = textscan(fid_meta, '%s', 'Delimiter', '\n');
    metadata_lines = metadata_lines{1};
    fclose(fid_meta);

    % Open file for missing metadata granules
    missing_metadata_file = fullfile(granule_list_dir, sprintf('%d_AQUA_missing_metadata_granules.txt', year));
    fid_missing = fopen(missing_metadata_file, 'w');

    % Search for each granule in the metadata file list
    for i = 1:length(granule_lines)
        granule_line = granule_lines{i};
        if contains(granule_line, '.nc')
            % Extract the date and time part from the granule filename
            granule_time_str = extractBetween(granule_line, 'AQUA_MODIS.', '.L2.SST.nc');

            % Search for corresponding metadata file
            found = false;
            for j = 1:length(metadata_lines)
                metadata_time_str = extractBetween(metadata_lines{j}, 'AQUA_MODIS_', '_L2_SST_OBPG_extras.nc4');
                if strcmp(granule_time_str, metadata_time_str)
                    found = true;
                    break;
                end
            end

            % If no corresponding metadata file is found, write to missing list
            if ~found
                fprintf(fid_missing, '%s\n', granule_line);
            end
        end
    end

    fclose(fid_missing);
end
end