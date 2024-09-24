function bin_gradients_by_month(yearStart,yearEnd)
%

epoch = datenum(1970,1,1,0,0,0); % Epoch time for conversion
secPerday = 86400;               % Seconds per day

% Define directories and file pattern
data_dir = '/Volumes/MODIS_L2_Modified/OBPG/SST_Orbits/';
output_dir = '/Users/petercornillon/Dropbox/Data/MODIS_L2/check_orbits/';

% Open the file that will contain the filenames for bad files, files that couldn't be read.
fileID = fopen([output_dir '/bad_files_in_bin_gradients.txt'], 'w');

% Check if the file opened successfully
if fileID == -1
    error('Failed to open the file for writing.');
end

% Define the latitude and longitude ranges for 1-degree grid
lat_bins = -90:1:90; % Bins for latitude
lon_bins = -180:1:180; % Bins for longitude

% Prepare storage arrays
nLat = length(lat_bins) - 1; % Number of bins for latitude
nLon = length(lon_bins) - 1; % Number of bins for longitude

% Loop through months
for year=yearStart:yearEnd

    for month = 1:12

        iBadOrbit = 0;
        badOrbits.filename = 1;

        outputFile = [data_dir 'gradient_stats_by_period/monthly_stats_' return_a_string( 2, month) '_' num2str(year) '.nc'];

        if exist(outputFile) == 2
            fprintf('monthly_stats file already exists for %i/%i. Going to next month.\n', month, year)
        else

            % Get list of files for the current month
            orbit_files = dir([data_dir num2str(year) '/' return_a_string( 2, month) '/*.nc4']);

            if isempty(orbit_files) == 0

                % Initialize the arrays to hold the sum of values for the month
                day_pixel_count = zeros(nLat, nLon); % Number of pixels in each 1-degree square (daytime)
                night_pixel_count = zeros(nLat, nLon); % Number of pixels in each 1-degree square (nighttime)

                day_sum_eastward_gradient = zeros(nLat, nLon); % Sum of eastward gradient values (daytime)
                night_sum_eastward_gradient = zeros(nLat, nLon); % Sum of eastward gradient values (nighttime)

                day_sum_northward_gradient = zeros(nLat, nLon); % Sum of northward gradient values (daytime)
                night_sum_northward_gradient = zeros(nLat, nLon); % Sum of northward gradient values (nighttime)

                day_sum_magnitude_gradient = zeros(nLat, nLon); % Sum of gradient magnitude (daytime)
                night_sum_magnitude_gradient = zeros(nLat, nLon); % Sum of gradient magnitude (nighttime)

                day_sum_eastward_gradient_squared = zeros(nLat, nLon); % Sum of square of eastward gradient values (daytime)
                night_sum_eastward_gradient_squared = zeros(nLat, nLon); % Sum of square of eastward gradient values (nighttime)

                day_sum_northward_gradient_squared = zeros(nLat, nLon); % Sum of square of northward gradient values (daytime)
                night_sum_northward_gradient_squared = zeros(nLat, nLon); % Sum of square of northward gradient values (nighttime)

                day_sum_magnitude_gradient_squared = zeros(nLat, nLon); % Sum of square of gradient magnitude (daytime)
                night_sum_magnitude_gradient_squared = zeros(nLat, nLon); % Sum of square of gradient magnitude (nighttime)

                for fileIdx = 1:length(orbit_files)

                    % Read data from file
                    orbit_filename = fullfile(orbit_files(fileIdx).folder, orbit_files(fileIdx).name);
                    fprintf('Working on %s at %s\n', orbit_filename, datestr(now, 'HH:MM:SS'))

                    % Get orbit number associated with this filename.
                    nn = strfind(orbit_filename, 'orbit');
                    fileOrbitNumber = str2num(orbit_filename(nn+6:nn+11));

                    % Extract the start time from the orbit filename
                    start_time_str = orbit_filename(nn+13:nn+27);
                    Time_of_orbit_extracted_from_title = datenum(start_time_str, 'yyyymmddTHHMMSS');

                    % Read latitude, longitude, eastward gradient, and
                    % northward gradient from file. The call to a function
                    % is designed to make sure that the file has been
                    % properly read. If not, skip this orbit.

                    % % % try
                    % % %     % Attempt to read the netCDF file
                    % % %     lat = ncread(orbit_filename, 'latitude');
                    % % %
                    % % % catch ME
                    % % %     iBadOrbit = iBadOrbit + 1;
                    % % %
                    % % %     badOrbits(iBadOrbit) = string(orbit_filename);
                    % % %     badOrbits(iBadOrbit).failure_mode = 'reading lat';
                    % % %     badOrbits(iBadOrbit).filename_start_time = Time_of_orbit_extracted_from_title;
                    % % %     badOrbits(iBadOrbit).file_orbit_number = fileOrbitNumber;
                    % % %
                    % % %     reading_problem_filename = [data_dir 'bad_files/reading_problem_' return_a_string( 2, month) '_' num2str(year)];
                    % % %     save([reading_problem_filename, 'badOrbits'])
                    % % %
                    % % %     fprintf('Problem reading lat from this file.\n');
                    % % %
                    % % %     % Continue to the next file
                    % % %     continue;
                    % % % end
                    % % % lon = ncread(orbit_filename, 'longitude');
                    % % % east_grad = ncread(orbit_filename, 'eastward_gradient');
                    % % % north_grad = ncread(orbit_filename, 'northward_gradient');
                    % % % dateTime = ncread(orbit_filename, 'DateTime') / secPerday + epoch; % Read the time of the first scan lin
                    % % % time_from_start_orbit = ncread(orbit_filename, 'time_from_start_orbit'); % Time offset for each scan line

                    [status, lat] = read_nc_variable( orbit_filename, 'regridded_latitude', month, year, data_dir, iBadOrbit, badOrbits, ...
                        'Could not read this file.', Time_of_orbit_extracted_from_title, fileOrbitNumber, 'lat');
                    if status == 0
                        [status, lon] = read_nc_variable( orbit_filename, 'regridded_longitude', month, year, data_dir, iBadOrbit, badOrbits, ...
                            'longitude does not exist.', Time_of_orbit_extracted_from_title, fileOrbitNumber, 'lon');
                        if status == 0
                            [status, east_grad] = read_nc_variable( orbit_filename, 'eastward_gradient', month, year, data_dir, iBadOrbit, badOrbits, ...
                                'eastward_gradient does not exist.', Time_of_orbit_extracted_from_title, fileOrbitNumber, 'east_grad');
                            if status == 0
                                [status, north_grad] = read_nc_variable( orbit_filename, 'northward_gradient', month, year, data_dir, iBadOrbit, badOrbits, ...
                                    'northward_gradient does not exist.', Time_of_orbit_extracted_from_title, fileOrbitNumber, 'north_grad');
                                if status == 0
                                    [status, dateTime] = read_nc_variable( orbit_filename, 'DateTime', month, year, data_dir, iBadOrbit, badOrbits, ...
                                        'DateTime does not exist.', Time_of_orbit_extracted_from_title, fileOrbitNumber, 'DateTime');
                                    if status == 0
                                        [status, time_from_start_orbit] = read_nc_variable( orbit_filename, 'time_from_start_orbit', month, year, data_dir, iBadOrbit, badOrbits, ...
                                            'time_from_start_orbit does not exist.', Time_of_orbit_extracted_from_title, fileOrbitNumber, 'time_from_start_orbit');
                                        if status == 0

                                            % Exclude the edge pixels plus some.

                                            elim = 5;
                                            lat = lat(elim:end-elim,elim:end-elim);
                                            lon = lon(elim:end-elim,elim:end-elim);
                                            east_grad = east_grad(elim:end-elim,elim:end-elim);
                                            north_grad = north_grad(elim:end-elim,elim:end-elim);
                                            time_from_start_orbit = time_from_start_orbit(elim:end-elim);

                                            % Calculate the gradient magnitude
                                            grad_magnitude = sqrt(east_grad.^2 + north_grad.^2);

                                            % Adjust longitude values to the range of -180 to 180 degrees
                                            lon = mod(lon + 180, 360) - 180;

                                            % Flatten the data arrays for efficient indexing
                                            lat_flat = lat(:);
                                            lon_flat = lon(:);
                                            east_grad_flat = east_grad(:);
                                            north_grad_flat = north_grad(:);
                                            grad_magnitude_flat = grad_magnitude(:);
                                            time_offset_flat = time_from_start_orbit(:); % Flatten the time offset array

                                            % Compute the exact time for each scan line.
                                            time_fractional_days = dateTime + time_offset_flat / 86400; % Convert seconds to fractional days
                                            [year_vec, month_vec, day_vec, hour_vec, min_vec, sec_vec] = datevec(time_fractional_days); % Convert to date vectors
                                            % % % tt = dateTime(datestr(time_fractional_days));

                                            % Compute the solar zenith angle for each pixel
                                            solar_zenith_angle = compute_solar_zenith_angle(lat, lon, year_vec, month_vec, day_vec, hour_vec, min_vec, sec_vec);
                                            % % % solar_zenith_angle = compute_solar_zenith_angle(lat_flat, lon_flat, tt);

                                            % Find the indices for the 1-degree grid bins using histcounts
                                            [~, ~, lat_bin] = histcounts(lat_flat, lat_bins);
                                            [~, ~, lon_bin] = histcounts(lon_flat, lon_bins);

                                            % Identify daytime (solar zenith angle < 90) and nighttime pixels (solar zenith angle >= 90)
                                            is_daytime = solar_zenith_angle < 90;
                                            is_nighttime = solar_zenith_angle >= 90;

                                            % Use accumarray to perform efficient summation for daytime
                                            % Only count pixels where there were good gradient values.
                                            nn = find(is_daytime & (isnan(north_grad) == 0));

                                            if isempty(nn) == 0
                                                day_pixel_count = day_pixel_count + accumarray([lat_bin(nn), lon_bin(nn)], 1, [nLat, nLon]);
                                                day_sum_eastward_gradient = day_sum_eastward_gradient + accumarray([lat_bin(nn), lon_bin(nn)], east_grad_flat(nn), [nLat, nLon]);
                                                day_sum_northward_gradient = day_sum_northward_gradient + accumarray([lat_bin(nn), lon_bin(nn)], north_grad_flat(nn), [nLat, nLon]);
                                                day_sum_magnitude_gradient = day_sum_magnitude_gradient + accumarray([lat_bin(nn), lon_bin(nn)], grad_magnitude_flat(nn), [nLat, nLon]);
                                                day_sum_eastward_gradient_squared = day_sum_eastward_gradient_squared + accumarray([lat_bin(nn), lon_bin(nn)], east_grad_flat(nn).^2, [nLat, nLon]);
                                                day_sum_northward_gradient_squared = day_sum_northward_gradient_squared + accumarray([lat_bin(nn), lon_bin(nn)], north_grad_flat(nn).^2, [nLat, nLon]);
                                                day_sum_magnitude_gradient_squared = day_sum_magnitude_gradient_squared + accumarray([lat_bin(nn), lon_bin(nn)], grad_magnitude_flat(nn).^2, [nLat, nLon]);
                                            end
                                            % Use accumarray to perform efficient summation for nighttime
                                            nn = find(is_nighttime & (isnan(north_grad) == 0));

                                            if isempty(nn) == 0
                                                night_pixel_count = night_pixel_count + accumarray([lat_bin(nn), lon_bin(nn)], 1, [nLat, nLon]);
                                                night_sum_eastward_gradient = night_sum_eastward_gradient + accumarray([lat_bin(nn), lon_bin(nn)], east_grad_flat(nn), [nLat, nLon]);
                                                night_sum_northward_gradient = night_sum_northward_gradient + accumarray([lat_bin(nn), lon_bin(nn)], north_grad_flat(nn), [nLat, nLon]);
                                                night_sum_magnitude_gradient = night_sum_magnitude_gradient + accumarray([lat_bin(nn), lon_bin(nn)], grad_magnitude_flat(nn), [nLat, nLon]);
                                                night_sum_eastward_gradient_squared = night_sum_eastward_gradient_squared + accumarray([lat_bin(nn), lon_bin(nn)], east_grad_flat(nn).^2, [nLat, nLon]);
                                                night_sum_northward_gradient_squared = night_sum_northward_gradient_squared + accumarray([lat_bin(nn), lon_bin(nn)], north_grad_flat(nn).^2, [nLat, nLon]);
                                                night_sum_magnitude_gradient_squared = night_sum_magnitude_gradient_squared + accumarray([lat_bin(nn), lon_bin(nn)], grad_magnitude_flat(nn).^2, [nLat, nLon]);
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                % Write the accumulated data to a netCDF file for the current month
                % outputFile = [data_dir 'gradient_stats_by_period/monthly_stats_' return_a_string( 2, month) '_' num2str(year) '.nc'];

                % Create the netCDF file with compression for both daytime and nighttime data
                nccreate(outputFile, 'day_pixel_count', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'night_pixel_count', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'day_sum_eastward_gradient', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'night_sum_eastward_gradient', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'day_sum_northward_gradient', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'night_sum_northward_gradient', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'day_sum_magnitude_gradient', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'night_sum_magnitude_gradient', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'day_sum_eastward_gradient_squared', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'night_sum_eastward_gradient_squared', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'day_sum_northward_gradient_squared', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'night_sum_northward_gradient_squared', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'day_sum_magnitude_gradient_squared', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);
                nccreate(outputFile, 'night_sum_magnitude_gradient_squared', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'DeflateLevel', 5);

                % Write data to netCDF file
                ncwrite(outputFile, 'day_pixel_count', day_pixel_count);
                ncwrite(outputFile, 'night_pixel_count', night_pixel_count);
                ncwrite(outputFile, 'day_sum_eastward_gradient', day_sum_eastward_gradient);
                ncwrite(outputFile, 'night_sum_eastward_gradient', night_sum_eastward_gradient);
                ncwrite(outputFile, 'day_sum_northward_gradient', day_sum_northward_gradient);
                ncwrite(outputFile, 'night_sum_northward_gradient', night_sum_northward_gradient);
                ncwrite(outputFile, 'day_sum_magnitude_gradient', day_sum_magnitude_gradient);
                ncwrite(outputFile, 'night_sum_magnitude_gradient', night_sum_magnitude_gradient);
                ncwrite(outputFile, 'day_sum_eastward_gradient_squared', day_sum_eastward_gradient_squared);
                ncwrite(outputFile, 'night_sum_eastward_gradient_squared', night_sum_eastward_gradient_squared);
                ncwrite(outputFile, 'day_sum_northward_gradient_squared', day_sum_northward_gradient_squared);
                ncwrite(outputFile, 'night_sum_northward_gradient_squared', night_sum_northward_gradient_squared);
                ncwrite(outputFile, 'day_sum_magnitude_gradient_squared', day_sum_magnitude_gradient_squared);
                ncwrite(outputFile, 'night_sum_magnitude_gradient_squared', night_sum_magnitude_gradient_squared);
            end
        end
    end
end
