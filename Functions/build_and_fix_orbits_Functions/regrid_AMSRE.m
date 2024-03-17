function [outputArg1,outputArg2] = regrid_AMSRE( fi, AMSR_E_baseDir, MODIS_lon, MODIS_lat, MODIS_sst)
% regrid_AMSRE and MODIS to L3 and L2 coordinates corresponding to AMSR-E - PCC
%
% This function will first determine which AMSR-E orbit corresponds to the
% current MODIS orbit and read the AMSR-E lat, lon and SST. It will then
% average MODIS to a 10x10 km grid and regrid the MODIS data to the AMSR-E
% data between 65 S and 65N after which it will determine the longitudinal
% range of the two portions of the AMSR-E orbit between 65 S and 65 N and
% regrid both AMSR-E and MODIS to this grid.
%
% INPUT
%   fi - the filename of the MODIS orbit. If empty then use the needed information in oinfo.
%   AMSR_E_baseDir - location of the AMSR-E data.
%
%   MODIS_lon - regridded of MODIS.
%   MODIS_lat - regridded of MODIS.
%   MODIS_sst - regridded of MODIS.
%
% OUTPUT
%   L3_lon - new L3 longitude grid
%   L3_lat - new L3 latitude grid
%
%   AMSRE_L3_sst - AMSR-E SST regridded to the L3 grid
%
%   AMSRE_L2_lon - original AMSR-E longitude
%   AMSRE_L2_lat - original AMSR-E latitude
%   AMSRE_L2_sst - original AMSR-E SST
%
%
%   MODIS_L2_sst - MODIS SST regridded to the AMSR-E L2 grid
%   MODIS_L3_sst - MODIS SST regridded to the L3 grid

% Get the AMSR-E data. Start by determining the correct AMSR-E orbit. 

% The first AMSR-E orbit with data, orbit #416, starts at 01-Jun-2002
% 19:05:19 or Matlab time 731368.7953587963. The average time for one orbit
% is: 98.863071 minutes. Given the NASA orbit number of this MODIS orbit--
% oinfo.ginfo(end).NASA_orbit_number--we can guess at the name of the
% corresponding AMSR-E orbit and we can check that the start times of the
% AMSR-E and MODIS orbits are similar.

if ~isempty(fi)
    temp_time = ncread( fi, 'DateTime');
    matlab_time_MODIS_start = datenum([1970,1,1]) + double(temp_time)/86400;

    kk = strfind( fi, '_orbit_');
    NASA_orbit_t = str2num(fi(kk+7:kk+12));

    [MODIS_yr, MODIS_mn, MODIS_day, MODIS_hr, MODIS_min, MODIS_sec] = datevec(matlab_time_MODIS_start);
else
    NASA_orbit_t = oinfo(end).orbit_number;
    
    [MODIS_yr, MODIS_mn, MODIS_day, MODIS_hr, MODIS_min, MODIS_sec] = datevec(oinfo(end).start_time);
end

% Build the AMSR-E orbit filename.

NASA_orbit = return_a_string( 5, NASA_orbit_t);

year_s = return_a_string( 4, MODIS_yr);
month_s = return_a_string( 2, MODIS_mn);
day_s = return_a_string( 2, MODIS_day);

fiamsre = [AMSR_E_baseDir year_s '/' year_s month_s day_s '-amsre-remss-l2p-l2b_v07_r' NASA_orbit '.dat-v01.nc'];

%       metadata_name
%       data_name
%       NASA_orbit_number

datestr(datenum([1981,1,1]) + double(ref_time)/86400)


end