% determine_orbit_timing - how many seconds/orbit
%
% This script will open the first orbit in the time series, on 4 July 2002
% and then the first one every year. It will get the start time of the
% orbit in matlab time and the list of granules contributing to the orbit.
% It will open the OBPG metadata for that file and get the NASA orbit
% number. From this information it will generate a table of seconds/orbit
% for the given year.
%
% Here's an alternate description:
% 

granule_dir = '/Volumes/MODIS_L2_Modified/AQUA/SST_Orbits/';
metadata_dir = '/Volumes/MODIS_L2_Modified/AQUA/Data_from_OBPG_for_PO-DAAC/';

iOrbit = 0;
for year=2002:2023
    yearS = num2str(year);

    for month=1:12
        monthS = return_a_string( 2, month);

        % Get the first orbit in this month

        orbit_list = dir( [granule_dir yearS '/' monthS '/*.nc4']);

        if isempty(orbit_list)
            fprintf('No data for %s/%s, going to the next month.\n', yearS, monthS)
        else
            iOrbit = iOrbit + 1;

            jOrbit = 0;
            while 1==1
                jOrbit = jOrbit + 1;

                if jOrbit > length(orbit_list)
                    break
                else
                    % Get the filename for this orbit.
                    orbit_filename = [orbit_list(jOrbit).folder '/' orbit_list(jOrbit).name];

                    % Get the start time of this orbit.

                    DateTime(iOrbit) = ncread( orbit_filename, 'DateTime');
                    matTime(iOrbit) = datenum(1970,1,1,0,0,0) + DateTime(iOrbit) / 86400;

                    % Get the list of filenames

                    filenames = ncread( orbit_filename, '/contributing_granules/filenames');
                    datetime_string = filenames(1,1:14);

                    % Build the OBPG metadata filename from the first file on the list.

                    OBPG_filename(iOrbit) = string([metadata_dir yearS '/AQUA_MODIS_' datetime_string(1:8) 'T' datetime_string(9:14) '_L2_SST_OBPG_extras.nc4']);

                    yearStart = ncread( OBPG_filename(iOrbit), '/scan_line_attributes/year');
                    dayStart = ncread( OBPG_filename(iOrbit), '/scan_line_attributes/day');
                    msecStart = ncread( OBPG_filename(iOrbit), '/scan_line_attributes/msec');

                    granule_start_time = datenum( yearStart(1), 0, dayStart(1)) +  msecStart(1)/(1000*86400);

                    tempS = ncreadatt( OBPG_filename(iOrbit), '/', 'orbit_number');
                    NASA_orbit(iOrbit) = str2num(string(tempS));

                    if (granule_start_time <= matTime(iOrbit)) & ( (granule_start_time + 5/(60*24)) > matTime(iOrbit))
                        break
                    end
                end
            end
        end
    end
end

% Now get the time/orbit in fractions of a second as a function of date.

dTimes = diff(matTime);
dOrbits = diff(NASA_orbit);

time_per_orbit = (dTimes ./ dOrbits) * 86400;

% Get the mean and standard deviation of orbit periods

periodSigma = std(time_per_orbit);
periodMean = mean(time_per_orbit);

fprintf('Period mean and sigma: %7.3f +/- %4.4f\n', periodMean, periodSigma)

% Repeat excluding periods more than 2 sigma from the mean.

nnWithin2Sigma = find( abs(time_per_orbit - periodMean) <= 2 * periodSigma); 

periodSigmaExcludingOutliers = std(time_per_orbit(nnWithin2Sigma));
periodmeanExcludingOutliers = mean(time_per_orbit(nnWithin2Sigma));

fprintf('Period mean and sigma excluding periods more than 2 sigma from the mean: %7.3f +/- %4.4f\n', periodmeanExcludingOutliers, periodSigmaExcludingOutliers)

% Show the outliers:

fprintf('\n And now for those that are more than 2 sigma from the mean.\n\n')
nnBeyond2Sigma = find( abs(time_per_orbit - periodMean) > 2 * periodSigma); 
for i=nnBeyond2Sigma
    fprintf('NASA orbit number: %i, %s. Deviation from mean of %7.3f in msec: %5.1f\n', NASA_orbit(i), datestr( matTime(i)), periodmeanExcludingOutliers, (time_per_orbit(i) - periodmeanExcludingOutliers) * 1000)
end

% Plot the results

figure
clf
plot(NASA_orbit(2:end),(time_per_orbit - periodmeanExcludingOutliers))
hold on
plot(NASA_orbit(2:end),(time_per_orbit - periodmeanExcludingOutliers), 'r.')

set(gca, fontsize=18)
xlabel('NASA Orbit Number')
ylabel('Mean Period Since Previous Orbit (s)')
title('Orbital Period vs Orbit #', fontsize=30)
