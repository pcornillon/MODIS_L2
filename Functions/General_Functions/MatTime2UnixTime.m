function unix_time = MatTime2UnixTime(mat_time)
% MatTime2UnixTime - converts from days since 0/1/1 to seconds since 1970,1,1 - PCC
%
% Well, realy not unix time since that would be in msec from 1970,1,1 but...

unix_time = (mat_time - datenum(1970,1,1)) * 86400;

end