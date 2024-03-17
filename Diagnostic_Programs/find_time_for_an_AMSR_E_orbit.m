% find_time_for_an_AMSR_E_orbit
%
% The idea of this program is to see if there are any gliches in the NASA
% or RSS numbering of orbits.

% The first orbit is #416 at Matlab time 731368.80 ==> 01-Jun-2002 19:05:19. 
% Get this info from the first orbit.

filelist = dir('/Volumes/Aqua-1/AMSR-E_L2-v7/2002/2002*');
fiamsre_416 = [filelist(1).folder '/' filelist(1).name];
ref_time_416 = ncread( fiamsre_416, 'time');
MLtime_amrse_416 = datenum([1981,1,1]) + double(ref_time_416)/86400;

% Loop over years

iNext = 0;
for iYear=2003:2012
    iNext = iNext + 1;

    year_string = num2str(iYear);
    
    % Get the list of files for this year and then the first on.

    eval(['filelist = dir(''/Volumes/Aqua-1/AMSR-E_L2-v7/' year_string '/' year_string '*'');'])
    
    fiamsre = [filelist(1).folder '/' filelist(1).name];

    % Now get the orbit number

    nn = strfind( filelist(1).name, '_v07_r');

    Orbit(iNext) = str2num(filelist(1).name(nn+6:nn+10));

    % Next get the Matlab time for the start of this orbit.

    ref_time = ncread( fiamsre, 'time');
    
    ML_time_amrse = datenum([1981,1,1]) + double(ref_time)/86400;

    % And the time since the start of orbit 416.
    
    d_time = ML_time_amrse - MLtime_amrse_416;

    d_time_per_orbit(iNext) = d_time / (Orbit(iNext) - 416) * 24 * 60;

    fprintf('For %i, orbit #%i the time per orbit would be %f minutes.\n', iYear, Orbit(iNext), d_time_per_orbit(iNext))
end