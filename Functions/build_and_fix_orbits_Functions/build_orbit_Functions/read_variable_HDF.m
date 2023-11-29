function [VarOut] = read_variable_HDF(file_id, VarName, nPixels, gsscan, scan_lines_to_read)
% read_variable_HDF - reads a variable from a netCDF file using HDF.
%
% This function will get the missing value for the variable to be read as
% well as the scale and offset. It then reads the data, sets matrix
% elements with missing values to nan and scales the variable.
%
% INPUT
%   file_id - the hdf ID for the file in which the variable is found.
%   VarName - a string--make sure to enclose in quotes 'SST_In'-- for the
%    variable to be read.
%   nPixels - will return elements in the first dimesion from 1 to nPixels.
%   gsscan - will extract scan lines starting here.
%   scan_lines_to_read - and going to gsscan+scan_lines_to_read-1.
%
% OUTPUT
%   VarOut - the scaled input value with nans at missing value locations.
%

% Get the id for the variable.

data_id = H5D.open( file_id, VarName);
if data_id
    VarOut = nan;
    return
end

% Read the variable.

data_temp = H5D.read( data_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');

% Get the missing value and apply.
 
data_temp(data_temp==MissingValues) = nan;

% Get the scale factor and offset and apply.

VarOut = single(data_temp(1:nPixels,gsscan:gsscan+scan_lines_to_read-1)) * ScaleFactor + Offset;

end