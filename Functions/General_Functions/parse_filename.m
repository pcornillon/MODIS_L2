function matTime = parse_filename( filename)
% parse_filename - returns Matlab time given a NASA MODIS filename - PCC
%
% INPUT
%   filename - a NASA filename of the form AQUA_MODIS.20240101T000001.L2.SST.nc
%
% OUTPUT
%   matTime - days since 1/1/1 extracted from the filename
%

nn = strfind(filename, 'MODIS_') + 6;
mm = nn + 3;

Year = str2num(filename(nn:mm));
nn = mm + 1;
mm = nn + 1;

Month = str2num(filename(nn:mm));
nn = mm + 1;
mm = nn + 1;

Day = str2num(filename(nn:mm));
nn = mm + 2;
mm = nn + 1;

Hour = str2num(filename(nn:mm));
nn = mm + 1;
mm = nn + 1;

Minute = str2num(filename(nn:mm));
nn = mm + 1;
mm = nn + 1;

Second = str2num(filename(nn:mm));

matTime = datenum([Year, Month, Day, Hour, Minute, Second]);
