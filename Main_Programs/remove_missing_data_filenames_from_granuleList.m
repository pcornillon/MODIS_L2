function remove_missing_data_filenames_from_granuleList
% remove_missing_data_filenames_from_granule_list - PCC
%
% NOTE: NEED TO SET yearStart AND yearEnd BELOW!
%
% This function will step through granuleList and removes entries with no
% corresponding data files at AWS.
%
% INPUT
%   none
%
% OUTPUT
%   none
%
%  CHANGE LOG
%   v. #  -  data    - description     - who
%
%   1.0.0 - 7/23/2024 - Initial version - PCC
%   1.0.1 - 7/26/2024 - Added print_Ex00 variables to control printout in 
%           populate_problems - PCC

clear global amazon_s3_run formatOut secs_per_day iProblem problem_list ...
    s3_expiration_time granuleList iGranuleList numGranules

global version_struct
version_struct.remove_missing_data_filenames_from_granuleList = '1.0.0';

global s3_expiration_time

% globals for the run as a whole.

% globals for build_orbit part.

global formatOut
global secs_per_day

global granules_directory metadata_directory
global granuleList iGranuleList numGranules

global iProblem problem_list

global amazon_s3_run

global print_E100 print_E300 print_E600 print_E700 print_E800 print_E900 

% Initialize variables.

yearStart = 2014;
yearEnd = 2014;

Local = false;

print_E100 = true;
print_E300 = true;
print_E700 = true;
print_E800 = true;
print_E900 = true;

kGranule = 0;

iProblem = 0;

formatOut.dd = 'dd';
formatOut.mm = 'mm';
formatOut.yyyy = 'yyyy';

formatOut.HH = 'HH';
formatOut.MM = 'MM';
formatOut.SS = 'SS';

formatOut.yyyymmdd = 'yyyymmdd';
formatOut.HHMMSS = 'HHMMSS';

formatOut.yyyymmddTHHMMSS = 'yyyymmddTHHMMSS';
formatOut.yyyymmddTHHMM = 'yyyymmddTHHMM';
formatOut.yyyymmddTHH = 'yyyymmddTHH';

formatOut.yyyymmddHHMMSS = 'yyyymmddHHMMSS';
formatOut.yyyymmddHHMM = 'yyyymmddHHMM';
formatOut.yyyymmddHH = 'yyyymmddHH';

secs_per_day = 86400;

if Local
    metadata_directory = '/Volumes/MODIS_L2_modified/OBPG/Data_from_OBPG_for_PO-DAAC/';
    granules_directory = '/Volumes/MODIS_L2_Original/OBPG/combined/';

    amazon_s3_run = false;
else

    amazon_s3_run = true;

    % Get AWS credentials.

    [status, s3Credentials] = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', 'eiMTJr6yeuD6');

    % if status == 921
    if status >= 900
        return
    end

    metadata_directory = '/mnt/s3-uri-gso-pcornillon/Data_from_OBPG_for_PO-DAAC/';
    granules_directory = 's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';
end

% Loop over years to process

for iYear=yearStart:yearEnd
    jGranule = 0;

    fprintf('Working on %i.\n', iYear)

    % % % if iYear == yearStart
    load([metadata_directory 'metadata_granule_lists/GoodGranuleList_' num2str(iYear) '.mat']);
    % % % else
    % % %     tempList = load([metadata_directory 'metadata_granule_lists/GoodGranuleList_' num2str(iYear) '.mat']);
    % % %     granuleList = [granuleList tempList(1).granuleList];
    % % % end
    % % % end

    numGranules = length(granuleList);

    for iGranuleList=1:numGranules
        
        if mod(iGranuleList,20000)==0
            fprintf('Working on file %i in %i. Date/Time: %s\n', iGranuleList, iYear, datestr(now))
        end
        
        if ~Local
            if (now - s3_expiration_time) > 30 / (60 * 24)
                [status, s3Credentials] = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', 'eiMTJr6yeuD6');

                if status >= 900
                    fprintf('Problem getting AWS credentials. iGranuleList=%i\n.', iGranuleList)
                    return
                end
            end
        end

        % Get the next metadata granule.

        [status, found_one, metadata_granule_folder_name, metadata_granule_file_name, granule_start_time] = get_filename('metadata');

        if status >= 900
            fprintf('Missing metadata granule for iGranuleList=%i. This should never happen.\n', iGranuleList)
            return
        end

        % Get the metadata filename.

        metadata_temp_filename = [metadata_granule_folder_name metadata_granule_file_name];

        % Is the data granule for this time present? If so, get the range
        % of locations of scanlines in the orbit and the granule to use.
        % Otherwise, add to problem list and continue search for a data
        % granule; remember, a metadata granule was found so this should
        % not occur. BUT FIRST, search for a granule within a minute of
        % the time passed in.

        [status, found_one, data_granule_folder_name, data_granule_file_name, ~] = get_filename('sst_data');

        if found_one

            jGranule = jGranule + 1;

            newList(jGranule) = granuleList(iGranuleList);

        else

            fprintf('Data granule #%i for metadata granule %s is missing.\n', iGranuleList, metadata_granule_file_name)
            kGranule = kGranule + 1;
            missingList(kGranule) = granuleList(iGranuleList);
        end
    end
    granuleList = newList;
    save([metadata_directory 'metadata_granule_lists/NewGranuleList_' num2str(iYear) '.mat'], 'granuleList') 
    clear newList
    save([metadata_directory 'metadata_granule_lists/MissingGranuleList_' num2str(iYear) 'mat'], 'missingList') 
end

