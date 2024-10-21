% nccopy_missing_from_OBPG_to_PO_DAAC - this script will copy data from OBPG files needed to work with PO.DAAC files - PCC
%
% Specifically, it will copy year, day, msec, slon, slat, clon, clat, elon,
%  elat, csol_z, sstref, qual_sst, flags_sst and tilt from the original file
%  obtained from Goddard to a new file in the 'original' directory on one
%  of the large disks. It will also generate a diary file.
%
% It will do this for missing files found by find_missing_granules_from_OBPG
%
% INPUT
%   none
%
% OUTPUT
%   none
%


if strcmp(satellite, 'TERRA')
    skipCharacters = '11';
elseif strcmp(satellite, 'AQUA')
    skipCharacters = '10';
else
    fprintf('You entered %s as the satellite name but I don''t know this one, it has to be either TERRA or AQUA\n', satellite)
    return
end

temp = 0; % For temporary, i.e., partial directories.

% Set up for either satdat1 or macstudio

[ret, computer_name] = system('hostname');

% eval(['diary_dir = ''/Users/petercornillon/Dropbox/Data/MODIS_L2/Logs/' satellite '/'';'])
eval(['diary_dir = ''/Volumes/MODIS_L2_Modified/' satellite '/Logs/'';'])

eval(['base_dir_in = ''/Volumes/Aqua-1/MODIS_R2019/' satellite '/Missing/'';'])

eval(['base_dir_out = ''/Volumes/Aqua-1/MODIS_R2019/' satellite '/Missing_Data_from_OBPG_for_PO-DAAC/'';'])

diary_name = [ diary_dir, 'Rewrite_OBPG_for_PO-DAAC_' strrep(num2str(now), '.', '_') '.txt'];
diary(diary_name)

% Get the year, month and day at which to start processing.


% Get the list of files from which to extract metadata

dirArgument = [base_dir_in satellite '_MODIS*.nc'];
file_list = dir(dirArgument);

% Loop through the list of files extracting metadata.

numFilesProcessed = 0;
for iFile=1:length(file_list) % Loop over granules *******************************************

    file_in = [file_list(iFile).folder '/' file_list(iFile).name];

    % Has this file already been processed?

    nn_name_start = strfind(file_in, '/');
    nn_name_end = strfind(file_in, '.nc');
    good_base_filename_out = strrep(file_in(nn_name_start(end)+1:nn_name_end-1), '.', '_');
    good_filename_out = [good_base_filename_out '_OBPG_extras.nc4'];

    % Get year and month to put this granule in the proper directory.

    nn_year =  strfind(file_in, [satellite '_MODIS']) + 1 + str2num(skipCharacters);
    YearS = file_in(nn_year:nn_year+3);
    MonthS = file_in(nn_year+4:nn_year+5);
    DayS = file_in(nn_year+6:nn_year+7);

    % Check to see if this file is for a pass on or after the  start
    % month and day specified for the 1st year. If so process, if not
    % go to the next pass.

    if datenum(str2num(YearS), str2num(MonthS), str2num(DayS)) >= matlab_start

        file_out = [base_dir_out YearS '/' good_filename_out];

        if exist(file_out) == 2
            fprintf('%i: %s has already been processed; skipping to the next file. \n', iFile, file_in)
        else

            if strcmp( deblank(computer_name), '208.100.10.10.dhcp.uri.edu')
                status = system(['/opt/homebrew/bin/nccopy -w -V year,day,msec,slon,slat,clon,clat,elon,elat,csol_z,sstref,qual_sst,flags_sst,tilt ' file_in ' ' file_out]);
            else
                status = system(['/usr/local/bin/nccopy -w -V year,day,msec,slon,slat,clon,clat,elon,elat,csol_z,sstref,qual_sst,flags_sst,tilt ' file_in ' ' file_out]);
                numFilesProcessed = numFilesProcessed + 1;

                if rem(numFilesProcessed,100) == 1
                    fprintf('*** Have processed %i at %s.\n', numFilesProcessed, datestr(now))
                end
            end

            if status ~= 0
                fprintf('Problem writing fields for granule number %i named %s \n', iFile, convertCharsToStrings(file_out))
            end
        end
    end
end

