function nccopy_from_OBPG_to_PO-DAAC( satellite, year_list)
% nccopy_from_OBPG_to_PO-DAAC - this script will copy data from OBPG files needed to work with PO.DAAC files - PCC
%
% Specifically, it will copy year, day, msec, slon, slat, clon, clat, elon,
%  elat, csol_z, sstref, qual_sst, flags_sst and tilt from the original file
%  obtained from Goddard to a new file in the 'original' directory on one
%  of the large disks. It will also generate a diary file.
%
% It will ask for the years to copy and for the starting month and day if
%  the year is entered with a minus sign.
%
% INPUT
%   satellite - AQUA or TERRA - the satellit for which the metadata is to
%    be extracted. The satellite names must be all caps.
%   year_list - a cell array of years; e.g., {'2003' '2008' '2020'] - If 
%    the first year is negative, it will ask for the starting month and
%    day, which it will use for that year. All subsequent years will be
%    completely processed.
%
% OUTPUT 
%   none
%
% EXAMPLE
%   To extract metadata for TERRA for 2000-2002.
%
%   nccopy_from_OBPG_to_PO-DAAC( 'TERRA', {'2000' '2001' '2002'})


which_dataset = 1;
datasets = {'combined' 'recover'};

if strcmp(satellite, 'TERRA')
    skipCharacters = '10';
elseif strcmp(satellite, 'AQUA')
    skipCharacters = '11';
else
    fprintf('You entered %s as the satellite name but I don''t know this one, it has to be either TERRA or AQUA\n', satellite)
    return
end

temp = 0; % For temporary, i.e., partial directories.

% Set up for either satdat1 or macstudio

[ret, computer_name] = system('hostname');

% eval(['diary_dir = ''/Users/petercornillon/Dropbox/Data/MODIS_L2/Logs/' satellite '/'';'])
eval(['diary_dir = ''/Volumes/MODIS_L2_Modified/' satellite '/Logs/'';'])

% % % if strcmp( deblank(computer_name), '208.100.10.10.dhcp.uri.edu')
% % %     base_dir_in = '/Volumes/Aqua-1/MODIS_R2019/';
% % %     base_dir_out = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
% % % elseif strcmp( deblank(computer_name), 'satdat1.gso.uri.edu')
% % %     eval(['base_dir_in = ''/Volumes/MODIS_L2_Original/' satellite '/'';'])
% % %     eval(['base_dir_out = ''/Volumes/MODIS_L2_Modified/' satellite '/Data_from_OBPG_for_PO-DAAC/'';'])
% % % elseif strcmp( deblank(computer_name), 'satdat1.local')
% % %     eval(['base_dir_in = ''/Volumes/MODIS_L2_Original/' satellite '/'';'])
% % %     eval(['base_dir_out = ''/Volumes/MODIS_L2_Modified/' satellite '/Data_from_OBPG_for_PO-DAAC/'';'])
% % % else
% % %     eval(['base_dir_in = ''/Volumes/MODIS_L2_Original/' satellite '/'';'])
% % %     eval(['base_dir_out = ''/Volumes/MODIS_L2_Modified/' satellite '/Data_from_OBPG_for_PO-DAAC/'';'])
% % % end

eval(['base_dir_in = ''/Volumes/MODIS_L2_Original/' satellite '/'';'])
eval(['base_dir_out = ''/Volumes/MODIS_L2_Modified/' satellite '/Data_from_OBPG_for_PO-DAAC/'';'])

diary_dir = [ diary_dir, 'Rewrite_OBPG_for_PO-DAAC_' strrep(num2str(now), '.', '_') '.txt'];
diary(diary_dir)

% Get the year, month and day at which to start processing.

% fprintf('\n\nIf the first element in year list is entered with a - in front, then ask\nfor month and day to start. Otherwise, get the month and day of the most\nrecently processed file for this year and determine month and day to start if requested.\n\n')
% 
% year_list = input('Enter year(s) to process cell array (e.g., {''2003'' ''2004'' ''2005'' ''2006'' ''2007''}): ');

% If the first element in year list is entered with a - in front, then ask
%  for month and day to start. Otherwise, get the month and day of the most
%  recently processed file for this year and determine month and day to
%  start if requested

if strfind(year_list{1}, '-')
    year_list{1} = year_list{1}(2:end);
    
    month_start = input(['Enter the month to start with ', year_list{1} ' (1 for January or cr): ']);
    if isempty(month_start); month_start = 1; end
    
    day_start = input(['Enter the day to start with ', num2str(month_start) '/' year_list{1} ' (1 for first day or cr): ']);
    if isempty(day_start); day_start = 1; end
else
    month_start = 1;
    day_start = 1;
end

% Specify the cutoff date (e.g., files modified after 1st January 2023 would be entered as [2023 1 1 0 0 0]

fprintf('\n\nYou can select a cutouff date in the following. Only input files created on or after this date will be processed\nunless the cutoff date is preceeded by a minus sign. If nothing specified, all files found will be processed.\n\n')

cutoffDate = input('Specify the cutoff date as [yyyy mm dd hh mm ss]. Default, no cutoff. Preceeded by - cutoff before otherwise after: '); 

relationalOperator = '>=';

if ~isempty(cutoffDate)
    if cutoffDate(1) < 0
        cutoffDate = -cutoffDate;
        relationalOperator = '<';
    end
end

disp(['Successfully started job submitted for ' year_list{1} ' starting at month ' num2str(month_start) ' and day ' num2str(day_start)])

matlab_start = datenum(str2num(year_list{1}), month_start, day_start);

% Now loop over years to process

for iYear=1:length(year_list) % Loop over years to process ......................................
    
    fprintf('Processing %5.0f \n', convertCharsToStrings(year_list{iYear}))
    
    % Get the list of files to consider for processing.
    
    YearS = year_list{iYear};
    if temp
        dirArgument = [base_dir_in datasets{which_dataset} '/temp_' YearS '/' satellite '_MODIS*.nc'];
        temp_file_list = dir(dirArgument);
    else
        dirArgument = [base_dir_in datasets{which_dataset} '/' YearS '/' satellite '_MODIS*.nc'];
        temp_file_list = dir(dirArgument);
    end

    % If a cutoff date has been specified filter the file list.
    % Initialize an array to store the filtered files
    
    if ~isempty(cutoffDate)
        file_list = [];

        % Loop through the list of files and filter by date

        for i = 1:length(temp_file_list)

            % Get the modification date of the current file

            fileDate = datetime(temp_file_list(i).date);

            % Check if the file date is after the cutoff date

            eval(['cutoffDateTest = ' num2str(datenum(fileDate)) relationalOperator num2str(datenum(cutoffDate)) ';'])
            if cutoffDateTest
                % Add the file to the filtered list

                file_list = [file_list; temp_file_list(i)];
            end
        end
    else
        file_list = temp_file_list;
    end

    tic
    for iFile=1:length(file_list) % Loop over granules *******************************************
        
        file_in = [file_list(iFile).folder '/' file_list(iFile).name];
        
%         if mod(iFile,1000) == 0
%             fprintf('Processed file #%i - %s - Elapsed time %6.0f seconds. \n', iFile, convertCharsToStrings(file_in), toc)
%             tic
%         end
        
        % Has this file already been processed?
        
        nn_name_start = strfind(file_in, '/');
        nn_name_end = strfind(file_in, '.nc');
        good_base_filename_out = strrep(file_in(nn_name_start(end)+1:nn_name_end-1), '.', '_');
        good_filename_out = [good_base_filename_out '_OBPG_extras.nc4'];
        
        % Get year and month to put this granule in the proper directory.
        
        eval(['nn_year = strfind(' strfindArgument ') + ' skipCharacters ';'])
        YearS = file_in(nn_year:nn_year+3);
        MonthS = file_in(nn_year+4:nn_year+5);
        DayS = file_in(nn_year+6:nn_year+7);
        
        % Check to see if this file is for a pass on or after the  start
        % month and day specified for the 1st year. If so process, if not
        % go to the next pass.
        
        if datenum(str2num(YearS), str2num(MonthS), str2num(DayS)) >= matlab_start
            
            if temp
                file_out = [base_dir_out 'temp_' YearS '/' good_filename_out];
            else
                file_out = [base_dir_out YearS '/' good_filename_out];
            end

            if exist(file_out) == 2
%                 fprintf('%i: %s has already been processed; skipping to the next file. \n', iFile, convertCharsToStrings(file_list(iFile).name))
            else
                
                if strcmp( deblank(computer_name), '208.100.10.10.dhcp.uri.edu')
                    status = system(['/opt/homebrew/bin/nccopy -w -V year,day,msec,slon,slat,clon,clat,elon,elat,csol_z,sstref,qual_sst,flags_sst,tilt ' file_in ' ' file_out]);
                else
                    status = system(['/usr/local/bin/nccopy -w -V year,day,msec,slon,slat,clon,clat,elon,elat,csol_z,sstref,qual_sst,flags_sst,tilt ' file_in ' ' file_out]);
                end
                
                if status ~= 0
                    fprintf('Problem writing fields for granule number %i named %s \n', iFile, convertCharsToStrings(file_out))
                end
            end
        end
    end
end
toc
