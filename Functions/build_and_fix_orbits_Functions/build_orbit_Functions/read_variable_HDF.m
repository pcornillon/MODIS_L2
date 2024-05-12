function [status, VarOut] = read_variable_HDF( FileID, FileName, VarName, nPixels, gsscan, scan_lines_to_read)
% read_variable_HDF - reads a variable from a netCDF file using HDF.
%
% This function will get the missing value for the variable to be read as
% well as the scale and offset. It then reads the data, sets matrix
% elements with missing values to nan and scales the variable.
%
% INPUT
%   FileID - the hdf ID for the file in which the variable is found.
%   FileName - used to get the information about the variables.
%   VarName - a string--make sure to enclose in quotes 'SST_In'-- for the
%    variable to be read.
%   nPixels - will return elements in the first dimesion from 1 to nPixels.
%   gsscan - will extract scan lines starting here.
%   scan_lines_to_read - and going to gsscan+scan_lines_to_read-1.
%
% OUTPUT
%   status - 921 if failed to get credentials, 0 otherwise.
%   VarOut - the scaled input value with nans at missing value locations.
%
%  CHANGE LOG 
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/9/2024 - Initial version - PCC
%   1.0.1 - 5/9/2024 - Added versioning. Added line to update the time at
%           which the credentials were set - PCC
%   1.0.2 - 5/12/2024 - Test to see if failure to get NASA se credentials
%           end the run if this is the case with status=921. Also added
%           status to the returned variables.

global version_struct
version_struct.read_variable_HDF = '1.0.2';

global iProblem problem_list 

global s3_expiration_time

status = 0;

% Make sure S3 credentials are up-to-date

if (now - s3_expiration_time) > 30 / (60 * 24)
    [status, s3Credentials] = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', 'eiMTJr6yeuD6');
    
    if status == 921
        return
    end
end

VarOut = [];

% Get the id for the variable.

data_id = H5D.open( FileID, VarName);

if data_id == -1
    fprintf('*** Couldn''t open file for %s\n', VarName)
    return
end

%Start by determining which dataset contains this variable.

info = h5info(FileName);

if isempty(info)
    fprintf('*** Couldn''t get info for %s\n', VarName)
    return
end

DatasetNumber = 0;
for i=1:length(info.Datasets)
    if strcmp(info.Datasets(i).Name, VarName) ~=0
        DatasetNumber = i;
        break
    end
end

if DatasetNumber == 0
    fprintf('*** Couldn''t get Dataset number for %s\n', VarName)
    return
else
    
    % Read the variable.
    
    data_temp = H5D.read( data_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    
    % Get the missing value and apply if there is one.
    
    FillValue = nan;
    for iAttribute=1:length(info.Datasets(DatasetNumber).Attributes)
        if strcmp(info.Datasets(DatasetNumber).Attributes(iAttribute).Name, '_FillValue') ~= 0
            FillValue = info.Datasets(DatasetNumber).Attributes(iAttribute).Value;
            break
        end
    end
    
    if isnan(FillValue) == 0
        data_temp(data_temp==FillValue) = nan;
    end
    
    % Get the scale factor and offset and applyl Note they are set to 1 and
    % 0 initially, so, if not present the input will not be scaled. 
    
    ScaleFactor = 1;
    for iAttribute=1:length(info.Datasets(DatasetNumber).Attributes)
        if strcmp(info.Datasets(DatasetNumber).Attributes(iAttribute).Name, 'scale_factor') ~= 0
            ScaleFactor = info.Datasets(DatasetNumber).Attributes(iAttribute).Value;
            break
        end
    end
    
    AddOffset = 0;
    for iAttribute=1:length(info.Datasets(DatasetNumber).Attributes)
        if strcmp(info.Datasets(DatasetNumber).Attributes(iAttribute).Name, 'add_offset') ~= 0
            AddOffset = info.Datasets(DatasetNumber).Attributes(iAttribute).Value;
            break
        end
    end
    
    VarOut = single(data_temp(1:nPixels,gsscan:gsscan+scan_lines_to_read-1)) * ScaleFactor + AddOffset;
end
