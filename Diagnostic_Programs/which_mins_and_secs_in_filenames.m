% which_mins_and_secs_in_filenames - to test seconds and minutes of data files.
%
% The objective of this script is to determine the minutes and seconds,
% which occur in MODIS Aqua L2 SST granule names. I want to make sure that
% only 0 and 5 occur for the minutes and get a sense for what seconds
% occur. The reason for this is to sort out how to handle searches for s3
% granules when I build and fix all files.
%
% This script will loop over all years with MODIS Aqua L2 SST data. For
% each year, it will get a list of all the granules for that year. It will
% then get the minutes and seconds of each file, convert these to integers,
% add 1 and then increment an array for minutes and one for seconds by 1.
%
for iYr=2002:2021
    Yr = num2str(iYr);
    fprintf('Working on %s\n', Yr)

    filelist = dir(['/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/' Yr '/AQUA_MODIS_*']);

    mincounts = zeros(60,1);
    seccounts = zeros(60,1);

    for iFile=1:length(filelist)

        % AQUA_MODIS_20100302T185507_L2_SST_OBPG_extras.nc4

        % Get minutes and seconds.

        iMin = str2num(filelist(iFile).name(23:24)) + 1;
        iSec = str2num(filelist(iFile).name(25:26)) + 1;

        mincounts(iMin) = mincounts(iMin) + 1;
        seccounts(iSec) = seccounts(iSec) + 1;
    end
end