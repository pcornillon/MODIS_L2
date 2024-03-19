% get_avg_scan_line_start_times - reads a number of complete orbits and averages scan line times - PCC
%
% This script reads the times for the start of each orbit from the start of
% the orbit for all the full orbits in January 2010. It averages these
% start times at each scan line location and saves the average of scan line
% start times. It then removes the average from each of the vectors read in
% and prints the min and max of the resulting anomaly for all scan lines.
% Here's the average obtained.
%
%  Scan line start time anomalies from the average are between -0.002461 and 0.003525
%

% file_list = dir('/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/01/AQUA_MODIS*');
file_list = dir('/Volumes/MODIS_L2_modified/OBPG/SST/2011/01/AQUA_MODIS*.nc4');
jFile = length(file_list);

file_list_2 = dir('/Volumes/MODIS_L2_modified/OBPG/SST/2011/02/AQUA_MODIS*.nc4');

for iFile=1:length(file_list_2)
    jFile = jFile + 1;
    file_list(jFile) = file_list_2(iFile);
end

file_list_3 = dir('/Volumes/MODIS_L2_modified/OBPG/SST/2011/02/AQUA_MODIS*.nc4');

for iFile=1:length(file_list_3)
    jFile = jFile + 1;
    file_list(jFile) = file_list_3(iFile);
end

% Get the time of the start of each scan line relative to the first scan 
% line and the nadir latitude value of each scan line.

for iFile=1:length(file_list)
    filename = [file_list(iFile).folder '/' file_list(iFile).name];
    sltimes(iFile,:) = ncread(filename, 'time_from_start_orbit');
    nlat(iFile,:) = ncread(filename, 'nadir_latitude');
    nlon(iFile,:) = ncread(filename, 'nadir_longitude');
end

% Average start times by scan line and latitudes and save the average.

sltimes_avg_temp = mean(sltimes,1,'omitnan');
nlat_avg = mean(nlat,1,'omitnan');
nlon_typical = nlon(end,:);

% reformulate sltimes_avg to address it's purpose: 
%  sltimes_avg is used in generate_output_filename.m (the only place it is
%  used) to determine the starting time of an orbit where there was a
%  missing granule for when it should have started. Since the mirror scan
%  includes 10 detectors, the actual time of the scan repeats in groups of
%  10. To get the best estimate of the start time, use the scan in the
%  middle of the group. For this reason, sltimes_avg should start with 6
%  zeros, then 10 repeats of the next time for the mirror rotation,… This
%  part of the code addresses this. Specifically, it generates
%    0 0 0 0 0 0 1.4771 repeated 10 times, 2.9542 repeated 10 times,… 
%  The actual values, 1.4771, 2.9542 are determined in from the above

sltimes_avg = [0 0 0 0 0 0];
iLine = 6;
for iMirror=11:10:length(sltimes_avg_temp)
    for iTemp=1:10
        iLine = iLine + 1;
        if iLine > length(sltimes_avg_temp)
            break
        end
        sltimes_avg(iLine) = sltimes_avg_temp(iMirror);
    end
end

save('/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/metadata/avg_scan_line_start_times', 'sltimes_avg', 'nlat_avg', 'nlon_typical')
save('/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/metadata/scan_and_nadir', 'sltimes', 'nlat', 'nlon')

% Get the anomalies from the average orbit.

sltimes_anom = sltimes - sltimes_avg;
nlat_anom = nlat - nlat_avg;

% Print results

fprintf('Scan line start time anomalies from the average are between %f and %f\n', min(sltimes_anom(:)), max(sltimes_anom(:)))
fprintf('Latitude anomalies from the average are between %f and %f\n', min(nlat_anom(:)), max(nlat_anom(:)))