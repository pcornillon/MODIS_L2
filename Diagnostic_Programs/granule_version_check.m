% granule_version_check - compare metadata for different version of the input granules - PCC
%
% This script loads the data downloaded from JPL and OBPG, both recently
% and in the past for the latter, as well as the metadata file and compares
% creation date for the file, number of scans in the file and the date/time
% of the first scan line in the file.

Year = 2019;
yr_day_time_OBPG = '20191115T135001';
yr_day_time_JPL = '20191115135001';

% Downloaded from JPL Amazon cloud 8/21/2023. There are two files for this
% day/time, one processed with the 11-12 um channels with -D- in the name
% and one with 4, 11-12 um channels with -N- in the name. We are interested
% in the former.

filelistn = dir(['~/Downloads/' yr_day_time_JPL '-JPL-L2P_*']);

fi_jpl_today = [filelistn(1).folder '/' filelistn(1).name];
[cd, st, ns] = get_metadata('PO       in 2023: ', fi_jpl_today);
sst_jpl_2023 = ncread( fi_jpl_today, 'sea_surface_temperature');

% Downloaded from OBPG pn 8/21/2023

fi_obpg_today = ['/Users/petercornillon/Dropbox/temp/AQUA_MODIS.' yr_day_time_OBPG '.L2.SST.NRT.nc'];
[cd, st, ns] = get_metadata('OBPG NRT in 2023: ', fi_obpg_today);
sst_obpg_2023_nrt = ncread( fi_obpg_today, '/geophysical_data/sst');

% Downloaded from OBPG a few years ago.

fi_obpg_past =  ['/Volumes/Aqua-1/MODIS_R2019/combined/2019/AQUA_MODIS.' yr_day_time_OBPG '.L2.SST.nc'];
[cd, st, ns] = get_metadata('OBPG     in 2019: ', fi_obpg_past);
sst_obpg_2019 = ncread( fi_obpg_past, '/geophysical_data/sst');

% Downloaded from OBPG a few years ago (NRT).

fi_obpg_past_nrt =  ['/Volumes/Aqua-1/MODIS_R2019/combined/2019/AQUA_MODIS.' yr_day_time_OBPG '.L2.SST.NRT.nc'];
[cd, st, ns] = get_metadata('OBPG NRT in 2019: ', fi_obpg_past_nrt);
sst_obpg_2019_nrt = ncread( fi_obpg_past_nrt, '/geophysical_data/sst');

% Metadata data file produced for the above.

fi_metadata = ['/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/2019/AQUA_MODIS_' yr_day_time_OBPG '_L2_SST_NRT_OBPG_extras.nc4'];
[cd, st, ns] = get_metadata('Metadata file: ', fi_obpg_past);


fprintf('\nNow differences in SST at locations where they differ.\n')
fprintf('      JPL 2023:  sst_jpl_2023(1346, 97)-273.15 = %f\n', sst_jpl_2023(1346, 97)-273.15)
fprintf(' NRT OBPG 2023:    sst_obpg_2023_nrt(1346, 97) = %f\n', sst_obpg_2023_nrt(1346, 97))
fprintf('     OBPG 2019:        sst_obpg_2019(1346, 97) = %f\n', sst_obpg_2019(1346, 97))
fprintf(' NRT OBPG 2019:    sst_obpg_2019_nrt(1346, 97) = %f\n', sst_obpg_2019_nrt(1346, 97))

%% Functions

function [cd, st, ns] = get_metadata( TITLE, fi)
cd = ncreadatt(fi, '/', 'date_created');
st = ncreadatt(fi, '/', 'time_coverage_start');

md = ncinfo(fi);

ns = [];
dims = md.Dimensions;
for i=1:length(dims)
    if strcmp(dims(i).Name, 'number_of_lines') | strcmp(dims(i).Name, 'nj')
        ns = dims(i).Length;
    end
end

if isempty(ns)
    fprintf('Problem with %s, cannot find number_of_lines\n', fi)
end

fprintf('%s num_scans: %i Start time: %s Created: %s: fi: %s: \n', TITLE, ns, st, cd, fi)

end
