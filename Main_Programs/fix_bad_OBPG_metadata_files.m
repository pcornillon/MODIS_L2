function fix_bad_OBPG_metadata_files( Year, iGranule)
% fix_bad_OBPG_metadata_files - files found when creating file lists - PCC
%

% Get string version of year to use in the construction of filenames.

YearS = num2str(Year);

% Define directories to use

granule_list_dir =      '/Users/petercornillon/Dropbox/Data/MODIS_L2/granule_lists/';
metadata_directory =    '/Volumes/MODIS_L2_modified/OBPG/Data_from_OBPG_for_PO-DAAC/';

base_dir_in =           '/Volumes/Aqua-1/MODIS_R2019/combined/';
base_dir_out =          '/Volumes/MODIS_L2_Modified/OBPG/Data_from_OBPG_for_PO-DAAC/';

% Load the granule list for this year.

eval(['load ~/Dropbox/Data/MODIS_L2/granule_lists/GoodGranuleList_' YearS '.mat)'])

% Display the contents of the 'bad' granule and check that it is the one to fix. 

granuleList(iGranule)
	
action = input('Does this look right to you (y/n): ', 's');

if strcmp(action, 'n')
    return
end

% OK, looks good, get the filename

% Need to make the 2nd filename from the first on
% AQUA_MODIS_20161013T203510_L2_SST_OBPG_extras.nc4
% AQUA_MODIS.20161013T203510.L2.SST.nc

metadataFilename = granuleList(iGranule).filename;

OBPGFilename = ['AQUA_MODIS.' extractBetween(metadataFilename, '_MODIS_', '_L2_') '.L2.SST.nc'];

%% First fix the OBPG metadata file.

file_in = [ base_dir_in '/' YearS '/OBPGFilename']);
good_filename_out = [base_dir_out metadataFilename];

% Get year and month to put this granule in the proper directory.

nn_year = strfind(file_in, 'AQUA_MODIS.') + 11;
YearS = file_in(nn_year:nn_year+3);
MonthS = file_in(nn_year+4:nn_year+5);
DayS = file_in(nn_year+6:nn_year+7);

action = input(['Ready to extract metadata from ' file_in ', want to continue (y): '], 's');
if strcmp(action, 'n')
    fprintf('Bummer, sounds like you don''t like what it did.\n')
    return
end

status = system(['/usr/local/bin/nccopy -w -V year,day,msec,slon,slat,clon,clat,elon,elat,csol_z,sstref,qual_sst,flags_sst,tilt ' file_in ' ' file_out]);

%% Now fix file lists

temp_filename = [metadata_directory num2str(year(granuleList(iGranule).filename_time)) '/' granuleList(iGranule).filename]; 
fprintf('Now fixing the file lists. Working on %s\n\n', temp_filename)

% Get the time information to determine the time of the 1st scan in the granule.

tYear = ncread( temp_filename, '/scan_line_attributes/year');
tYrDay = ncread( temp_filename, '/scan_line_attributes/day');
[tMonth, tDay] = doy2mmdd(tYear(1), tYrDay(1));
tmSec = ncread( temp_filename, '/scan_line_attributes/msec');
tSec = tmSec(1) / 1000;
tHour = floor( tSec / 3600);
tMinute = floor( (tSec - tHour  * 3600) / 60);
tSecond = round( tSec - tHour * 3600 - tMinute * 60);

% Put it all together.

granuleList(iGranule).first_scan_line_time = datenum( [tYear(1), tMonth, tDay, tHour, tMinute, tSecond]);


granuleList(iGranule).filename
datestr(granuleList(iGranule).first_scan_line_time)

action = input('If the above looks good, type y to save: ', 's');
if strcmp(action, 'n')
    fprintf('Bummer, sounds like you don''t like what it did.\n')
    return
end

save('~/Dropbox/Data/MODIS_L2/granule_lists/GoodGranuleList_2016.mat', 'granuleList');

aws s3 cp /Users/petercornillon/Dropbox/Data/MODIS_L2/granule_lists/GoodGranuleList_2016.mat s3://uri-gso-pcornillon/Data_from_OBPG_for_PO-DAAC/metadata_granule_lists/ --profile iam_pcornillon
% aws s3 cp /Users/petercornillon/Dropbox/Data/MODIS_L2/granule_lists/NewGranuleList_2016.mat s3://uri-gso-pcornillon/Data_from_OBPG_for_PO-DAAC/metadata_granule_lists/ --profile iam_pcornillon


