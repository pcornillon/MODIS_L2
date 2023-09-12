% find_OBPG_match - matches list of OBPG granules with Data_from_OBPG_for_PO-DAAC - PCC
%
% This function opens the list of granules at OBPG obtained as described in
% OneNote, reads each line and looks for a file with the same name in the
% Data_from_OBPG_for_PO-DAAC directories. Notes if not found.
%

missing_granules = {};
iMissingGranule = 0;

% The directory in which the metadata granules to be copied to AWS are stored.

base_md_url = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';

% Now loop over lists of data from OBPG

for iYear=2002:2022

    % Get the filename with the file with the input list for this year and open it. 

    input_list = ['~/Dropbox/TempForTransfer/' num2str(iYear) '-day_and_night_MODIS_SST_list.txt'];

    fileID = fopen( input_list ,'r');

    % Loop over filenames on this list.

    iGranules = 0;
    while 1==1

        % Get the next line.

        input_line = fgets(fileID);

        iGranules = iGranules + 1;

        if rem(iGranules, 10000) == 0
            fprintf('Working on file #%i -- %s\n', iGranules, input_line)
        end

        if ischar(input_line)
            base_name = strrep(input_line(1:33), '.', '_');

            % Get the year for this granule.

            Year = base_name(12:15);

            fimd = [base_md_url Year '/' base_name '_OBPG_extras.nc4'];

            if exist(fimd) ~= 2
                % Metadata for granule is missing
                iMissingGranule = iMissingGranule + 1;
                fprintf('Missing granule for input file #%i: %s.  Metadata filename: %s\n', iGranules, input_line(1:end-1), fimd)

                missing_granules(iMissingGranule) = {input_line(1:end-1)};
            end
        else
            % Here if this line is a number the list has been read.

            break
        end
    end
end

% How about just the ones for 2002-2021 and without NRT.

im = 0;
for iMissing=1:length(missing_granules)
    if (isempty(strfind(missing_granules{iMissing}, 'NRT')) == 1) & (str2num(missing_granules{iMissing}(12:15)) ~= 2022) & (str2num(missing_granules{iMissing}(12:15)) ~= 2023)
        im = im + 1;
        new_missing_granules{im} = missing_granules{iMissing};
        fprintf('%i) %s\n', im, new_missing_granules{im})
    end
end
