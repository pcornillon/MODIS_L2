% rename_NRT_files - find nrt metadata granules and rename without nrt_ - PCC
%
% Some of the OBPG granules have 'nrt_' in their names. The corresponding
% data granules in NASA's AWS S3 repository do not have 'nrt_' in their
% names. (I checked a few and the SST fields are identical.) The purpose of
% this script is to rename these granules, removing the 'NRT_'.
%

clear renamed_granules

metadata_run = 0;

if metadata_run
    base_dir = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
else
    base_dir = '/Volumes/Aqua-1/MODIS_R2019/combined/';
end



iRenamed = 0;

for iYear=2022:2023
    YearS = num2str(iYear);

    % Get the list of granules with NRT in their names for this year.

    dir_in = [base_dir YearS '/'];
    filelist = dir([dir_in 'AQUA*NRT*']);

    for iFile=1:length(filelist)

        file_in  = [filelist(iFile).folder '/' filelist(iFile).name];

        if metadata_run
            file_out = strrep(file_in, '_NRT', '');
        else
            file_out = strrep(file_in, '.NRT', '');
        end

        iRenamed = iRenamed + 1;
        renamed_granules(iRenamed) = string(file_in);

        fprintf('%i) Renaming %s to %s\n', iRenamed, file_in, file_out)

        eval(['! mv -n ' file_in ' ' file_out])
    end
end

rename_filelist = dir([base_dir 'Filelists_and_Logs/rename_log*']);

if ~isempty(rename_filelist)
    log_filelist = dir([base_dir 'Filelists_and_Logs/rename_log*']);
    next_log = length(log_filelist) + 1;

    fileout = [base_dir 'Filelists_and_Logs/rename_log_' num2str(next_log) '.txt'];
end

save( fileout, 'iRenamed', 'renamed_granules')
