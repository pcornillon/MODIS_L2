function zenith_angle = compute_solar_zenith_angle(lat, lon, year_vec, month_vec, day_vec, hour_vec, min_vec, sec_vec)
    % Compute the solar zenith angle for each pixel location and time
    % Convert the date and time to Julian date

    time_fractional_days = datenum(year_vec, month_vec, day_vec, hour_vec, min_vec, sec_vec);
    tt = datetime(datevec(time_fractional_days));

    jd = juliandate(tt);
    
    % Calculate the number of days from J2000
    n = jd - 2451545.0;
    
    % Mean longitude of the Sun
    L = mod(280.46 + 0.9856474 * n, 360);
    
    % Mean anomaly of the Sun
    g = deg2rad(mod(357.528 + 0.9856003 * n, 360));
    
    % Ecliptic longitude of the Sun
    lambda = deg2rad(mod(L + 1.915 * sin(g) + 0.02 * sin(2 * g), 360));
    
    % Obliquity of the ecliptic
    epsilon = deg2rad(23.439 - 0.0000004 * n);
    
    % Right ascension and declination of the Sun
    alpha = atan2(cos(epsilon) .* sin(lambda), cos(lambda));
    delta = asin(sin(epsilon) .* sin(lambda));

    % Convert the time to local solar time
    time_in_hours = hour_vec + min_vec / 60 + sec_vec / 3600;

    % Replicate the time_in_hours to match the size of the lon array
    time_in_hours_grid = repmat(time_in_hours', size(lon, 1), 1); % 1354x40271 array

    solar_time = time_in_hours_grid + (lon / 15);

    % Hour angle
    H = deg2rad((solar_time - 12) * 15);
    
    % Replicate the time_in_hours to match the size of the lon array
    delta_grid = repmat(delta', size(lon, 1), 1); % 1354x40271 array

    % Compute the solar zenith angle
    zenith_angle = acos(sin(deg2rad(lat)) .* sin(delta_grid) + cos(deg2rad(lat)) .* cos(delta_grid) .* cos(H));
    zenith_angle = rad2deg(zenith_angle); % Convert to degrees
end