% scan_line_timing_info - get information from formed orbit about scan line timing - PCC
%
% This script reads information from built orbits to determine scan line
% timing. Specifically, does the speed of the satellite change as it moves
% through its orbit.
%

global secs_per_day secs_per_scan_line orbit_length

orbit_length = 40271;
secs_per_day = 86400;

granules_directory    = '/Volumes/MODIS_L2_original/OBPG/combined/';

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

load /Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/metadata/avg_scan_line_start_times.mat
clear sltimes_avg nlon_typical

% % % % Find direction of satellite--increasing +1 versus decreasing -1
% % % % latitude--as a function of location in the canonical orbit.
% % % 
% % % for i=2:orbit_length
% % %     dd(i) = (nlat_avg(i) - nlat_avg(i-1)) / abs(nlat_avg(i) - nlat_avg(i-1));
% % % end
% % % ddd = diff(dd);
% % % nn = find(abs(ddd) > 0.1);
% % % direction_orbit = nn(2:end);
% % % 

num_scan_lines_in_half_orbit = floor(orbit_length / 2);

for iFilename=2:length(filelist)
    
    % Get the nadir latitudes for this granule; will have access to this
    % information in a regular run.
    
    [Year, Month, Day, Hour, Minute, Second] = datevec(granule_info(iFilename).start_time(iGranule)/secs_per_day + datenum(1970,1,1,0,0,0));
    temp_filename = [granules_directory num2str(Year) '/' granule_info(iFilename).filenames(iGranule,:)];
    nlat_t = single(ncread( temp_filename, '/scan_line_attributes/clat'));

    year_t = single(ncread( temp_filename, '/scan_line_attributes/year'));
    day_t = single(ncread( temp_filename, '/scan_line_attributes/day'));
    msec_t = single(ncread( temp_filename, '/scan_line_attributes/msec'));
    
    [month_t day_t] = doy2mmdd(year_t(1), day_t(1));

    mat_time = datenum( double(year_t), double(month_t), double(day_t), 0, 0, double(msec_t/1000)); % days since 0,1,1,0,0,0
    linux_time = (mat_time - datenum(1970,1,1)) * secs_per_day; % seconds since 1970,1,1,0,0,0

    % Now guess at number of scans from the start of this orbit to the
    % start of this granule. First, do so based on the start time of the granule.
    
    guess_scan_num_from_time(iFilename) = floor( (granule_info(iFilename).start_time(iGranule) - ...
        orbit_info(iFilename-1).orbit_end_time) / secs_per_scan_line);
    
    % Next do so based on the latitude of the first scan line in the granule.
    
    aa = find( abs(nlat_avg - nlat_t(1)) < 0.02);

    % If no crossing found return; should never get here.
    
    if isempty(aa)
        fprintf('iGranule = %i, iFilename = %i. Should never get here.\n', iGranule, iFilename)
    else
        % If more than 10 scan lines separate groups of scan lines found
        % near the start of iGranule, break them up and analyze separately
        % for direction. 
        
        diffaa = diff(aa);
        bb = find(diffaa >10);
 
        if isempty(bb)
            % Only one group
                
            nn = find( min(abs(nlat_avg - nlat_t(1))) == abs(nlat_avg - nlat_t(1)));

            guess_scan_num_from_canonical_orbit(iFilename) = nn(1);
         else
            % Two groups
            
            if (nlat_avg(aa(1)+1) > nlat_avg(aa(1))) & (nlat_t(2) > nlat_t(1))
               nn = find( min(abs(nlat_avg(1:num_scan_lines_in_half_orbit) - nlat_t(1))) == abs(nlat_avg(1:num_scan_lines_in_half_orbit) - nlat_t(1)));
               guess_scan_num_from_canonical_orbit(iFilename) = nn(1);
            else
               nn = find( min(abs(nlat_avg(num_scan_lines_in_half_orbit+1:end) - nlat_t(1))) == abs(nlat_avg(num_scan_lines_in_half_orbit+1:end) - nlat_t(1)));
               guess_scan_num_from_canonical_orbit(iFilename) = num_scan_lines_in_half_orbit + nn(1);
            end
        end
    end
    
    % Finally, remember that the number of scan lines from the first one in
    % this granule to the first one for this orbit must be a multiple of 5;
    % the first scan line in the orbit must occur as the 5th line in a
    % group of ten and there are multiple of 10 scan lines per orbit.
            
    guess_scan_num_from_time(iFilename) = floor( guess_scan_num_from_time(iFilename) / 10) * 10 + 6;
    guess_scan_num_from_canonical_orbit(iFilename) = floor( guess_scan_num_from_canonical_orbit(iFilename) / 10) * 10 + 6;

    % Now determine how close these are to the time of the first scan line in the orbit.
    % AQUA_MODIS.20030109T000006.L2.SST.nc'

    temp_filename = filelist(iFilename).name;
    nn = strfind( temp_filename, '_');

    dt_from_start_of_orbit = nadir_info(iFilename).time_from_start_orbit + orbit_info(iFilename).orbit_start_time - granule_info(iFilename).start_time(1);

    true_scan_num_from_time(iFilename) = find( min(abs(dt_from_start_of_orbit)) == abs(dt_from_start_of_orbit));
    true_scan_num_from_canonical_orbit(iFilename)  = find( min(abs(nadir_info(iFilename).nadir_latitude - nlat_t(1))) == abs(nadir_info(iFilename).nadir_latitude - nlat_t(1)));
    
    fprintf('%i) For %s, iGranule %i starts at orbit element %i\nThe location was guessed to be %i based on time and %i based on latitude.\n', ...
        iFilename, temp_filename(nn(4)+1:nn(5)-1), iGranule, true_scan_num_from_canonical_orbit, guess_scan_num_from_time(iFilename), ...
        guess_scan_num_from_canonical_orbit(iFilename))
end