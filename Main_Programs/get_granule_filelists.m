function get_granule_filelists(Years)
% get_granule_filelists - generates list of filenames and Matlab time extracted from the names - PCC
%
% INPUT
%   Years: vector of years to process [2002:2005]

metadata_directory = '/Volumes/MODIS_L2_modified/OBPG/Data_from_OBPG_for_PO-DAAC/';

Test = 0;

for iYear=1:length(Years)
    
    Year = Years(iYear);
    YearString = num2str(Year);
    
    fprintf('Starting to process %i at %s \n', Year, datetime)
    tic;
    
    % Get the file list for this year.
    
    if Test
        % load ~/Dropbox/TempForTransfer/filelist.mat
        load ~/Desktop/filelist.mat
    else
        eval(['fileList = dir([metadata_directory ''' YearString '/AQUA*'']);'])
    end
    
    granuleList(length(fileList)).filename = fileList(end).name;
    granuleList(length(fileList)).filename_time = parse_filename(fileList(end).name);
    
    for iGranule=1:length(fileList)
        filename = fileList(iGranule).name;

        if rem(iGranule,10000) == 0
            fprintf('Working on granule %i: %s. Current date/time %s\n', iGranule, filename, datestr(now))
        end

        granuleList(iGranule).filename = filename;
        granuleList(iGranule).filename_time = parse_filename(filename);

        % % % tempTime = ncreadatt( [metadata_directory num2str(year(granuleList(iGranule).filename_time)) '/' granuleList(iGranule).filename], '/', 'time_coverage_start');
        % % % granuleList(iGranule).granule_start_time = datenum(datetime(tempTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''', 'TimeZone', 'UTC'));

        temp_filename = [metadata_directory num2str(year(granuleList(iGranule).filename_time)) '/' granuleList(iGranule).filename];
        tYear = ncread( temp_filename, '/scan_line_attributes/year');
        tYrDay = ncread( temp_filename, '/scan_line_attributes/day');
        tmSec = ncread( temp_filename, '/scan_line_attributes/msec');

        granuleList(iGranule).granule_start_time = datenum( tYear(1), ones(size(tYear(1))), tYrDay(1)) + tmSec(1) / 1000 / 86400;

    end
    
    eval(['save(''~/Dropbox/Data/MODIS_L2/GoodGranuleList_' YearString '.mat'', ''granuleList'');']);
    
    clear granuleList fileList
    
    time_to_process = toc;
    
    fprintf('%7.1f seconds or %4.1f minutes to process %s. Current date/time is: %s\n', time_to_process, time_to_process/60, YearString, datetime)
end