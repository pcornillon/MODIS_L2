function [status, found_one, folder_name, file_name, granule_start_time] = get_filename(file_type)
% get_filename - get the name of the NASA data file from the AWS S3 NASA bucket - PCC
%
% This function will get the approximate time of the granule to search for
% from the metadata name and then test a filename second-by-second in the
% S3 bucket.
%
% INPUT
%   file_type - 'sst_data' for NASA granule data or 'metadata' for OBPG
%    metadata file in S3 bucket.
%
% OUTPUT
%   status - 921 if timed out on credentials request, 0 otherwise.
%   found_one - 1 if a data file was found corresponding to the metadata
%    file and 0 if none was found within one minute.
%   folder_name - the folder in which the file was found.
%   file_name - the name of the data file found.
%   granule_start_time - the start time, which was altered in the call for 'metadata'.
%
%  CHANGE LOG
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/6/2024 - Initial version - PCC
%   1.0.1 - 5/6/2024 - Added  versioning and added some comment lines
%           related to the need to check for s3 credentials - PCC 
%   1.0.2 - 5/12/2024 - Test to see if failure to get NASA se credentials
%           end the run if this is the case with status=921. Addes status
%           to return.
%   2.0.0 - 5/17/2024 - Modified code for switch to list of granules/times.
%           Also, significant changes to arguments passed in and out.
%           Updated error handling as we move from granule_start_time to
%           metadata granule list - PCC 

global version_struct
version_struct.get_filename = '2.0.0';

% globals for the run as a whole.

global granules_directory metadata_directory

% globals for build_orbit part.

global formatOut
global s3_expiration_time amazon_s3_run
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length secs_per_granule_minus_10 

global newGranuleList iGranuleList filenamePrefix filenameEnding numGranules

status = 0;
found_one = 0;

folder_name = '';
file_name = '';

granule_start_time = nan;

switch file_type

    case 'metadata'
        found_one = 0;

        if iGranuleList < numGranules
            folder_name = [metadata_directory newGranuleList(iGranuleList).matTime(1:4) '/'];
            file_name = [filenamePrefix newGranuleList(iGranuleList).filename filenameEnding];

            granule_start_time = newGranuleList(iGranuleList).matTime;

            % Check to make sure that this metadata file really exists, AS IT SHOULD.

            if exist([folder_name file_name])
                found_one = 1;
            else
                status = populate_problem_list( 605, ['Metadata granule ' newGranuleList(iGranuleList).filename ' not found. This should never happen.'], granule_start_time); % old status 101
            end
        else
            status = populate_problem_list( 905, ['Ran out of granules, only ' num2str(numGranules) ' on the list and the granule count has reached ' num2str(iGranuleList) '.'], newGranuleList(iGranuleList-1).matTime+fiveMinutesMatTime); % old status 101
        end

    case 'sst_data'

        % Get the time of the metadata file. Start by finding where in the
        % string the data and time info is. 

        md_date = datestr(newGranuleList(iGranuleList).matTime, formatOut.yyyymmdd);
        md_time = datestr(newGranuleList(iGranuleList).matTime, formatOut.HHMMSS);

        % Will first get components of the filename, which differ from data
        % at URI, as copied from OBPG, and at AWS.

        if amazon_s3_run

            % make sure that access credentials for NASA S3 files are still
            % active. Note that the s3 access is further down (lines 133,
            % 147, 165 and 169 in this function where an exist is done on
            % the filename. 
            
            if (now - s3_expiration_time) > 30 / (60 * 24)
                [status, s3Credentials] = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', 'eiMTJr6yeuD6');
                
                % if status == 921
                if status >= 900
                    return
                end
            end

            % s3 data granule: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100419015508-JPL-L2P_GHRSST-SSTskin-MODIS_A-N-v02.0-fv01.0.nc
            %   granules_directory = 's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';

            filename_start = '';
            filename_end_day = '-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc';
            filename_end_night = '-JPL-L2P_GHRSST-SSTskin-MODIS_A-N-v02.0-fv01.0.nc';
            dir_year = '';
            date_time_separator = '';
        else
            % modis metadata file: AQUA_MODIS.20030103T120006.L2.SST.nc
            %   granules_directory = '/Volumes/MODIS_L2_original/OBPG/combined/';  OR
            %   granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';


            filename_start = 'AQUA_MODIS.';
            filename_end_day = '.L2.SST.nc';
            filename_end_night = filename_end_day;

            dir_year = [md_date(1:4) '/'];
            date_time_separator = 'T';
        end

        % Build the filename.

        data_filename = [granules_directory dir_year filename_start md_date date_time_separator md_time filename_end_day];

        % Well, does this sucker exist? If not, continue searching for a file.

        if exist(data_filename)
            found_one = 1;
        else
            % If the file does not exist check for a nighttime version of it.

            % Note that since filename_end_night = filename_end_day for
            % granules at URI (i.e., not in an S3 bucket), the script will
            % perform two identical searches if the file is not found on the
            % first one. Yup, that's slower but these runs are just for debug
            % purposes and the extra time to do this is not that big of a deal.
            % It would be a much bigger deal for NASA S3.

            data_filename = [granules_directory dir_year filename_start md_date md_time filename_end_night];

            if ~exist(data_filename)

                % If the file does not exist search all seconds for this metadata minute.

                granule_guess_time = datenum([str2num(md_date(1:4)) str2num(md_date(5:6)) str2num(md_date(7:8)) str2num(md_time(1:2)) str2num(md_time(3:4)) str2num(md_time(5:6))]);

                yymmddhhmm = datestr(granule_guess_time, formatOut.yyyymmddhhmm);

                for iSec=0:59
                    iSecC = num2str(iSec);
                    if iSec < 10
                        iSecC = ['0' iSecC];
                    elseif iSec == 0
                        iSecC = '00';
                    end

                    data_filename = [granules_directory dir_year filename_start yymmddhhmm iSecC filename_end_day];

                    if ~exist(data_filename) & amazon_s3_run  % No need to search for a URI nighttime version of the file. 
                        data_filename = [granules_directory dir_year filename_start yymmddhhmm iSecC filename_end_night];
                    end

                    if exist(data_filename)
                        found_one = 1;
                        break
                    end
                end
            else
                found_one = 1;
            end
        end

        nn = strfind(data_filename, '/');

        folder_name = data_filename(1:nn(end));
        file_name = data_filename(nn(end)+1:end);

    otherwise
        fprintf('Should never get here.\n')
end

end