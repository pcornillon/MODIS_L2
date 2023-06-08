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

missing_granules = string('');

YearS = num2str(Year);

base_dir = '/Volumes/Aqua-1/MODIS_R2019/';

% Get the list of granules in the given year of folder1.

fi_in = [base_dir folder1 '/' YearS '/'];
fi_out = [fi_in 'file_list.txt'];
eval(['! ls ' fi_in ' > ' fi_out])

% Now open and read the file with the list of granules for folder1.

fileID = fopen( fi_out, 'r');
line = fgets(fileID);

iFile = 0;
while ischar(line)
    nn = strfind(line, '.nc');
    if ~isempty(nn)
        xx = string(line(1:nn+2));

        iFile = iFile + 1;
        A(iFile) = xx;
    end
    
    line = fgets(fileID);
end

fclose(fileID);

% Repeat for folder2.

fi_in = [base_dir folder2 '/' YearS '/'];
fi_out = [fi_in 'file_list.txt'];
eval(['! ls ' fi_in ' > ' fi_out])

% Now open and read the file with the list of granules for folder2.

fileID = fopen(fi_out, 'r');
line = fgets(fileID);

iFile = 0;
while ischar(line)
    nn = strfind(line, '.nc');
    if ~isempty(nn)
        xx = string(line(1:nn+2));

        iFile = iFile + 1;
        B(iFile) = xx;
    end
    
    line = fgets(fileID);
end

fclose(fileID);

% Now compare the lists

nn = strfind(A(1), 'AQUA_MODIS');
iMissing = int16(0);

for iFile1=1:length(A)
    
    AChar = char(A(iFile1));

    granule_found = 0;
    for iFile2=max([1,iFile1-10]):length(B)
        
        BChar = char(B(iFile2));

        if strcmp( AChar(nn+11:nn+25), BChar(nn+11:nn+25))
            granule_found = 1;
            break
        end
    end
    
    % Add this granule to the list if missing.
    
    if granule_found == 0
        iMissing = iMissing + 1;
        missing_granules(iMissing) = A(iFile1);
    end
end

fprintf('Found %i granules in %s but missing from %s for %s\n', iMissing, string(folder1), string(folder2), string(YearS))

