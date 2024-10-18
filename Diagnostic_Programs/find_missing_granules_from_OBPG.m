function [iBad, missing_files] = find_missing_granules_from_OBPG(satellite, startYear, endYear)
% find_missing_granules_from_OBPG - compare filelist from OBPG with that for metadata files to AWS - PCC
%
% This function will create a list of all metadata files in
% Data_from_OBPG_for_PO-DAAC for each year in the range. The script will
% then read through the list of granules obtained from OBPG with:
% wget --no-check-certificate --user=pcornillon --ask-password --auth-no-challenge=on -i /Volumes/MODIS_L2_Original/granule_lists_from_OBPG/2011_TERRA_filelist-10-01-2024.txt  -nv -o /Volumes/MODIS_L2_Original/granule_lists_from_OBPG/2011_TERRA_log_10-03-2024.txt
% for the same year and write out the line from this file if there is not a
% line in the metadata file; i.e., if the metadata granule is missing. This
% means either that the data granule was acquired but that the
% corresponding metadata granule was not written or that the data granule
% was not acquired.
%
% INPUT
%   satellite - AQUA or TERRA - the satellit for which the metadata is to
%    be extracted. The satellite names must be all caps.
%   startYear - the first year to process
%   endYear - the last year to process.
%
% OUTPUT
%   iBad - the total number of missing files for the range of year specified.
%   missing_files - the list of missing files.
%

if isempty(strfind( satellite, 'AQUA')) & isempty(strfind( satellite, 'TERRA'))
    fprintf('You entered %s for the satellite but it has to be either ''AQUA'' or ''TERRA''.\n', satellite)
    return
end

% Define directories

metadata_dir =     [ '/Volumes/MODIS_L2_Modified/' satellite '/'];
granule_list_dir = [ '/Volumes/MODIS_L2_Original/' satellite '/Logs/'];

% Create and open the filename for the file that will contain ALL missing OBPG granules. 

missing_metadata_file_ALL = [metadata_dir 'Logs/ALL_' satellite '_missing_metadata_granules.txt'];
fid_missing_ALL = fopen(missing_metadata_file_ALL, 'w');

% Loop through the specified years

for year = startYear:endYear
    yearS = num2str(year);

    fprintf('Working on %s for %s at %s\n', satellite, yearS, datestr(now))

    % Create the metadata list file for the current year: 2005_AQUA_metadata_list.txt

    metadata_list_file = [metadata_dir 'Logs/' yearS '_' satellite '_metadata_list.txt'];

    % Get all metadata files for the current year if the metadata file list
    % does not already exist. If it does, read the data.

    if ~exist(metadata_list_file)    % TERRA_MODIS_20000224T000006_L2_SST_OBPG_extras.nc4
        
        metadata_files = dir( [metadata_dir 'Data_from_OBPG_for_PO-DAAC/' yearS '/' satellite '_MODIS_' yearS '*_L2_SST_OBPG_extras.nc4']);

        fid_meta = fopen(metadata_list_file, 'w');

        for i = 1:length(metadata_files)
            fprintf(fid_meta, '%s\n', metadata_files(i).name);
        end
        fclose(fid_meta);
    end

    % Get the filename for the list of files from OBPG: 2000_TERRA_filelist-10-01-2024.txt

    granule_list_pattern = [granule_list_dir yearS '_' satellite '_*'];

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
    granule_lines = sort(granule_lines);
    fclose(fid_granule);

    % Read metadata list

    fid_meta = fopen(metadata_list_file, 'r');
    metadata_lines = textscan(fid_meta, '%s', 'Delimiter', '\n');
    metadata_lines = metadata_lines{1};
    metadata_lines = sort(metadata_lines);
    fclose(fid_meta);

    % Open file for missing metadata granules

    missing_metadata_file = [metadata_dir 'Logs/' yearS '_' satellite '_missing_metadata_granules.txt'];
    fid_missing = fopen(missing_metadata_file, 'w');

    % Search for each granule in the metadata file list
    
    iBad = 0;
    lastMetadataGranuleFound = 1;
    for i = 1:length(granule_lines)
    
        granule_line = granule_lines{i};
        
        % Make sure this line is for a .nc filename.

        if contains(granule_line, '.nc')
        
            % Extract the date and time part from the granule filename
            
            granule_time_str = extractBetween(granule_line, 'AQUA_MODIS.', '.L2.SST.nc');

            % Search for corresponding metadata file
            
            found = false;
            for j = lastMetadataGranuleFound:length(metadata_lines)
            
                metadata_time_str = extractBetween(metadata_lines{j}, 'AQUA_MODIS_', '_L2_SST_OBPG_extras.nc4');
                if strcmp(granule_time_str, metadata_time_str)
                    found = true;
                    lastMetadataGranuleFound = j;
                    break;
                end
            end

            % If no corresponding metadata file is found, write to missing list
            if ~found
                iBad = iBad + 1;
                missing_files{iBad} = granule_line;

                fprintf( fid_missing,     '%s\n', granule_line);
                fprintf( fid_missing_ALL, '%s\n', granule_line);
            end
        end
    end

    fclose(fid_missing);
end

fclose(fid_missing_ALL);
end