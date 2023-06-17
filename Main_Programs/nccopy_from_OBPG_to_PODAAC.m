% nccopy_from_OBPG_to_PO-DAAC - this script will copy data from OBPG files needed to work with PO.DAAC files - PCC
%
% Specifically, it will copy year, day, msec, slon, slat, clon, clat, elon,
%  elat, csol_z, sstref, qual_sst, flags_sst and tilt from the original file
%  obtained from Goddard to a new file in the 'original' directory on one
%  of the large disks. It will also generate a diary file.
%
% It will ask for the years to copy and for the starting month and day if
%  the year is entered with a minus sign.

% Set up for either satdat1 or macstudio

[ret, computer_name] = system('hostname');

% base_dir_out = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';

if strcmp( deblank(computer_name), '208.100.10.10.dhcp.uri.edu')
%     diary_dir = '/Volumes/MSG-GOES-AMSR-MODEL/MODIS_L2/Logs/';
    diary_dir = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';
%     base_dir_in = '/Volumes/MODIS-AVHRR/MODIS_L2/';
    base_dir_in = '/Volumes/Aqua-1/MODIS_R2019/';
    
%     base_dir_out = '/Volumes/MSG-GOES-AMSR-MODEL/MODIS_L2/Data_from_OBPG_for_PO-DAAC/';
    base_dir_out = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
else
    %     diary_dir = '/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/Logs/';
%     diary_dir = '/Users/petercornillon/MATLAB/Projects/Temp_for_MODIS_L2/Logs/';
    diary_dir = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';
    base_dir_in = '/Volumes/Aqua-1/MODIS_R2019/';
    base_dir_out = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
end

diary_dir = [ diary_dir, 'Rewrite_OBPG_for_PO-DAAC_' strrep(num2str(now), '.', '_') '.txt'];
diary(diary_dir)

% Get the year, month and day at which to start processing.

fprintf('\n\nIf the first element in year list is entered with a - in front, then ask\nfor month and day to start. Otherwise, get the month and day of the most\nrecently processed file for this year and determine month and day to start if requested.\n\n')

year_list = input('Enter year(s) to process cell array (e.g., {''2003'' ''2004'' ''2005'' ''2006'' ''2007''}): ');

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
    file_list = dir( [ base_dir_out, year_list{1} '/AQUA*']);
    month_start = 1;
    day_start = 1;
end

disp(['Successfully started job submitted for ' year_list{1} ' starting at month ' num2str(month_start) ' and day ' num2str(day_start)])

matlab_start = datenum(str2num(year_list{1}), month_start, day_start);

% Now loop over years to process

for iYear=1:length(year_list) % Loop over years to process ......................................
    
    fprintf('Processing %5.0f \n', convertCharsToStrings(year_list{iYear}))
    
    % Get the list of files to consider for processing.
    
    YearS = year_list{iYear};
    file_list = dir([ base_dir_in, 'combined/' YearS '/AQUA*.nc']);
    
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
        
        nn_year = strfind(file_in, 'AQUA_MODIS.') + 11;
        YearS = file_in(nn_year:nn_year+3);
        MonthS = file_in(nn_year+4:nn_year+5);
        DayS = file_in(nn_year+6:nn_year+7);
        
        % Check to see if this file is for a pass on or after the  start
        % month and day specified for the 1st year. If so process, if not
        % go to the next pass.
        
        if datenum(str2num(YearS), str2num(MonthS), str2num(DayS)) >= matlab_start
            
            file_out = [base_dir_out YearS '/' good_filename_out];
            
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
