% scan_line_timing_info - get information from formed orbit about scan line timing - PCC
%
% This script reads information from built orbits to determine scan line
% timing. Specifically, does the speed of the satellite change as it moves
% through its orbit.
%

global secs_per_day secs_per_scan_line orbit_length nlat_t nlat_avg

orbit_length = 40271;
secs_per_day = 86400;

secs_per_scan_line = 0.14771810;

num_scan_lines_in_half_orbit = floor(orbit_length / 2);

granules_directory    = '/Volumes/MODIS_L2_original/OBPG/combined/';

problem = 0;

% Get the latitudes for each scan line in the canonical orbit for later use. 

load /Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/metadata/avg_scan_line_start_times.mat
clear sltimes_avg nlon_typical

% Get a list of built orbits to use.

filelist = dir('/Volumes/MODIS_L2_Modified/OBPG/SST/2003/01/AQUA_MODIS_orbit_*.nc4');

%% Loop over the list of full orbit files written by build_and_fix_orbits reading pertinent information.

granule_duration = nan(length(filelist),21);

for iFilename=1:length(filelist)

    % Build the filename from which to extract information.
    
    filename = [filelist(iFilename).folder '/' filelist(iFilename).name];
        
    % Get locations to isolate orbit # and date/dime 

    nn = strfind(filename, '_');

    % When did the orbit start? Times here and below are seconds since 1/1/1970 0:0:0 

    orbit_info(iFilename).orbit_start_time = ncread(filename, 'DateTime'); % seconds since 1970,1,1
    
    % Information about each granule in the orbit.

    granule_info(iFilename).filenames = ncread(filename, '/contributing_granules/filenames');
    
    granule_info(iFilename).start_time = ncread(filename, '/contributing_granules/start_time'); % seconds since 1970,1,1
    granule_info(iFilename).end_time = ncread(filename, '/contributing_granules/end_time'); % seconds since 1970,1,1
    
    granule_info(iFilename).orbit_start_index = ncread(filename, '/contributing_granules/orbit_start_index');
    granule_info(iFilename).orbit_end_index = ncread(filename, '/contributing_granules/orbit_end_index');
    
    granule_info(iFilename).granule_start_index = ncread(filename, '/contributing_granules/granule_start_index');
    granule_info(iFilename).granule_end_index = ncread(filename, '/contributing_granules/granule_end_index');
    
    % Information about the nadir track of each orbit.

    orbit_info(iFilename).nadir_latitude = ncread(filename, 'nadir_latitude');
    
    temp_time = ncread(filename, 'time_from_start_orbit');
    for iScan=1:10:length(temp_time)-9
        for j=0:9
            orbit_info(iFilename).time_from_start_of_orbit(iScan+j) = temp_time(iScan) + j * secs_per_scan_line;
        end
    end
    
    % Information derived from the above: orbit end time and the time in seconds from 1970,1,1 of each scan line. 

    orbit_info(iFilename).seconds_since_1970 = orbit_info(iFilename).orbit_start_time + orbit_info(iFilename).time_from_start_of_orbit; 
    orbit_info(iFilename).orbit_end_time = orbit_info(iFilename).seconds_since_1970(end); % seconds since 1970,1,1

    % Make sure that the start time of the orbit corresponds to the time of the first pixel to use in the first granule.

    orbit_start_time_differences(iFilename) = orbit_info(iFilename).orbit_start_time - ...
        (granule_info(iFilename).start_time(1) + (granule_info(iFilename).granule_start_index(1) - 1) * secs_per_scan_line);

    if abs(orbit_start_time_differences*100/secs_per_scan_line) > 10
        fprintf('\nFor orbit %s the orbit start time (%s) does not agree with the granule start time (%s).\n', ...
            filename(nn(5)+1:nn(7)-1), ...
            datestr(UnixTime2MatTime(orbit_info(iFilename).orbit_start_time)),  ...
            datestr(UnixTime2MatTime(granule_info(iFilename).start_time(1) + (granule_info(iFilename).granule_start_index(1) - 1))))
        fprintf('The percentage difference with regard to the time separating scans is %6.2f%%.\n', ...
            orbit_start_time_differences(iFilename)*100/secs_per_scan_line)

        problem = problem + 1;
    end

    % Get the time between the start of this orbit and the end of the
    % previous orbit and make sure that they are to within either 10 scan
    % lines or 0 scan lines of one another.

    if iFilename == 1
        diff_start_end(iFilename) = nan;
    else
        diff_start_end(iFilename) = (orbit_info(iFilename).orbit_start_time - orbit_info(iFilename-1).orbit_end_time + 100 * secs_per_scan_line);
        fractional_diff(iFilename) = diff_start_end(iFilename) / secs_per_scan_line;

        previous_filename = [filelist(iFilename-1).folder '/' filelist(iFilename-1).name];

        if abs(fractional_diff(iFilename) + 10) > 0.01 & abs(fractional_diff(iFilename)) > 0.01
            fprintf('\n*** The end time of orbit %s (%s) does not correspond to the start time of orbit %s (%s). This should not happen.\n', ...
                previous_filename(nn(5)+1:nn(7)-1), datestr(UnixTime2MatTime(orbit_info(iFilename-1).orbit_end_time + 100 * secs_per_scan_line)), ...
                filename(nn(5)+1:nn(7)-1), datestr(UnixTime2MatTime(orbit_info(iFilename).orbit_start_time + 100 * secs_per_scan_line)))

                problem = problem + 1;
        end
    end

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

fprintf('\nThe min and max times separating the end of one orbit and the start of the next divided by the time separating scans are: %5.3f and  %5.3f.\n', ...
    min(fractional_diff,[],'omitnan'), max(fractional_diff,[],'omitnan'))

if problem
    fprintf('\nEncountered %i problems with orbit or granule start/end time tests.\n', problem)
else
    fprintf('\nThis orbit''s start times is consistent with previous orbit end times.\nThis orbit''s start times is conistent with the time of the scan line in the first granule start corresponding to the start of the orbit.\n')
end

%% Now test to see if it can find the correct starting time for the ith granule in a given orbit.

iGranule = 2;

% Estimate the number of scans from the end of the previous orbit to the
% start of this granule. First, need the 

for iFilename=2:length(filelist)
        
    filename = [filelist(iFilename).folder '/' filelist(iFilename).name];
    nn = strfind(filename, '_');

    % Get the nadir latitudes and times for this granule; will have access to this information in a regular run.
    
    [Year, Month, Day, Hour, Minute, Second] = datevec(granule_info(iFilename).start_time(iGranule)/secs_per_day + datenum(1970,1,1,0,0,0));
    temp_filename = [granules_directory num2str(Year) '/' granule_info(iFilename).filenames(iGranule,:)];
    nlat_t = single(ncread( temp_filename, '/scan_line_attributes/clat'));

    year_t = single(ncread( temp_filename, '/scan_line_attributes/year'));
    day_t = single(ncread( temp_filename, '/scan_line_attributes/day'));
    msec_t = single(ncread( temp_filename, '/scan_line_attributes/msec'));
    
    [month_t day_t] = doy2mmdd(year_t(1), day_t(1));

    mat_time = datenum( double(year_t), double(month_t), double(day_t), 0, 0, double(msec_t/1000)); % days since 0,1,1,0,0,0
    linux_time = (mat_time - datenum(1970,1,1)) * secs_per_day; % seconds since 1970,1,1,0,0,0

    % Make sure that the start time of this granule read from the orbit
    % file corresponds to the first time in the times read above.

    if abs(linux_time(1) - granule_info(iFilename).start_time(iGranule)) > 0.1
        fprintf('\nStart time (%s) for granule %i of orbit %s just read in does not correspond to the start time written to the output file (%s).\n', ...
            datestr(UnixTime2MatTime(linux_time(1))), iGranule, filename(nn(1)+1:nn(2)-1), datestr(UnixTime2MatTime(granule_info(iFilename).start_time(iGranule))))
    else
        fprintf('\nStart time (%s) for granule %i of orbit %s just read in corresponds to the start time written to the output file.\n', ...
            datestr(UnixTime2MatTime(linux_time(1))), iGranule, filename(nn(5)+1:nn(7)-1))
    end
   
    % Now guess at the number of scans from the start of this orbit to the
    % start of this granule. First, do so so using get_scanline_index.
    
    guess_from_get_fn(iFilename) = get_scanline_index;

    % Next, do so based on time.
    
    guess_from_time(iFilename) = floor( (granule_info(iFilename).start_time(iGranule) - ...
        (orbit_info(iFilename-1).orbit_end_time - 100 * secs_per_scan_line) ) / secs_per_scan_line);

    % Next, remember that the number of scan lines from the first one in
    % this granule to the first one for this orbit must be a multiple of 5;
    % the first scan line in the orbit must occur as the 5th line in a
    % group of ten and there are multiple of 10 scan lines per orbit.
    
    guess_from_time(iFilename) = floor( guess_from_time(iFilename) / 10) * 10 + 6;

    % Now determine how close these are to the time of the first scan line in the orbit.

    dt_from_start_of_orbit = granule_info(iFilename).start_time(iGranule) - orbit_info(iFilename).seconds_since_1970;

    kk = find( min(abs(dt_from_start_of_orbit)) == abs(dt_from_start_of_orbit));
    true_scan_num_from_time(iFilename) = kk(5);
   
    % Next repeat based on the latitude of the first scan line in the granule.
    
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

            guess_from_canonical_orbit(iFilename) = nn(1);
         else
            % Two groups
            
            if (nlat_avg(aa(1)+1) > nlat_avg(aa(1))) & (nlat_t(2) > nlat_t(1))
               nn = find( min(abs(nlat_avg(1:num_scan_lines_in_half_orbit) - nlat_t(1))) == abs(nlat_avg(1:num_scan_lines_in_half_orbit) - nlat_t(1)));
               guess_from_canonical_orbit(iFilename) = nn(1);
            else
               nn = find( min(abs(nlat_avg(num_scan_lines_in_half_orbit+1:end) - nlat_t(1))) == abs(nlat_avg(num_scan_lines_in_half_orbit+1:end) - nlat_t(1)));
               guess_from_canonical_orbit(iFilename) = num_scan_lines_in_half_orbit + nn(1);
            end
        end
    end
    
    % Next, remember that the number of scan lines from the first one in
    % this granule to the first one for this orbit must be a multiple of 5;
    % the first scan line in the orbit must occur as the 5th line in a
    % group of ten and there are multiple of 10 scan lines per orbit.
            
    guess_from_canonical_orbit(iFilename) = floor( guess_from_canonical_orbit(iFilename) / 10) * 10 + 6;

    true_scan_num_from_canonical_orbit(iFilename)  = find( min(abs(orbit_info(iFilename).nadir_latitude - nlat_t(1))) == abs(orbit_info(iFilename).nadir_latitude - nlat_t(1)));
    
    fprintf('%i) For %s, iGranule %i starts at orbit element %i\nThe location was guessed to be %i based on time and %i based on latitude.\n', ...
        iFilename, temp_filename(nn(4)+1:nn(5)-1), iGranule, true_scan_num_from_canonical_orbit, guess_from_time(iFilename), ...
        guess_from_canonical_orbit(iFilename))
end