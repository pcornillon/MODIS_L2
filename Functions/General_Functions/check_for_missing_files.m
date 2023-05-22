function missing_granules = check_for_missing_files( folder1, folder2, Year)
% check_for_missing_files - Find files in folder2 that are not in folder1  - PCC
% 
% This function will get a text file list of all the granules in two
% folders for the given year. It will then search the list for folder2 for
% all files in folder1, returning a list of the missing ones.
%
% INPUT
%   folder1 - the first folder to examine.'
%   folder2 - the second folder to examine.'
%   Year - year to check.
%
% OUTPUT
%   missing_granules - granules in folder1 missing from folder2.
%

YearS = num2str(Year);

base_dir = '/Volumes/Aqua-1/MODIS_R2019/';

% Get the list of granules in the given year of folder1.

eval(['! cd ' base_dir folder1 '/' YearS '/']);
! ls > file_list.txt

% Now opend and read the file with the list of granules.

fileID = fopen(fi, 'r');
line = fgets(fileID);

iFile = 0;
while ischar(line)
    nn = strfind(line, '.nc');
    xx = string(line(1:nn+2));

    iFile = iFile + 1;
    A(iFile) = xx;
    
    line = fgets(fileID);
end

fclose(fileID)

% Repeat for folder2.

eval(['! cd ' base_dir folder2 '/' YearS '/']);
! ls > file_list.txt

% Now opend and read the file with the list of granules.

fileID = fopen(fi, 'r');
line = fgets(fileID);

iFile = 0;
while ischar(line)
    nn = strfind(line, '.nc');
    xx = string(line(1:nn+2));

    iFile = iFile + 1;
    B(iFile) = xx;
    
    line = fgets(fileID);
end

fclose(fileID)

% Now compare the lists

nn = strfind(A(1), 'AQUA_MODIS');
iMissing = 0;

for iFile1=1:length(A)
    
    granule_found = 0;
    for iFile2=1:length(B)
        
        if strcmp(A(nn+12:nn+27), B(nn+12:nn+27))
            granule_found = 1;
            break
        end
    end
    
    % Add this granule to the list if missing.
    
    if granule_found == 0
        iMissing = iMissinng + 1;
        missing_granules(iMissing) = A(iFile);
    end
end


