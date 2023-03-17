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

file_list = dir('/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/01/AQUA_MODIS*');

% Get the time of the start of each scan line relative to the first scan 
% line and the nadir latitude value of each scan line.

for i=1:length(file_list)
    filename = [file_list(i).folder '/' file_list(i).name];
    sltimes(i,:) = ncread(filename, 'time_from_start_orbit');
    nlat(i,:) = ncread(filename, 'nadir_latitude');
end

% Average start times by scan line and latitudes and save the average.

sltimes_avg = mean(sltimes,1,'omitnan');
nlat_avg = mean(nlat,1,'omitnan');
save('~/Dropbox/ComputerPrograms/MATLAB/Projects/MODIS_L2/Data/avg_scan_line_start_times', 'sltimes_avg', 'nlat_avg')
save('~/Dropbox/ComputerPrograms/MATLAB/Projects/MODIS_L2/Data/scan_and_nadir', 'sltimes', 'nlat')

% Get the anomalies from the average orbit.

sltimes_anom = sltimes - sltimes_avg;
nlat_anom = nlat - nlat_avg;

% Print results

fprintf('Scan line start time anomalies from the average are between %f and %f\n', min(sltimes_anom(:)), max(sltimes_anom(:)))
fprintf('Latitude anomalies from the average are between %f and %f\n', min(nlat_anom(:)), max(nlat_anom(:)))