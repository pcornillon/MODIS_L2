% Define directories and file pattern
dataDir = 'path_to_your_data_directory'; % Replace with the path to your data
outputDir = 'path_to_output_directory'; % Replace with the path where you want to save the netCDF file

% Define the latitude and longitude ranges for 1-degree grid
lat_bins = -90:1:90; % Bins for latitude
lon_bins = -180:1:180; % Bins for longitude

% Prepare storage arrays
nLat = length(lat_bins) - 1; % Number of bins for latitude
nLon = length(lon_bins) - 1; % Number of bins for longitude

% Loop through months
for year = 2002:2022
    for month = 1:12
        % Get list of files for the current month
        orbit_files = dir(fullfile(dataDir, sprintf('%04d/%02d/*.nc', year, month)));

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
                filePath = fullfile(orbit_files(fileIdx).folder, orbit_files(fileIdx).name);

                % Read latitude, longitude, eastward gradient, and northward gradient from file
                try
                    % Attempt to read the netCDF file
                    lat = ncread(filePath, 'latitude');

                catch ME
                    iBadOrbit = iBadOrbit + 1;
                    BadOrbits(iBadOrbit) = string(orbitFullFileName);
                    fprintf(fileID, '%s\n', string(orbitFullFileName));

                    kNumMissing = kNumMissing + 1;

                    MissingGranules(kNumMissing).orbit_filename = orbit_filename;
                    MissingGranules(kNumMissing).problem = 'bad orbit file';

                    % If an error occurs, catch it and flag the problem
                    % warning(['Error reading file: ', orbit_files(iOrbit).name, '. Moving to next file.']);
                    % disp(['Error message: ', ME.message]);

                    % Continue to the next file
                    continue;
                end
                lon = ncread(filePath, 'longitude');
                east_grad = ncread(filePath, 'eastward_gradient');
                north_grad = ncread(filePath, 'northward_gradient');
                DateTime = ncread(filePath, 'DateTime'); % Read the time of the first scan line
                time_from_start_orbit = ncread(filePath, 'time_from_start_orbit'); % Time offset for each scan line

                % Calculate the gradient magnitude
                grad_magnitude = sqrt(east_grad.^2 + north_grad.^2);

                % Flatten the data arrays for efficient indexing
                lat_flat = lat(:);
                lon_flat = lon(:);
                east_grad_flat = east_grad(:);
                north_grad_flat = north_grad(:);
                grad_magnitude_flat = grad_magnitude(:);
                time_offset_flat = time_from_start_orbit(:); % Flatten the time offset array

                % Adjust longitude values to the range of -180 to 180 degrees
                lon_flat = mod(lon_flat + 180, 360) - 180;

                % Compute the exact time for each scan line
                time_fractional_days = DateTime + time_offset_flat / 86400; % Convert seconds to fractional days
                [year_vec, month_vec, day_vec, hour_vec, min_vec, sec_vec] = datevec(time_fractional_days); % Convert to date vectors
                % % % tt = datetime(datestr(time_fractional_days));

                % Compute the solar zenith angle for each pixel
                solar_zenith_angle = compute_solar_zenith_angle(lat_flat, lon_flat, year_vec, month_vec, day_vec, hour_vec, min_vec, sec_vec);
                % % % solar_zenith_angle = compute_solar_zenith_angle(lat_flat, lon_flat, tt);

                % Find the indices for the 1-degree grid bins using histcounts
                [~, ~, lat_bin] = histcounts(lat_flat, lat_bins);
                [~, ~, lon_bin] = histcounts(lon_flat, lon_bins);

                % Identify daytime (solar zenith angle < 90) and nighttime pixels (solar zenith angle >= 90)
                is_daytime = solar_zenith_angle < 90;

                % Use accumarray to perform efficient summation for daytime
                day_pixel_count = day_pixel_count + accumarray([lat_bin(is_daytime), lon_bin(is_daytime)], 1, [nLat, nLon]);
                day_sum_eastward_gradient = day_sum_eastward_gradient + accumarray([lat_bin(is_daytime), lon_bin(is_daytime)], east_grad_flat(is_daytime), [nLat, nLon]);
                day_sum_northward_gradient = day_sum_northward_gradient + accumarray([lat_bin(is_daytime), lon_bin(is_daytime)], north_grad_flat(is_daytime), [nLat, nLon]);
                day_sum_magnitude_gradient = day_sum_magnitude_gradient + accumarray([lat_bin(is_daytime), lon_bin(is_daytime)], grad_magnitude_flat(is_daytime), [nLat, nLon]);
                day_sum_eastward_gradient_squared = day_sum_eastward_gradient_squared + accumarray([lat_bin(is_daytime), lon_bin(is_daytime)], east_grad_flat(is_daytime).^2, [nLat, nLon]);
                day_sum_northward_gradient_squared = day_sum_northward_gradient_squared + accumarray([lat_bin(is_daytime), lon_bin(is_daytime)], north_grad_flat(is_daytime).^2, [nLat, nLon]);
                day_sum_magnitude_gradient_squared = day_sum_magnitude_gradient_squared + accumarray([lat_bin(is_daytime), lon_bin(is_daytime)], grad_magnitude_flat(is_daytime).^2, [nLat, nLon]);

                % Use accumarray to perform efficient summation for nighttime
                night_pixel_count = night_pixel_count + accumarray([lat_bin(~is_daytime), lon_bin(~is_daytime)], 1, [nLat, nLon]);
                night_sum_eastward_gradient = night_sum_eastward_gradient + accumarray([lat_bin(~is_daytime), lon_bin(~is_daytime)], east_grad_flat(~is_daytime), [nLat, nLon]);
                night_sum_northward_gradient = night_sum_northward_gradient + accumarray([lat_bin(~is_daytime), lon_bin(~is_daytime)], north_grad_flat(~is_daytime), [nLat, nLon]);
                night_sum_magnitude_gradient = night_sum_magnitude_gradient + accumarray([lat_bin(~is_daytime), lon_bin(~is_daytime)], grad_magnitude_flat(~is_daytime), [nLat, nLon]);
                night_sum_eastward_gradient_squared = night_sum_eastward_gradient_squared + accumarray([lat_bin(~is_daytime), lon_bin(~is_daytime)], east_grad_flat(~is_daytime).^2, [nLat, nLon]);
                night_sum_northward_gradient_squared = night_sum_northward_gradient_squared + accumarray([lat_bin(~is_daytime), lon_bin(~is_daytime)], north_grad_flat(~is_daytime).^2, [nLat, nLon]);
                night_sum_magnitude_gradient_squared = night_sum_magnitude_gradient_squared + accumarray([lat_bin(~is_daytime), lon_bin(~is_daytime)], grad_magnitude_flat(~is_daytime).^2, [nLat, nLon]);
            end

            % Write the accumulated data to a netCDF file for the current month
            outputFile = sprintf('%s/monthly_stats_%04d_%02d.nc', outputDir, year, month);

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
