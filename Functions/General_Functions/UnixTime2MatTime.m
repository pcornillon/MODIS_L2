function mat_time = UnixTime2MatTime(unix_time)
% UnixTime2MatTime - converts from seconds since 1970,1,1 to days since 0/1/1 - PCC
%
% Well, realy not unix time since that would be in msec from 1970,1,1 but...

mat_time = unix_time / 86400 + datenum(1970,1,1);

end