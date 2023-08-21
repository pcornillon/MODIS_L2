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
[cd, st, ns] = get_metadata(fi_jpl_today);

% Downloaded from OBPG a few years ago.

fi_obpg_past =  '/Volumes/Aqua-1/MODIS_R2019/combined/2019/AQUA_MODIS.' yr_day_time_OBPG '.L2.SST.NRT.nc';
[cd, st, ns] = get_metadata(fi_obpg_past);

% Metadata data file produced for the above.

fi_metadata = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/2019/AQUA_MODIS_' yr_day_time_OBPG '_L2_SST__NRT_OBPG_extras.nc4';
[cd, st, ns] = get_metadata(fi_metadata);

% Downloaded from OBPG pn 8/21/2023

fi_obpg_today = '/Users/petercornillon/Dropbox/temp/AQUA_MODIS.' yr_day_time_OBPG '.L2.SST.NRT.nc';
[cd, st, ns] = get_metadata(fi_obpg_today);

%% Functions

function [cd, st, ns] = get_metadata(fi)
cd = ncreadatt(fi, '/', 'date_created');
st = ncreadatt(fi, '/', 'time_coverage_start');

md = ncinfo(fi);

ns = [];
dims = md.Dimensions;
for i=1:length(dims)
    if strcmp(dims(i).Name, 'number_of_lines')
        ns = dims(i).Length;
    end
end

if isempty(ns)
    fprintf('Problem with %s, cannot find number_of_lines\n', fi)
end

fprintf('fi: %s: Created: %s: num_scans: %i Start time: %s\n', fi, cd, ns, st)

end
