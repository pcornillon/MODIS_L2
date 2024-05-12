function [status, found_one, folder_name, file_name, test_time] = get_filename( file_type, arg_2)
% get_filename - get the name of the NASA data file from the AWS S3 NASA bucket - PCC
%
% This function will get the approximate time of the granule to search for
% from the metadata name and then test a filename second-by-second in the
% S3 bucket.
%
% INPUT
%   file_type - 'sst_data' for NASA granule data or 'metadata' for OBPG
%    metadata file in S3 bucket.
%   arg_2 = time to start looking for a metadata granule, will be set to
%    test_time if 'metadata.
%    OR
%    The metadata filename corresponding to the data file we are searching
%    for if file_type is 'S3', otherwise can be blank or have a value,
%    which will be ignored. Will be set to metadata_name if 'data'.
%
% OUTPUT
%   status - 921 if timed out on credentials request, 0 otherwise.
%   found_one - 1 if a data file was found corresponding to the metadata
%    file and 0 if none was found within one minute.
%   folder_name - the folder in which the file was found.
%   file_name - the name of the data file found.
%   test_time - the start time, which was altered in the call for 'metadata'.
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

global version_struct
version_struct.get_filename = '1.0.2';

% globals for the run as a whole.

global granules_directory metadata_directory

% globals for build_orbit part.

global formatOut
global s3_expiration_time amazon_s3_run
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length secs_per_granule_minus_10 

status = 0;
found_one = 0;

folder_name = '';
file_name = '';

test_time = nan;

switch file_type

    case 'metadata'
        metadata_granule = [];

        test_time = arg_2 - 5 / secs_per_day;

        for iSecond=1:65
            test_time = test_time + 1 / secs_per_day;

            data_filename = [metadata_directory datestr(test_time, formatOut.yyyy) '/AQUA_MODIS_' datestr(test_time, formatOut.yyyymmddThhmmss) '_L2_SST_OBPG_extras.nc4'];

            if exist(data_filename)
                found_one = 1;

                folder_name = [metadata_directory datestr(test_time, formatOut.yyyy) '/'];
                file_name = ['AQUA_MODIS_' datestr(test_time, formatOut.yyyymmddThhmmss) '_L2_SST_OBPG_extras.nc4'];

                break
            end
        end

        % Reset test_time to the time passed in. If it is not reset, it
        % will creep up by about a minute on each call potentially putting
        % it out of range for if a number of granules are missing.

        test_time = arg_2;
        
    case 'sst_data'

        metadata_name = arg_2;

        % Get the time of the metadata file. Start by finding where in the
        % string the data and time info is. 

        md_date = metadata_name(12:19);
        md_time = metadata_name(21:26);

        % Will first get components of the filename, which differ from data
        % at URI, as copied from OBPG, and at AWS.

        if amazon_s3_run

            % make sure that access credentials for NASA S3 files are still
            % active. Note that the s3 access is further down (lines 133,
            % 147, 165 and 169 in this function where an exist is done on
            % the filename. 
            
            if (now - s3_expiration_time) > 30 / (60 * 24)
                [status, s3Credentials] = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', 'eiMTJr6yeuD6');
                
                if status == 921
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