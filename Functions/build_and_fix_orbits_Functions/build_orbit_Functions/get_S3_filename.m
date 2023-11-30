function [found_one, data_filename, test_time] = get_S3_filename( file_type, arg_2)
% get_S3_filename - get the name of the NASA data file from the AWS S3 NASA bucket - PCC
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
%   found_one - 1 if a data file was found corresponding to the metadata
%    file and 0 if none was found within one minute.
%   data_filename - the name of the data file found.
%   granule_start_time_guess - the start time, which was altered in the
%    call for 'metadata'.
%

% globals for the run as a whole.

global granules_directory metadata_directory

% globals for build_orbit part.

global formatOut
global s3_expiration_time

test_time = nan;

found_one = 0;

switch file_type

    case 'metadata'
        metadata_granule = [];

        test_time = arg_2 - 5 / 86400;

        for iSecond=1:65
            test_time = test_time + 1 / 86400;

            data_filename = [metadata_directory datestr(test_time, formatOut.yyyy) '/AQUA_MODIS_' datestr(test_time, formatOut.yyyymmddThhmmss) '_L2_SST_OBPG_extras.nc4'];

            if exist(data_filename)
                found_one = 1;
                break
            end
        end

    case 'sst_data'

        % Do we need new credentials for the s3 file?

        if (now - s3_expiration_time) > 55 / (60 * 24)
            s3Credentials = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', 'eiMTJr6yeuD6');
        end

        % Get the time of the metadata file.
        % modis metadata file: AQUA_MODIS_20100502T170507_L2_SST_OBPG_extras.nc4

        metadata_name = arg_2;

        md_date = metadata_name(12:19);
        md_time = metadata_name(21:26);

        % s3 data granule: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100419015508-JPL-L2P_GHRSST-SSTskin-MODIS_A-N-v02.0-fv01.0.nc

        % Is there an s3 data file at the same time as this metadata file?

        data_filename = [granules_directory md_date md_time '-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc'];

        % If the file does not exist check for a nighttime version of it.

        if ~exist(data_filename)
            data_filename = [granules_directory md_date md_time '-JPL-L2P_GHRSST-SSTskin-MODIS_A-N-v02.0-fv01.0.nc'];
        end

        % If the file does not exist search all seconds for this metadata minute.

        if ~exist(data_filename)

            data_filename = [granules_directory md_date md_time '-JPL-L2P_GHRSST-SSTskin-MODIS_A-N-v02.0-fv01.0.nc'];
            % % % found_one = 0;

            granule_guess_time = datenum([str2num(md_data(1:4)) str2num(md_data(5:6)) str2num(md_data(7:8)) str2num(md_time(1:2)) str2num(md_time(3:4)) str2num(md_time(5:6))]);

            yymmddhhmm = datestr(granule_guess_time, formatOut.yyyymmddhhmm);

            for iSec=0:59
                iSecC = num2str(iSec);
                if iSec < 10
                    iSecC = ['0' iSecC];
                elseif iSec == 0
                    iSecC = '00';
                end

                data_filename = [granules_directory yymmddhhmm iSecC '-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc'];

                if ~exist(data_filename)
                    data_filename = [granules_directory yymmddhhmm iSecC '-JPL-L2P_GHRSST-SSTskin-MODIS_A-N-v02.0-fv01.0.nc'];
                end

                if exist(data_filename)
                    found_one = 1;
                    break
                end
            end
        else
            found_one = 1;
        end

    otherwise
        fprintf('Should never get here.\n')
end

end