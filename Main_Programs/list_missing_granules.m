% list_missing_granules - Lists granules at OBPG but not in NASA AWS repository - PCC
%
% This function reads the files,  'MissingGranuleList_2004mat.mat', written
% at AWS and writes them out in a new txt file.
%
% INPUT
%   none
%
% OUTPUT
%   none
%
%  CHANGE LOG
%   v. #  -  data    - description     - who
%
%   1.0.0 - 9/6/2024 - Initial version - PCC

clear global granuleList iGranuleList numGranules

global version_struct
version_struct.list_missing_granules = '1.0.0';

global metadata_directory granuleList iGranuleList numGranules

% Initialize variables.

yearStart = 2002;
yearEnd = 2024;

Local = false;

kGranule = 0;

% Specify the output text file name
outputFile = 'file_names_list.txt';  % Change the name if needed

% Open the output file.
fileID = fopen(outputFile, 'w');

metadata_directory = '/Volumes/MODIS_L2_modified/OBPG/Data_from_OBPG_for_PO-DAAC/';

% Loop over years to process

for iYear=yearStart:yearEnd
    jGranule = 0;

    fprintf('Working on %i.\n', iYear)

    clear missingList

    load([metadata_directory 'metadata_granule_lists/ MissingGranuleList_' num2str(iYear) 'mat.mat']);

    numGranules = length(missingList);

    % Loop through the files and write their names to the text file

    for iGranule = 1:numGranules
        fprintf(fileID, '%s\n', fileList(iGranule).name);
    end
end

% Close the file
fclose(fileID);
