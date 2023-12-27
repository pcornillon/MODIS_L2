function [status, Matlab_time] = extract_datetime_from_filename(filename)
% extract_datetime_from_filename - determines orbit start time for pcc orbits - PCC  
%  
% Assuming an orbit name written by build_and_fix_orbits, of the form 
% AQUA_MODIS_orbit_003521_20030101T005135_L2_SST.nc4, this function will
% determine the Matlab start time. In this example, it would be 
%   datenum(2003,1,1,0,1,35) = 731582.00110 
%   datestr(731582.00110) = '01-Jan-2003 00:01:35'
%
% INPUT
%   filename - Do I really have to say what this is? Note that this can be
%    either the fully specified filename or just the name itself.
%
% OUTPUT
%   status - set to 161 if a problem, 0 otherwise.
%   Matlab_time - datenum value of the extracted date/time.
%
% EXAMPLE
%   [status, mat_start_time] = extract_datetime_from_filename('AQUA_MODIS_orbit_003521_20030101T005135_L2_SST.nc4')
%

status = 0;

if length(filename) < 29
    fprintf('\n\n******************** Something wrong with filename passed into extract_datetime_from_filename, %s, \n********************\n', filename)
    status = populate_problem_list( 161, ['Something wrong with filename passed into extract_datetime_from_filename,' filename '. SHOULD NEVER GET HERE.']);
    return
end

kk = strfind( filename, '_orbit_');

Year = str2num(filename(kk+14:kk+17));
Month = str2num(filename(kk+18:kk+19));
Day = str2num(filename(kk+20:kk+21));
Hour = str2num(filename(kk+23:kk+24));
Minute = str2num(filename(kk+25:kk+26));
Second = str2num(filename(kk+27:kk+28));

if  (Year < 2000) | (Year > 2030) | ...
    (Month < 1) | (Month > 12) | ...
    (Day < 1) | (Day > 31) | ...
    (Hour < 0) | (Hour > 24) | ...
    (Minute < 0) | (Minute > 60) | ...
    (Second < 0) | (Second > 60)

    fprintf('\n\n******************** Something wrong with filename passed into extract_datetime_from_filename, %s, \n********************\n', filename)
    status = populate_problem_list( 161, ['Something wrong with filename passed into extract_datetime_from_filename,' filename '. SHOULD NEVER GET HERE.']);
    return
end


Matlab_time = datenum( Year, Month, Day, Hour, Minute, Second);

end