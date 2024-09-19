function fix_bad_OBPG_metadata_files( Year, iGranule)
% fix_bad_OBPG_metadata_files - files found when creating file lists - PCC
%

% Get string version of year to use in the construction of filenames.

YearS = num2str(Year);

% Define directories to use

granule_list_dir =      '/Users/petercornillon/Dropbox/Data/MODIS_L2/granule_lists/';
metadata_directory =    '/Volumes/MODIS_L2_modified/OBPG/Data_from_OBPG_for_PO-DAAC/';

% base_dir_in =           '/Volumes/Aqua-1/MODIS_R2019/combined/';
base_dir_in =           '/Volumes/MODIS_L2_Original/OBPG/combined/';
base_dir_out =          '/Volumes/MODIS_L2_Modified/OBPG/Data_from_OBPG_for_PO-DAAC/';

% Load the granule list for this year.

eval(['load ~/Dropbox/Data/MODIS_L2/granule_lists/GoodGranuleList_' YearS '.mat'])

% Display the contents of the 'bad' granule and check that it is the one to fix. 

granuleList(iGranule)
	
action = input('Does this look right to you (y/n): ', 's');

if strcmp(action, 'n')
    return
elseif strcmp(action, 'k')
    keyboard
end

% OK, looks good, get the filename

% Need to make the 2nd filename from the first on
% AQUA_MODIS_20161013T203510_L2_SST_OBPG_extras.nc4
% AQUA_MODIS.20161013T203510.L2.SST.nc

metadataFilename = granuleList(iGranule).filename;

OBPGFilename = ['AQUA_MODIS.' char(extractBetween(metadataFilename, '_MODIS_', '_L2_')) '.L2.SST.nc'];

%% First fix the OBPG metadata file.

file_in = [ base_dir_in YearS '/' OBPGFilename];
file_out = [base_dir_out YearS '/' metadataFilename];

% Get year and month to put this granule in the proper directory.

nn_year = strfind(file_in, 'AQUA_MODIS.') + 11;
YearS = file_in(nn_year:nn_year+3);
MonthS = file_in(nn_year+4:nn_year+5);
DayS = file_in(nn_year+6:nn_year+7);

action = input(['Ready to extract metadata from ' file_in ', want to continue (y): '], 's');
if strcmp(action, 'n')
    fprintf('Bummer, sounds like you don''t like what it did.\n')
    return
elseif strcmp(action, 'k')
    keyboard
end

status = system(['/usr/local/bin/nccopy -w -V year,day,msec,slon,slat,clon,clat,elon,elat,csol_z,sstref,qual_sst,flags_sst,tilt ' file_in ' ' file_out]);

if status == 0
    eval(['! aws s3 cp ' file_out ' s3://uri-gso-pcornillon/Data_from_OBPG_for_PO-DAAC/' YearS ' / --profile iam_pcornillon'])
else
    fprintf('Problem with OBPG metadata for %s\n', file_in)
    return
end

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

good_file_out = ['/Users/petercornillon/Dropbox/Data/MODIS_L2/granule_lists/GoodGranuleList_' YearS '.mat'];

action = input(['I''m about to save ' good_file_out '. Is that OK with you? (y/n/k) : '], 's');
if strcmp(action, 'n')
    fprintf('Bummer, sounds like you don''t like what it did.\n')
    return
elseif strcmp(action, 'k')
    keyboard
end

save(good_file_out, 'granuleList');

if status == 0
    fprintf('Copying the GoodGranuleList_%s.mat to AWS.\n', good_file_out)
    eval(['! aws s3 cp ' good_file_out ' s3://uri-gso-pcornillon/Data_from_OBPG_for_PO-DAAC/metadata_granule_lists/ --profile iam_pcornillon'])
else
    fprintf('Problem with OBPG metadata for %s\n', file_in)
    return
end

% Check to see if NewGranuleList needs to be updated as well.

new_file_out = ['/Users/petercornillon/Dropbox/Data/MODIS_L2/granule_lists/NewGranuleList_' YearS '.mat'];

tempEntry = granuleList(iGranule);
tempTime = granuleList(iGranule).filename_time;

load(new_file_out)
for jGranule=1:length(granuleList)
    if granuleList(jGranule).filename_time == tempTime
        fprintf('\nFound a match NewGranuleList\n\n')
        action = input('Do you want to fix this? (y): ', 's');
        if strcmp(action, 'y')
            if status == 0
                granuleList(jGranule) = tempEntry;

                fprintf('Saving the NewGranuleList_%s.mat to AWS.\n', new_file_out)
                save(new_file_out, 'granuleList');

                fprintf('Copying the NewGranuleList_%s.mat to AWS.\n', new_file_out)
                eval(['! aws s3 cp ' new_file_out ' s3://uri-gso-pcornillon/Data_from_OBPG_for_PO-DAAC/metadata_granule_lists/ --profile iam_pcornillon'])
                break
            else
                fprintf('Problem with OBPG metadata for %s\n', file_in)
                return
            end
        elseif strcmp(action, 'k')
            keyboard
        end
    end
end


