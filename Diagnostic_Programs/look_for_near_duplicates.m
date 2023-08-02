sfunction missing_granules = look_for_near_duplicates( year_in)
% look_for_near_duplicates - look for granules in combined within a few minutes of each other  - PCC
% 
% The OBPG has put granules into day and night folders. There is however
% overlap between these foloder--granules which overlap the terminus. This
% script loads the names of all granules for a given year, extracts the
% times for each from their names, writes them to an list, does a first
% difference on the times and then finds all granules separated by less
% than one minute.
%
% INPUT
%   Year - year to check.
%
% OUTPUT
%   near_duplicates - granules withinn a minute of each other.
%

near_duplicates = [];

YearS = num2str(year_in);

base_dir = '/Volumes/Aqua-1/MODIS_R2019/combined/';

% Get the list of granules in the given year of folder1.

fi_in = [base_dir '/' YearS '/'];
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
        
        nn = strfind(xx, 'AQUA_MODIS');

        Year(iFile) = str2num(A(iFile)
    end
    
    line = fgets(fileID);
end

fclose(fileID);

% Now compare the lists

nn = strfind(A(1), 'AQUA_MODIS');
iMissing = 0;

for iFile1=1:length(A)
    
    AChar = char(A(iFile1));

    granule_found = 0;
    for iFile2=1:length(B)
        
        BChar = char(B(iFile2));

        if strcmp( AChar(nn+11:nn+25), BChar(nn+11:nn+25))
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


