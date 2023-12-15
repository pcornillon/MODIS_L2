% scan_line_timing_info - get information from formed orbit about scan line timing - PCC
%
% This script reads information from built orbits to determine scan line
% timing. Specifically, does the speed of the satellite change as it moves
% through its orbit.
%

% Get a list of built orbits to use.

filelist = dir('/Volumes/MODIS_L2_Modified/OBPG/SST/2003/01/AQUA_MODIS_orbit_*.nc4');

% Loop over the list reading pertinent information.

granule_duration = nan(length(filelist),21);

for iFilename=1:length(filelist)

    % Build the filename from which to extract information.
    
    filename = [filelist(iFilename).folder '/' filelist(iFilename).name];

    % When did the orbit start? Times here and below are seconds since 1/1/1970 0:0:0 

    orbit_info(iFilename).orbit_start_time = ncread(filename, 'DateTime');
    
    % Information about each granule in the orbit.

    granule_info(iFilename).filenames = ncread(filename, '/contributing_granules/filenames');
    
    granule_info(iFilename).start_time = ncread(filename, '/contributing_granules/start_time');
    granule_info(iFilename).end_time = ncread(filename, '/contributing_granules/end_time');
    
    granule_info(iFilename).orbit_start_index = ncread(filename, '/contributing_granules/orbit_start_index');
    granule_info(iFilename).orbit_end_index = ncread(filename, '/contributing_granules/orbit_end_index');
    
    granule_info(iFilename).granule_start_index = ncread(filename, '/contributing_granules/granule_start_index');
    granule_info(iFilename).granule_end_index = ncread(filename, '/contributing_granules/granule_end_index');
    
    % Information about the nadir track of each orbit.

    nadir_info(iFilename).nadir_latitude = ncread(filename, 'nadir_latitude');
    nadir_info(iFilename).time_from_start_orbit = ncread(filename, 'time_from_start_orbit');
    
    % Information derived from the above.

    orbit_info(iFilename).orbit_end_time = orbit_info(iFilename).orbit_start_time + nadir_info(iFilename).time_from_start_orbit(end);

    % if (iFilename ~= 37) & (iFilename ~= 38) & (iFilename ~= 39) & (iFilename ~= 1

    tempstart = granule_info(iFilename).start_time;

    granule_duration(iFilename,1:length(tempstart)-1) = diff(tempstart);

    % Now get the time for one scan line.

    for iGranule=1:length(tempstart)-1
        if granule_info(iFilename).granule_end_index(iGranule) == 2030
            scan_line_time(iFilename, iGranule) = granule_duration(iFilename,iGranule) / 2030;
        elseif granule_info(iFilename).granule_end_index(iGranule) == 2040
            scan_line_time(iFilename, iGranule) = granule_duration(iFilename,iGranule) / 2040;
        else
            scan_line_time(iFilename, iGranule) = nan;
        end
    end

end

% Now calculate the mean secs_per_scan_line for for all values of
% scan_line_time >0.14. Values smaller than this are generally associated
% with orbits for which there was an issue the granules--fairly few.

nn = find(scan_line_time > 0.14);
secs_per_scan_line = mean(scan_line_time(nn),'omitnan');

fprintf('The mean time separating scan lines determined from %i granules is %f10\n', length(nn), secs_per_scan_line)

% Next make sure that the start time of the orbit corresponds to the time
% of the first pixel to use in the first granule.

for iFilename=1:length(filelist)
    orbit_start_time_differences(iFilename) = orbit_info(iFilename).orbit_start_time - ...
        (granule_info(iFilename).start_time(1) + (granule_info(iFilename).granule_start_index(1) - 1) * secs_per_scan_line);
end

fprintf('For (oinfo(iOrbit).start_time - oinfo(iOrbit).ginfo(1).start_time) * 100 / secs_per_scan_line we have: [min, mean, max] [%f, %f, %f]%%\n', ...
    min(orbit_start_time_differences)*100/secs_per_scan_line,  mean(orbit_start_time_differences)*100/secs_per_scan_line,  ...
    max(orbit_start_time_differences)*100/secs_per_scan_line)

if abs(mean(orbit_start_time_differences)*100/secs_per_scan_line) < 20
    fprintf('This is a small difference <20%% of the time separating scan lines. Everything looks good.\n')
else
    fprintf('Look into this, the difference is > 20%% of the time separating scan lines.\n')
end

% Now test to see if it can find the correct starting time for the ith
% granule in a given orbit.

iGranule = 5;

% Estimate the number of scans from the end of the previous orbit to the start of this granule.

load /Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/avg_scan_line_start_times.mat
clear sltimes_avg nlon_typical

for iFilename=2:length(filelist)
    guess_scan_num_from_time(iFilename) = floor((granule_info(iFilename).end_time(iGranule) - ...
        orbit_info(iFilename-1).orbit_end_time) / secs_per_scan_line);

    nadir_info(iFilename).time_from_start_orbit - (granule_info(iFilename).start_time(iGranule) - granule_info(iFilename).start_time(1));
    nn = find( abs(nlat_avg - )
    guess_scan_num_from_canonical_orbit(iFilename) = floor((granule_info(iFilename).end_time(iGranule) - ...

end

