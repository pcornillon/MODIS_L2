function zenith_angle = compute_solar_zenith_angle(lat, lon, year, month, day, hour, minute, second)
    % Compute the solar zenith angle for each pixel location and time
    % Convert the date and time to Julian date
    jd = juliandate(year, month, day, hour, minute, second);
    
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
    alpha = atan2(cos(epsilon) * sin(lambda), cos(lambda));
    delta = asin(sin(epsilon) * sin(lambda));
    
    % Convert the time to local solar time
    time_in_hours = hour + minute / 60 + second / 3600;
    solar_time = time_in_hours + (lon / 15);
    
    % Hour angle
    H = deg2rad((solar_time - 12) * 15);
    
    % Compute the solar zenith angle
    zenith_angle = acos(sin(deg2rad(lat)) .* sin(delta) + cos(deg2rad(lat)) .* cos(delta) .* cos(H));
    zenith_angle = rad2deg(zenith_angle); % Convert to degrees
end