% diagnostic_separation_and_angle_plots - plots diagnostic fields to test generate_separations_and_angles - PCC
%
%               VARIABLES
%
% mean_az - the azimuthal angle of the scan line measured clockwise from
%  north. The direction of the scan line is taken as positive in the
%  direction in which the sensor is scanning.
%
% as_angle - the counter-clockwise angle the scan line makes relative to
%  east at each pixel location. The direction of the scan line is taken as
%  the scan direction, so if the sensor is scaning east-to-west, the angle
%  would be -180 degrees, west-to-east, 0 degrees, south-to-north 90 degrees.
%
% mean_az_final - as_angle smoothed with an 11 point moving median filter in
%  the along-scan direction.
%
% mean_sas - separations in the along-scan direction averaged over a number
%  of orbits. The orbits were constructed so that the location of a pixel
%  in the orbit is at very nearly the same location for all orbits of a
%  given length. There are in fact two lengths of orbits differing by 10
%  scan lines. I may fix this by buffering one end or the other the orbit
%  for the shorter ones.
% mean_sat - separations in the along-track direction averaged over a number of orbits.
%
%                   FIGURES
%
% Fig. 1 -
%
% Fig. 11 - mean_az_final
% Fig. 12 - as_angle - mean_az_final
% Fig. 13 - Along-track plot of the az_angle and mean_az_final at pixel location 310.
% Fig. 13 - Along-track plot of the az_angle and mean_az_final at pixel location 1000.
% Fig. 13 - Along-track plot of the az_angle and mean_az_final at pixel location 8000.

base_dir = '/Users/petercornillon/Dropbox/ComputerPrograms/MATLAB/Projects/MODIS_L2/';
base_dir_temp = '~/Dropbox/ComputerPrograms/Fronts_Gradients-Workflow/Matlab/Decloud/';
% base_dir_temp = '/Volumes/Aqua-1/junk/';

% Tell the script where to get the data to plot. Set wheres_the_data_to_plot to:
%   -2 if the data were read in from mean_seps_and_angles_pass** files,
%   -1 if the data were read in from from netCDF file,
%   0 if data are already in memory, don't read in again.
%   1 to read data from netCDF file, and
%   2 to read data from mean_seps_and_angles_pass** files.

wheres_the_data_to_plot = 1;

% The plot control vector can be used to turn on/off specific plots. To
% turn on set the given element of the array to its location in the array;
% e.g., to make the plot for figure 41, enter 41 in the 41st element of
% plot_control.
%

% plot_control = [1:400];         % Turn on all plots add an offset to compare plots
plot_control = zeros(1,400);    % Turn off all plots
plot_control(25) = 25;        % Turn on a specific plot.
plot_control(41) = 41;        % Turn on a specific plot.
plot_control(42) = 44;        % Turn on a specific plot.
plot_control(43) = 43;        % Turn on a specific plot.
plot_control(44) = 44;        % Turn on a specific plot.

% plot_contol_xxxs is used to turn groups of plots on or off. This is a 0/1 flag.

plot_control_010s = 0;
plot_control_020s = 0;
plot_control_030s = 0;
plot_control_040s = 1;
plot_control_100s = 0;
plot_control_200s = 0;
plot_control_300s = 1;

% Generate based on lat,lon, azimuthal angle, and separations.

load coastlines.mat

% Get the data to plot, from netCDF file if wheres_the_data_to_plot = 1,
% or from the files saved by generate_separations if wheres_the_data_to_plot = 2

if wheres_the_data_to_plot == 1
    output_filename = [base_dir 'Data/Separation_and_Angle_Arrays.n4'];
    
    longitude = ncread( output_filename, 'longitude');
    latitude = ncread( output_filename, 'latitude');
    
    track_angle = ncread( output_filename, 'track_angle');
    
    along_scan_seps_array = ncread(output_filename, 'along_scan_seps_array');
    along_track_seps_array = ncread(output_filename, 'along_track_seps_array');
    
    along_scan_seps = ncread(output_filename, 'along_scan_seps_vector');
    along_track_seps = ncread(output_filename, 'along_track_seps_vector');
    
    smoothed_min_along_scan_factor = ncread(output_filename, 'smoothed_along_scan_factor');
    smoothed_min_along_track_factor = ncread(output_filename, 'smoothed_along_track_factor');
end

if wheres_the_data_to_plot == 2
    fprintf('\n ***********************************************************\n Reading First iteration ************************************\n ***********************************************************\n\n')
%     load([base_dir 'Data/mean_seps_and_angles_pass_1.mat'])
    load([base_dir_temp 'mean_seps_and_angles_pass_1.mat'])
    
    fprintf('\n ***********************************************************\n Reading Second iteration **********************************\n ***********************************************************\n\n')
%     load([base_dir 'Data/mean_seps_and_angles_pass_2.mat'])
    load([base_dir_temp 'mean_seps_and_angles_pass_2.mat'])
    
    fprintf('\n ***********************************************************\n Reading Final Smoothing ************************************\n ***********************************************************\n\n')
%     load([base_dir 'Data/auxillary_seps_and_angles.mat'])
    load([base_dir_temp 'auxillary_seps_and_angles.mat'])
end

if wheres_the_data_to_plot > 0
    if size(smoothed_min_along_scan_factor,2) == 1
        along_scan_seps_array =  along_scan_seps * smoothed_min_along_scan_factor';
        along_track_seps_array =  along_track_seps * smoothed_min_along_track_factor';
    else
        along_scan_seps_array =  along_scan_seps * smoothed_min_along_scan_factor;
        along_track_seps_array =  along_track_seps * smoothed_min_along_track_factor;
    end
end

fprintf('\n ***********************************************************\n Setting Up Test Orbit ************************************\n ***********************************************************\n\n')

% fi_orbit_1 = '/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/06/AQUA_MODIS.20100601T021010.L2.SST.nc4';
fi_orbit_1 = [base_dir 'Data/AQUA_MODIS.20100601T021010.L2.SST.nc4'];
index_1_equator_a = 11146; % a for ascending.
index_1_m58_a = 4500;  % scan line will cross the international date line 180 E.
index_1_p35_a = 15074;
index_2_81p86 = 21172; % Highest latitude in orbit.
index_1_equator_d = 31198; % d for descending.
index_1_p35_d = 27271;

% % % % Get the latitude and longitude for this orbit. The latitude of other
% % % % orbits should be the same. The longitudes should be these longitudes
% % % % offset by the differences in ascending equatorial crossings.
% % %
% % % latitude = ncread( fi_orbit_1, 'regridded_latitude');
% % % longitude = ncread( fi_orbit_1, 'regridded_longitude');

% pixels from nadir for calculations and plots.

[num_elements_per_along_scan num_along_scans] = size(longitude);
pixels_from_nadir = [-num_elements_per_along_scan/2:num_elements_per_along_scan/2 - 1]';

% Get the separations based on adjacent pixels for the test orbit.

if wheres_the_data_to_plot > 0
    lat_as_temp = (latitude(2:end,:) - latitude(1:end-1,:)) * 111;
    lon_as_temp = (longitude(2:end,:) - longitude(1:end-1,:)) .* cosd(latitude(1:end-1,:)) * 111;
    lat_as_array = single([lat_as_temp(1,:); lat_as_temp]);
    lon_as_array = single([lon_as_temp(1,:); lon_as_temp]);
    as_sep_1_orbit = sqrt(lat_as_array.^2 + lon_as_array.^2);
    
    lat_at_temp = (latitude(:,2:end) - latitude(:,1:end-1)) * 111;
    lon_at_temp = (longitude(:,2:end) - longitude(:,1:end-1)) .* cosd(latitude(:,1:end-1)) * 111;
    lat_at_array = single([lat_at_temp(:,1), lat_at_temp]);
    lon_at_array = single([lon_at_temp(:,1), lon_at_temp]);
    at_sep_1_orbit = sqrt(lat_at_array.^2 + lon_at_array.^2);
end

%% Plots the azimuthal angle results

% The original version of the angle was determined clockwise from north but
% we want it counterclockwise from east since we are going to compare it to
% the smoothed version in the following plots, so convert the original
% estimatefrom clockwise from north to counterclockwise from east.

if wheres_the_data_to_plot == 1
    as_angle = ncread( output_filename, 'scan_angle');
end

if plot_control_010s
    
    if abs(wheres_the_data_to_plot) == 2
        as_angle = 450 - mean_az;
        as_angle(as_angle>360) = as_angle(as_angle>360) - 360;
        
        plot_image( plot_control(11), pixels_from_nadir, [1:num_along_scans], mean_az_final', [], 'Pixels from Nadir', 'Scan Line', strrep(' mean_az_final', '_', '\_'))
        
        mean_az_diff = as_angle - mean_az_final;
        plot_image( plot_control(12), pixels_from_nadir, [1:num_along_scans], mean_az_diff', [-1 1]*0.5, 'Pixels from Nadir', 'Scan Line', strrep('as_angle - mean_az_final', '_', '\_'))
        
        lines_to_plot{1} = as_angle(310,:);
        lines_to_plot{2} = mean_az_final(310,:);
        plot_lines( plot_control(13), [], lines_to_plot, [21000 27000 270 360], {'b' 'r'}, [1 1], 'Scan Line', 'Mean Angle', 'Mean Angles for Pixel From Nadir: -367', {'mean\_az', 'mean\_az\_smoothed'})
        
        lines_to_plot{1} = as_angle(:,1000);
        lines_to_plot{2} = mean_az_final(:,1000);
        plot_lines( plot_control(14), [], lines_to_plot, [], {'b' 'r'}, [1 1], 'Pixels from Nadir', 'Mean Angle', 'Mean Angles for Scan Line: 1000', {'mean\_az', 'mean\_az\_smoothed'})
        
        lines_to_plot{1} = as_angle(:,8000);
        lines_to_plot{2} = mean_az_final(:,8000);
        plot_lines( plot_control(15), [], lines_to_plot, [], {'b' 'r'}, [1 1], 'Pixels from Nadir', 'Mean Angle', 'Mean Angles for Scan Line: 8000', {'mean\_az', 'mean\_az\_smoothed'})
    end
end

%% Now plot up results for separation

if plot_control_020s
    
    % Plot the mean sum of squared differences for the selected factor.
    
    % Plot the difference.
    
    if wheres_the_data_to_plot == 1
        min_along_scan_factor = ncread(output_filename, 'along_scan_factor');
        min_along_track_factor = ncread(output_filename, 'along_track_factor');
    end
    
    if abs(wheres_the_data_to_plot) == 2
        %         plot_image( plot_control(21), pixels_from_nadir, [1:num_along_scans], along_scan_sep_diff_1st', [-1 1]*0.2, 'Pixels from Nadir', 'Scan Line', 'First Guess Pixel Separation -- All Scan Lines')
        
        along_scan_sep_diff = mean_sas - along_scan_seps .* ones(1,num_along_scans);
        plot_image( plot_control(22), pixels_from_nadir, [1:num_along_scans], along_scan_sep_diff', [-1 1]*0.2, 'Pixels from Nadir', 'Scan Line', 'Pixel Separations Excluding Problem Scans')
        
        % Now plot the percentage difference between the 1st guess scan line
        % separations and the improved scan line separations.
        
        mean_along_scan_sep_diff = along_scan_seps - along_scan_seps_1st;
        plot_lines( plot_control(23), pixels_from_nadir, {100 * mean_along_scan_sep_diff ./ along_scan_seps}, [-1354/2 1354/2 -0.25 -0.04], [], [1], 'Pixels from Nadir', 'Percent Difference', 'Best Scan Line Separation Minus First Guess')
        
        % Get the variance of separations for good scan lines and plot them.
        
        along_scan_seps_std = std(mean_sas(:,[1380:21010, 21310:end]), [], 2, 'omitnan');
        plot_lines( plot_control(24), pixels_from_nadir, {100 * along_scan_seps_std ./ along_scan_seps}, [-1354/2 1354/2 0 2.1], [], [1], 'Pixels from Nadir', 'Percent Variability', '100 * Separation Sigma / Mean Separation')
    end
    
    % Plot the factor as a function of scan line.
    
    lines_to_plot{1} = min_along_scan_factor;
    lines_to_plot{2} = smoothed_min_along_scan_factor;
    lines_to_plot{3} = min_along_track_factor;
    lines_to_plot{4} = smoothed_min_along_track_factor;
    plot_lines( plot_control(25), [1:length(min_along_scan_factor)],  lines_to_plot, [0 num_along_scans 0.97 1.04], {'b' 'm' 'k' 'r'}, [1 2 1 2], 'Scan Line', 'Factor', 'Factors for Along-Scan and Along-Track Separations', {'Original Along-Scan Factor', 'Smoothed Along-Scan Factor', 'Original Along-Track Factor', 'Smoothed Along-Track Factor'})
    
    % Plot the mean sum of squared differences for the selected factor.
    
    if abs(wheres_the_data_to_plot) == 2
        clear lines_to_plot
        lines_to_plot{1} = min_rms_along_scan_diff;
        lines_to_plot{2} = min_rms_along_track_diff;
        plot_lines( plot_control(26), [1:length(min_rms_along_scan_diff)], lines_to_plot, [0 num_along_scans 0 10^-3], {'k' 'r'}, [1 1], 'Scan Line', 'RMS', 'For Along-Scan \& Along-Track Separations $\sqrt{\Sigma_j(scan\_line_{ij}-best\_fit_j*factor_i)^2}$', {'Along-Scan' 'Along-Track'})
        
        plot_lines( plot_control(27), pixels_from_nadir, {along_scan_locs}, [-1354/2 1354/2 -1500 1500], [], [1], 'Pixel Number from Nadir', 'Distance from Nadir (km)', 'Distance from Nadir vs Pixel Location')
    end
end

%% Plot geographically.

if plot_control_030s
    
    print_angle_info = 0;
    
    iElement = 677;
    
    % Adjust the orbit to have the same nadir track as lon_nadir. This is
    % because this track has points at good locations in the Pacific to
    % test the angle.
    
    eq_lon_sep = lon_nadir(11147) - longitude(677,11147);
    new_lon= longitude + eq_lon_sep;
    new_lon(new_lon<-180) = new_lon(new_lon<-180) + 360;
    
    jScan = 0;
    for iScan=1:5000:num_along_scans
        jScan = jScan + 1;
        
        lon_eq_a = new_lon(iElement,iScan);
        lat_eq_a = latitude(iElement,iScan);
        
        if print_angle_info
            fprintf('\nWe will start with this lon,lat location on the nadir track: %6.3f,%6.3f\n', lon_eq_a, lat_eq_a)
        end
        
        % Now get the azimuthal angle as a function of distance from nadir for the
        % selected location.
        
        %         az_sl = mean_az_final(iElement,iScan);
        az_sl = mean_az_final(iElement,iScan);
        
        if print_angle_info
            fprintf('The scan line is rotated counter clockwise %5.1f degrees relative to east.\n', az_sl)
        end
        
        % And convert from degrees counterclockwise from east to degrees
        % clockwise from north.
        
        az_sl = 450 - az_sl;
        az_sl(az_sl>=360) = az_sl(az_sl>=360) - 360;
        
        if iScan == 1
            figure(plot_control(31))
            clf
            
            plot(lon_nadir, lat_nadir, 'k', linewidth=1);
            hold on
            plot(coastlon,coastlat, color=[0.6 0.6 0.6])
        else
            plot(lon_nadir, lat_nadir, 'k', linewidth=1);
        end
        
        plot( lon_eq_a, lat_eq_a, 'ok', markerfacecolor='c', markersize=5);
        
        % Plot scan line and end points of scan line
        
        plot( new_lon(:,iScan), latitude(:,iScan), 'k');
        
        plot( new_lon(1,iScan), latitude(1,iScan), 'ok', markerfacecolor='r', markersize=5);
        plot( new_lon(end,iScan), latitude(end,iScan), 'ok', markerfacecolor='b', markersize=5);
        
        if print_angle_info
            fprintf('The scan line is rotated counter clockwise %5.1f degrees relative to east.\n', az_sl)
        end
        
        % Plot direction of scan angle based on generic scan angles for the nadir point.
        
        [lattrk,lontrk] = track1( lat_eq_a, lon_eq_a, az_sl, 120/111, [], 'degrees', 2);
        plot( lontrk, lattrk, 'r', linewidth=2)
        
        % Repeat for the first point on this scan
        
        ipt = 1;
        
        az_sl = mean_az_final(ipt,iScan);
        
        az_sl = 450 - az_sl;
        az_sl(az_sl>=360) = az_sl(az_sl>=360) - 360;
        
        lon_pt = new_lon(ipt,iScan);
        lat_pt = latitude(ipt,iScan);
        
        [lattrk_pt,lontrk_pt] = track1( lat_pt, lon_pt, az_sl, 20/111, [], 'degrees', 2);
        plot( lontrk_pt, lattrk_pt, 'r', linewidth=2)
        
        if jScan == 8
            for ipt=1:40:1350
                az_sl = mean_az_final(ipt,iScan);
                
                az_sl = 450 - az_sl;
                az_sl(az_sl>=360) = az_sl(az_sl>=360) - 360;
                
                lon_pt = new_lon(ipt,iScan);
                lat_pt = latitude(ipt,iScan);
                
                [lattrk_pt,lontrk_pt] = track1( lat_pt, lon_pt, az_sl, 20/111, [], 'degrees', 2);
                plot( lontrk_pt, lattrk_pt, 'r', linewidth=2)
                
            end
        end
    end
end

%% Compare the along-scan and along-track separations for a single orbit with the final, smoothed versions.

if plot_control_040s
    lines_to_plot{1} = as_sep_1_orbit(10,:);
    lines_to_plot{2} = as_sep_1_orbit(677,:);
    lines_to_plot{3} = as_sep_1_orbit(1350,:);
    lines_to_plot{4} = along_scan_seps_array(10,:);
    lines_to_plot{5} = along_scan_seps_array(677,:);
    lines_to_plot{6} = along_scan_seps_array(1350,:);
    plot_lines( plot_control(41), [], lines_to_plot, [0 4071 0 6], {'y' 'g' 'c' 'r' 'b' 'k'}, [1 1 1 2 2 2], ...
        'Scan Line', 'Separation (km)', 'Along-Scan Separations', ...
        {'One Orbit (10)' 'One Orbit (677)' 'One Orbit (1350)' 'Smoothed Values (10)' 'Smoothed Values (677)' 'Smoothed Values (1350)'})
    
    lines_to_plot{1} = at_sep_1_orbit(10,:);
    lines_to_plot{2} = at_sep_1_orbit(677,:);
    lines_to_plot{3} = at_sep_1_orbit(1350,:);
    lines_to_plot{4} = along_track_seps_array(10,:);
    lines_to_plot{5} = along_track_seps_array(677,:);
    lines_to_plot{6} = along_track_seps_array(1350,:);
    plot_lines( plot_control(42), [], lines_to_plot, [0 40701 0.8 1.2], {'y' 'g' 'c' 'r' 'b' 'k'}, [1 1 1 2 2 2], ...
        'Scan Line', 'Separation (km)', 'Along-Track Separations', ...
        {'One Orbit (10)' 'One Orbit (677)'  'One Orbit (1350)' 'Smoothed Values (10)' 'Smoothed Values (677)' 'Smoothed Values (1350)'})
    
    lines_to_plot{1} = as_sep_1_orbit(:,100);
    lines_to_plot{2} = as_sep_1_orbit(:,15000);
    lines_to_plot{3} = as_sep_1_orbit(:,35000);
    lines_to_plot{4} = along_scan_seps_array(:,100);
    lines_to_plot{5} = along_scan_seps_array(:,15000);
    lines_to_plot{6} = along_scan_seps_array(:,35000);
    plot_lines( plot_control(43), [], lines_to_plot, [0 1354 0 6], {'y' 'g' 'c' 'r' 'b' 'k'}, [1 1 1 2 2 2], ...
        'Pixel Location', 'Separation (km)', 'Along-Scan Separations', ...
        {'One Orbit (100)' 'One Orbit (1500)'  'One Orbit (35000)' 'Smoothed Values (100)' 'Smoothed Values (15000)' 'Smoothed Values (35000)'})
    
    lines_to_plot{1} = at_sep_1_orbit(:,100);
    lines_to_plot{2} = at_sep_1_orbit(:,15000);
    lines_to_plot{3} = at_sep_1_orbit(:,35000);
    lines_to_plot{4} = along_track_seps_array(:,100);
    lines_to_plot{5} = along_track_seps_array(:,15000);
    lines_to_plot{6} = along_track_seps_array(:,35000);
    plot_lines( plot_control(44), [], lines_to_plot, [0 1354 0.8 1.2], {'y' 'g' 'c' 'r' 'b' 'k'}, [1 1 1 2 2 2], ...
        'Pixel Location', 'Separation (km)', 'Along-Track Separations', ...
        {'One Orbit (100)' 'One Orbit (1500)'  'One Orbit (35000)' 'Smoothed Values (100)' 'Smoothed Values (15000)' 'Smoothed Values (35000)'})
end

%% Now do the gradient stuff

% Get both the original and regridded SST fields for the test orbit and
% from them get associated SST gradients in both in K/km and K/pixel for
% regridded SST.

if abs(wheres_the_data_to_plot) > 0
    sst = ncread(fi_orbit_1, 'regridded_sst');
    [grad_at_per_pixel, grad_as_per_pixel] = Sobel(sst);
    grad_mag_per_pixel = sqrt(grad_as_per_pixel.^2 + grad_at_per_pixel.^2);
    
    [grad_at_per_km, grad_as_per_km, grad_mag_per_km] = sobel_gradient_degrees_per_kilometer(sst, along_track_seps_array, along_scan_seps_array);
    
    sst_in = ncread(fi_orbit_1, 'SST_In_masked');
    [grad_at_in_per_km, grad_as_in_per_km, grad_mag_in_per_km] = sobel_gradient_degrees_per_kilometer(sst_in, along_track_seps_array, along_scan_seps_array);
    
    grad_ang = atand( grad_as_per_km ./ grad_at_per_km);
    grad_ang_in = atand( grad_as_in_per_km ./ grad_at_in_per_km);
    
    % Only construct track_angle if this is not a netCDF run. If the latter
    % it would have been read in already.
    
    if abs(wheres_the_data_to_plot) == 2
        track_angle = mean_az_final - 90;
    end
    
    % cos_az = cos(mean_az_final);
    % sin_az = sin(mean_az_final);
    
    grad_lon_per_km = grad_at_per_km .* cosd(track_angle) - grad_as_per_km .* sind(track_angle);
    grad_lat_per_km = grad_at_per_km .* sind(track_angle) + grad_as_per_km .* cosd(track_angle);
    
    xx = repmat( [1:size(sst,1)]', 1, size(sst,2));
    yy = repmat( [1:size(sst,2)], size(sst,1), 1);
    
    % Define a zoomed-in area, the colorbar to use for this area and a focus
    % point in the area for the calculation of gradients.
    
    si1 = 1285;
    si2 = 1335;
    sj1 = 15560;
    sj2 = 15850;
    
    CAXIS_ZOOM = [8 22];
    
    it = 1316;
    jt = 15774;
    
    % And manually calculate the gradients for the selected point.
    
    pcc_grad_as_per_pixel = ((17.665 + 2*17.520 + 17.480) - (14.625 + 2*14.025 + 13.795)) / 8;
    pcc_grad_at_per_pixel = ((13.795 + 2*16.385 + 17.480) - (14.625 + 2*17.285 + 17.665)) / 8;
    
    % % %     mean_as_pt = mean(mean_sas(it-1:it+1,jt-1:jt+1),'all');
    % % %     mean_at_pt = mean(mean_sat(it-1:it+1,jt-1:jt+1),'all');
    mean_as_pt = mean(along_scan_seps_array(it-1:it+1,jt-1:jt+1),'all');
    mean_at_pt = mean(along_track_seps_array(it-1:it+1,jt-1:jt+1),'all');
    pcc_grad_as_per_km = ((17.665 + 2*17.520 + 17.480) - (14.625 + 2*14.025 + 13.795)) / 8 / 3.69;
    pcc_grad_at_per_km = ((13.795 + 2*16.385 + 17.480) - (14.625 + 2*17.285 + 17.665)) / 8;
end

%% Print info for a small test area.

% % % fprintf('\n\nSST(%3i:%3i, %3i:%3i) \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n', it-1, it+1, jt-1, jt+1, sst(it-1:it+1, jt-1:jt+1))
% % % fprintf('Along-scan Separation(%3i:%3i, %3i:%3i) \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n', it-1, it+1, jt-1, jt+1, mean_sas(it-1:it+1, jt-1:jt+1))
% % % fprintf('Along-track Separation(%3i:%3i, %3i:%3i) \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n', it-1, it+1, jt-1, jt+1, mean_sat(it-1:it+1, jt-1:jt+1))
fprintf('\n\nSST(%3i:%3i, %3i:%3i) \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n', it-1, it+1, jt-1, jt+1, sst(it-1:it+1, jt-1:jt+1))
fprintf('Along-scan Separation(%3i:%3i, %3i:%3i) \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n', it-1, it+1, jt-1, jt+1, along_scan_seps_array(it-1:it+1, jt-1:jt+1))
fprintf('Along-track Separation(%3i:%3i, %3i:%3i) \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n \t%6.3f %6.3f %6.3f \n', it-1, it+1, jt-1, jt+1, along_track_seps_array(it-1:it+1, jt-1:jt+1))

g_at_per_pixel = ( (sst(it+1,jt-1) + 2 * sst(it+1,jt) + sst(it+1,jt+1)) -  (sst(it-1,jt-1) + 2 * sst(it-1,jt) + sst(it-1,jt+1)) ) / 8;
g_as_per_pixel = ( (sst(it-1,jt+1) + 2 * sst(it,jt+1) + sst(it+1,jt+1)) -  (sst(it-1,jt-1) + 2 * sst(it,jt-1) + sst(it+1,jt-1)) ) / 8;

g_at_per_km = ( (sst(it+1,jt-1) + 2 * sst(it+1,jt) + sst(it+1,jt+1)) -  (sst(it-1,jt-1) + 2 * sst(it-1,jt) + sst(it-1,jt+1)) ) / (8 * 1);
g_as_per_km = ( (sst(it-1,jt+1) + 2 * sst(it,jt+1) + sst(it+1,jt+1)) -  (sst(it-1,jt-1) + 2 * sst(it,jt-1) + sst(it+1,jt-1)) ) / (8 * 3.64);


fprintf('\n Hand calculated gradient at (%3i, %3i) is (%6.4f, %6.4f) K/pixel \n', it+1, jt+1, pcc_grad_as_per_pixel, pcc_grad_at_per_pixel)
fprintf('\n Hand calculated gradient at (%3i, %3i) is (%6.4f, %6.4f) K/pixel \n', it+1, jt+1, g_at_per_pixel, g_as_per_pixel)

fprintf('\n Hand calculated gradient at (%3i, %3i) is (%6.4f, %6.4f) K/km \n', it+1, jt+1, pcc_grad_as_per_km,  pcc_grad_at_per_km)
fprintf('\n Hand calculated gradient at (%3i, %3i) is (%6.4f, %6.4f) K/km \n', it+1, jt+1, g_as_per_km, g_at_per_km)

fprintf('\n Computer calculated gradient magnitude at (%3i, %3i) is (%6.4f, %6.4f) K/km \n', ...
    it, jt, grad_mag_per_km(it,jt), grad_mag_per_km(it,jt))

fprintf('\n Computer calculated gradient vector (as, at) at (%3i, %3i) is (%6.4f, %6.4f) K/pixel \n', ...
    it, jt, grad_as_per_pixel(it,jt), grad_at_per_pixel(it,jt))

fprintf('\n Computer calculated gradient vector (as, at) at (%3i, %3i) is (%6.4f, %6.4f) K/km \n', ...
    it, jt, grad_as_per_km(it,jt), grad_at_per_km(it,jt))

%% Histogram the gradients in the selected region.

% 101 - Histograms of gradient magnitudes of original and fixed SST for selected area.
% 102 - Histograms of gradient magnitudes of original and fixed SST for entire orbit.
% 103 - Histograms of along-scan and along-track gradients for fixed SST for selected area.
% 104 - Histograms of along-scan and along-track gradients for fixed SST for entire orbit.
% 105 - Histograms of along-scan gradients for swath edge vs center of swath for fixed SST for selected area.
% 106 - Histograms of along-track gradients for swath edge vs center of swath for fixed SST for selected area.
% 107 - Histograms of along-scan gradients for left swath edge vs right swath edge for fixed SST for selected area.
% 108 - Histograms of along-track gradients for left swath edge vs right swath edge fixed SST for selected area.

if plot_control_100s
    
    % Start with histograms for selected area.
    
    TITLE = ['|\nabla{SST(}' num2str(si1) ':' num2str(si2) ', ' num2str(sj1) ':' num2str(sj2) ')|'];
    Var1_Legend = '|\nabla{SST}| for Fixed SST';
    Var2_Legend = '|\nabla{SST}| for Original SST';
    histogram_results( plot_control(101), grad_mag_per_km, grad_mag_in_per_km, [si1 si2 sj1 sj2], [0:0.01:0.6], 'K/km', Var1_Legend, Var2_Legend, TITLE);
    
    TITLE = '\nabla{SST(:)}';
    Var1_Legend = '|\nabla{SST}| for Fixed SST';
    Var2_Legend = '|\nabla{SST}| for Original SST';
    histogram_results( plot_control(102), grad_mag_per_km, grad_mag_in_per_km, [], [0:0.01:0.6], 'K/km', Var1_Legend, Var2_Legend, TITLE);
    
    % Now for along-scan and along-track histograms.
    
    TITLE = ['\nabla{SST(}' num2str(si1) ':' num2str(si2) ', ' num2str(sj1) ':' num2str(sj2) ')'];
    Var1_Legend = '\nabla_{Along-Scan}SST for Fixed SST';
    Var2_Legend = '\nabla_{Along-Track}SST for Fixed SST';
    histogram_results( plot_control(103), grad_as_per_km, grad_mag_in_per_km, [si1 si2 sj1 sj2], [-0.3:0.01:0.3], 'K/km', Var1_Legend, Var2_Legend, TITLE);
    
    TITLE = '\nabla{SST(:)}';
    Var1_Legend = '\nabla_{Along-Scan}SST for Fixed SST';
    Var2_Legend = '\nabla_{Along-Track}SST for Fixed SST';
    histogram_results( plot_control(104), grad_as_per_km, grad_mag_in_per_km, [], [-0.3:0.01:0.3], 'K/km', Var1_Legend, Var2_Legend, TITLE);
    
    % Next near the swath edge versus near the center of the track for components.
    
    TITLE = '\nabla_{Along-Scan}SST';
    Var1_Legend = 'Elements 0 to 50 - Swath Edge';
    Var2_Legend = 'Elements 652 to 702 - Center of Scan';
    histogram_results( plot_control(105), grad_as_per_km, grad_at_per_km, ...
        [1 50 1 size(grad_as_per_km,2); ...
        size(grad_as_per_km,1)/2-25 size(grad_as_per_km,1)/2+25 1 size(grad_as_per_km,2)], [-0.3:0.01:0.3], 'K/km', Var1_Legend, Var2_Legend, TITLE);
    
    TITLE = '\nabla_{Along-Track}SST';
    Var1_Legend = 'Elements 0 to 50 - Swath Edge';
    Var2_Legend = 'Elements 652 to 702 - Center of Scan';
    histogram_results( plot_control(106), grad_at_per_km, grad_at_per_km, ...
        [1 50 1 size(grad_at_per_km,2); ...
        size(grad_at_per_km,1)/2-25 size(grad_at_per_km,1)/2+25 1 size(grad_at_per_km,2)], [-0.3:0.01:0.3], 'K/km', Var1_Legend, Var2_Legend, TITLE);
    
    % Finally compare gradients from one swath edge to the other for components.
    
    TITLE = '\nabla_{Along-Scan}SST';
    Var1_Legend = 'Elements 0 to 50 - Swath Edge';
    Var2_Legend = 'Elements 1329 to 1354 - Center of Scan';
    histogram_results( plot_control(107), grad_as_per_km, grad_at_per_km, ...
        [1 50 1 size(grad_as_per_km,2); ...
        size(grad_as_per_km,1)/2-25 size(grad_as_per_km,1)/2+25 1 size(grad_as_per_km,2)], [-0.3:0.01:0.3], 'K/km', Var1_Legend, Var2_Legend, TITLE);
    
    TITLE = '\nabla_{Along-Track}SST';
    Var1_Legend = 'Elements 0 to 50 - Swath Edge';
    Var2_Legend = 'Elements 1329 to 1354 - Center of Scan';
    histogram_results( plot_control(108), grad_at_per_km, grad_at_per_km, ...
        [1 50 1 size(grad_at_per_km,2); ...
        size(grad_at_per_km,1)-50 size(grad_at_per_km,1) 1 size(grad_at_per_km,2)], [-0.3:0.01:0.3], 'K/km', Var1_Legend, Var2_Legend, TITLE);
    
end

%% SST with gradients plots zoomed in on selected region in satellite coordinates

% 201 - SST plus gradients in K/pixel zoomed in on it, jt with components for that point.
% 202 - SST plus gradients in K/km zoomed in on it, jt with components for that point.
% 203 - Gradient magnitude of SST for the fixed field zoomed in on it, jt.
% 204 - Gradient magnitude of SST for the original field zoomed in on it, jt.

if plot_control_200s
    
    window_size = 7; % Half size of zoom area in pixels; i.e., will show 15x15 pixel region if set to 7.
    
    % Plot SST for fixed field in satellite coordinates with Sobel gradients in K/pixel
    
    if plot_control(201) ~= 0
        myTITLE = ['SST with \nabla{SST} (K/pixel) in Satellite Coordinates'];
        plot_image( plot_control(201), [], [], sst', [], [], [], myTITLE)
        hold on
        
        % Plot the gradient vectors
        
        qq = quiver( xx, yy, grad_as_per_pixel, grad_at_per_pixel, 'k');
        qq.MaxHeadSize = 0.000015;
        qq.LineWidth = 2;
        qq.AutoScale = 'off';
        
        q1_mag_per_pixel = quiver( xx(it,jt), yy(it,jt), grad_as_per_pixel(it,jt), grad_at_per_pixel(it,jt), 'g');
        q1_mag_per_pixel.MaxHeadSize = 0.2;
        q1_mag_per_pixel.LineWidth = 2;
        q1_mag_per_pixel.AutoScale = 'off';
        
        q1_at_per_pixel = quiver( xx(it,jt), yy(it,jt), 0, grad_at_per_pixel(it,jt), 'k');
        q1_at_per_pixel.MaxHeadSize = 1;
        q1_at_per_pixel.LineWidth = 2;
        q1_at_per_pixel.AutoScale = 'off';
        
        q1_as_per_pixel = quiver( xx(it,jt), yy(it,jt), grad_as_per_pixel(it,jt), 0, 'm');
        q1_as_per_pixel.MaxHeadSize = 0.2;
        q1_as_per_pixel.LineWidth = 2;
        q1_as_per_pixel.AutoScale = 'off';
        
        axis equal
        window_size = 7;
        axis([it-window_size it+window_size jt-window_size jt+window_size])
        set(gca,ydir='normal')
        caxis(CAXIS_ZOOM)
        
        % Light up the pixels around the point of interest
        
        p1 = plot([1 1 1]*(it-1),[jt-1:jt+1],'ok', markerfacecolor='k', markersize=10);
        p2 = plot(it,jt,'ok', markerfacecolor='w', markersize=10);
        p3 = plot([1 1 1]*(it+1),[jt-1:jt+1],'ok', markerfacecolor='c', markersize=10);
        p4 = plot( it+1, jt+1,'ok', markerfacecolor='m', markersize=10);
        
        legend([p1 p2 p3 p4 q1_mag_per_pixel q1_at_per_pixel q1_as_per_pixel], ...
            {['(' num2str(it-1) ', ' num2str(jt-1) '-' num2str(jt+1) ')'] ['(' num2str(it) ', ' num2str(jt) ')'] ...
            ['(' num2str(it+1) ', ' num2str(jt-1) '-' num2str(jt) ')'] ['(' num2str(it+1) ', ' num2str(jt+1) ')'] ...
            '|\nabla SST| (K/pixel)' 'Along-track \nabla SST (K/pixel)' 'Along-scan \nabla SST (K/pixel)'})
    end
    
    % Plot SST for fixed field in satellite coordinates with Sobel gradients in K/km
    
    if plot_control(202) ~= 0
        myTITLE = ['SST with \nabla{SST} (K/km) in Satellite Coordinates'];
        plot_image( plot_control(202), [1:size(sst,1)], [1:size(sst,2)], sst', [], [], [], myTITLE)
        hold on
        
        % Plot the gradient vectors
        
        q1 = quiver( xx, yy, grad_as_per_km, grad_at_per_km, 'k');
        q1.MaxHeadSize = 0.000015;
        q1.LineWidth = 2;
        q1.AutoScale = 'off';
        
        q1_mag_per_km = quiver( xx(it,jt), yy(it,jt), grad_as_per_km(it,jt), grad_at_per_km(it,jt), 'g');
        q1_mag_per_km.MaxHeadSize = 0.2;
        q1_mag_per_km.LineWidth = 2;
        q1_mag_per_km.AutoScale = 'off';
        
        q1_at_per_km = quiver( xx(it,jt), yy(it,jt), 0, grad_at_per_km(it,jt), 'b');
        q1_at_per_km.MaxHeadSize = 1;
        q1_at_per_km.LineWidth = 2;
        q1_at_per_km.AutoScale = 'off';
        
        q1_as_per_km = quiver( xx(it,jt), yy(it,jt), grad_as_per_km(it,jt), 0, 'm');
        q1_as_per_km.MaxHeadSize = 0.2;
        q1_as_per_km.LineWidth = 2;
        q1_as_per_km.AutoScale = 'off';
        
        axis equal
        axis([it-window_size it+window_size jt-window_size jt+window_size])
        set(gca,ydir='normal')
        caxis(CAXIS_ZOOM)
        
        % Light up the pixels around the point of interest
        
        p1 = plot([1 1 1]*(it-1),[jt-1:jt+1],'ok', markerfacecolor='k', markersize=10);
        p2 = plot(it,jt,'ok', markerfacecolor='w', markersize=10);
        p3 = plot([1 1 1]*(it+1),[jt-1:jt+1],'ok', markerfacecolor='c', markersize=10);
        p4 = plot( it+1, jt+1,'ok', markerfacecolor='m', markersize=10);
        
        legend([p1 p2 p3 p4 q1_mag_per_km q1_at_per_km q1_as_per_km], ...
            {['(' num2str(it-1) ', ' num2str(jt-1) '-' num2str(jt+1) ')'] ['(' num2str(it) ', ' num2str(jt) ')'] ...
            ['(' num2str(it+1) ', ' num2str(jt-1) '-' num2str(jt) ')'] ['(' num2str(it+1) ', ' num2str(jt+1) ')'] ...
            '|\nabla SST| (K/pixel)' 'Along-track \nabla SST (K/km)' 'Along-scan \nabla SST (K/km)'})
        
        % Plot gradiend magnitudes for fixed and input fields in satellite coordinates
        
        CAXIS_ZOOM_GRADIENTS = [0 2];
        
        window_size = 100; % Half size of zoom area in pixels; i.e., will show 201x201 pixel region if set to 100.
        
        itl = it - window_size;
        if itl <= 0
            itl = 1;
        end
        itr = itl + 2 * window_size;
        if itr > size(grad_mag_per_km,1)
            itr = size(grad_mag_per_km,1);
            itl = itr - 2 * window_size;
        end
        
        jtl = jt - window_size;
        if jtl <= 0
            jtl = 1;
        end
        jtu = jtl + 2 * window_size;
        if jtu > size(grad_mag_per_km,2)
            jtu = size(grad_mag_per_km,2);
            jtl = jtu - 2 * window_size;
        end
    end
    
    % For the fixed SST field.
    
    if plot_control(203) ~= 0
        myTITLE = ['|\nabla SST_{fixed}|'];
        plot_image( plot_control(203), [], [], grad_mag_per_km', [], [], [], myTITLE)
        
        axis equal
        axis([itl itr jtl jtu])
        set(gca,ydir='normal')
        caxis(CAXIS_ZOOM_GRADIENTS)
        
        % Now for the original SST field.
        myTITLE = ['|\nabla SST_{in}|'];
    end
    
    
    if plot_control(204) ~= 0
        plot_image( plot_control(204), [], [], grad_mag_in_per_km', [], [], [], myTITLE)
        
        axis equal
        axis([itl itr jtl jtu])
        set(gca,ydir='normal')
        caxis(CAXIS_ZOOM_GRADIENTS)
    end
end

%% SST with gradients plots zoomed in on selected region in geographic coordinates

% 301 - SST plus gradients in K/pixel zoomed in on it, jt with components for that point.
% 302 - SST plus gradients in K/km zoomed in on it, jt with components for that point.
% 303 - Gradient magnitude of SST for the fixed field zoomed in on it, jt.
% 304 - Gradient magnitude of SST for the original field zoomed in on it, jt.

if plot_control_300s
    
    %%
    window_size = 9; % Half size of zoom area in pixels; i.e., will show 15x15 pixel region if set to 7.
    
    % Plot SST, grad SST for fixed field in geo coordinates with gradients.
    
    myTITLE = ['SST with \nabla{SST} (K/km)'];
    pcolor_image( plot_control(301), longitude, latitude, sst, [], myTITLE)
    hold on
    
    % Light up the pixels around the focus point and zoom in to surrounding area.
    
    lon_local = longitude(it-1:it+1,jt-1:jt+1) + (longitude(it+1,jt+1) - longitude(it,jt)) / 2;
    lat_local = latitude(it-1:it+1,jt-1:jt+1) + (latitude(it+1,jt+1) - latitude(it,jt)) / 2;
    
    p1 = plot( lon_local(1,:), lat_local(1,:), 'ok', markerfacecolor='k', markersize=10);
    p2 = plot( lon_local(2,2), lat_local(2,2),'ok', markerfacecolor='w', markersize=10);
    p3 = plot( lon_local(end,:), lat_local(end,:), 'ok', markerfacecolor='c', markersize=10);
    p4 = plot( lon_local(end,end), lat_local(end,end),'ok', markerfacecolor='m', markersize=10);
    
    lon_left = min(longitude(it-window_size:it+window_size,jt-window_size:jt+window_size), [], 'All');
    lon_right = max(longitude(it-window_size:it+window_size,jt-window_size:jt+window_size), [], 'All');
    lon_range = lon_right - lon_left;
    
    lat_mean = mean(latitude(it-window_size:it+window_size,jt-window_size:jt+window_size), 'All');
    lat_lower = lat_mean - lon_range * cosd(lat_mean) / 2;
    lat_upper = lat_mean + lon_range * cosd(lat_mean) / 2;
    axis([lon_left lon_right lat_lower lat_upper])
    axis square
    
    caxis(CAXIS_ZOOM)
    
    % Get lon and lat arrays for where gradients are to be plotted and plot the gradient vectors
    
    lon_shifted_1 = longitude(2:end, 2:end);
    lon_shifted_2 = [lon_shifted_1; lon_shifted_1(end,:)];
    lon_shifted = [lon_shifted_2 lon_shifted_2(:,end)];
    lon_plot = longitude + (lon_shifted - longitude) / 2;
    
    clear lon_shifted*
    
    lat_shifted_1 = latitude(2:end, 2:end);
    lat_shifted_2 = [lat_shifted_1; lat_shifted_1(end,:)];
    lat_shifted = [lat_shifted_2 lat_shifted_2(:,end)];
    lat_plot = latitude + (lat_shifted - latitude) / 2;
    
    clear lat_shifted*
    
    q2 = quiver( lon_plot, lat_plot, grad_lon_per_km, grad_lat_per_km, 'k', MaxHeadSize = 0.00005, LineWidth = 2, AutoScale = 'on');
    
    % First, plot the components of the along-track and along-scan gradients
    % in lat,lon space. Start by getting them.
    
    glon_at = grad_at_per_km(it,jt) * cosd(track_angle(it,jt));
    glat_at = grad_at_per_km(it,jt) * sind(track_angle(it,jt));
    
    glon_as = -grad_as_per_km(it,jt) * sind(track_angle(it,jt));
    glat_as = grad_as_per_km(it,jt) * cosd(track_angle(it,jt));
    
    % Now plot them.
    
    q2_at_per_km = quiver( lon_local(2,2), lat_local(2,2), glon_at, glat_at, 'c', LineWidth=1, MaxHeadSize = 0.1, AutoScale='on', AutoScaleFactor = 0.5);
    q2_as_per_km = quiver( lon_local(2,2), lat_local(2,2), glon_as, glat_as, 'm', LineWidth=1, MaxHeadSize = 0.1, AutoScale='on', AutoScaleFactor = 0.5);
    
    q2_mag_as_at_per_km = quiver( lon_local(2,2), lat_local(2,2), glon_at+glon_as, glat_at+glat_as, color=[0.7 0.7 0.7], LineWidth=2, MaxHeadSize = 0.1, AutoScale='on', AutoScaleFactor = 0.5);
    
    % Next do the same for the lat,lon components.
    
    glon = grad_at_per_km(it,jt) * cosd(track_angle(it,jt)) - grad_as_per_km(it,jt) * sind(track_angle(it,jt));
    glat = grad_at_per_km(it,jt) * sind(track_angle(it,jt)) + grad_as_per_km(it,jt) * cosd(track_angle(it,jt));
    
    q2_lon_per_km = quiver( lon_local(2,2), lat_local(2,2), glon, 0, 'b', LineWidth=2, MaxHeadSize = 0.1, AutoScale='on', AutoScaleFactor = 0.5);
    q2_lat_per_km = quiver( lon_local(2,2), lat_local(2,2), 0, glat, 'g', LineWidth=2, MaxHeadSize = 0.1, AutoScale='on', AutoScaleFactor = 0.5);
    
    q2_mag_lat_lon_per_km = quiver( lon_local(2,2), lat_local(2,2), glon, glat, 'c', LineWidth=2, MaxHeadSize = 0.1, AutoScale='on', AutoScaleFactor = 0.5);
    
    legend([p1 p2 p3 p4 q2_at_per_km q2_as_per_km q2_lon_per_km q2_lat_per_km q2_mag_lat_lon_per_km], ...
        {['(' num2str(it-1) ', ' num2str(jt-1) '-' num2str(jt+1) ')'] ['(' num2str(it) ', ' num2str(jt) ')'] ...
        ['(' num2str(it+1) ', ' num2str(jt-1) '-' num2str(jt) ')'] ['(' num2str(it+1) ', ' num2str(jt+1) ')'] ...
        'Along-track \nabla SST (K/km)' 'Along-scan \nabla SST (K/km)' 'Eastward \nabla SST (K/km)' 'Northward \nabla SST (K/km)' '|\nabla SST| (K/pixel)'})
    
    % Plot the gradient vectors
    
    q2 = quiver( xx, yy, grad_as_per_pixel, grad_at_per_pixel, 'k');
    q2.MaxHeadSize = 0.000015;
    q2.LineWidth = 2;
    q2.AutoScale = 'off';
    
    q2_mag_per_pixel = quiver( xx(it,jt), yy(it,jt), grad_mag_per_pixel(it,jt), grad_at_per_pixel(it,jt), 'g');
    q2_mag_per_pixel.MaxHeadSize = 0.2;
    q2_mag_per_pixel.LineWidth = 2;
    q2_mag_per_pixel.AutoScale = 'off';
    
    q2_at_per_pixel = quiver( xx(it,jt), yy(it,jt), 0, grad_at_per_pixel(it,jt), 'k');
    q2_at_per_pixel.MaxHeadSize = 1;
    q2_at_per_pixel.LineWidth = 2;
    q2_at_per_pixel.AutoScale = 'off';
    
    q2_as_per_pixel = quiver( xx(it,jt), yy(it,jt), grad_as_per_pixel(it,jt), 0, 'w');
    q2_as_per_pixel.MaxHeadSize = 0.2;
    q2_as_per_pixel.LineWidth = 2;
    q2_as_per_pixel.AutoScale = 'off';
    
    axis equal
    window_size = 7;
    axis([it-window_size it+window_size jt-window_size jt+window_size])
    set(gca,ydir='normal')
    caxis(CAXIS_ZOOM)
    
    % Light up the pixels around the point of interest
    
    p1 = plot([1 1 1]*(it-1),[jt-1:jt+1],'ok', markerfacecolor='k', markersize=10);
    p2 = plot(it,jt,'ok', markerfacecolor='w', markersize=10);
    p3 = plot([1 1 1]*(it+1),[jt-1:jt+1],'ok', markerfacecolor='c', markersize=10);
    p4 = plot( it+1, jt+1,'ok', markerfacecolor='m', markersize=10);
    
    legend([p1 p2 p3 p4], {['(' num2str(it-1) ', ' num2str(jt-1) '-' num2str(jt+1) ')'] ['(' num2str(it) ', ' num2str(jt) ')'] ['(' num2str(it+1) ', ' num2str(jt-1) '-' num2str(jt) ')'] ['(' num2str(it+1) ', ' num2str(jt+1) ')']})
    
    myTITLE = ['SST_{in}(' num2str(si1), ':'  num2str(si2), ','  num2str(sj1), ':'  num2str(sj2), ')'];
    pcolor_image( 301, longitude, latitude, sst_in, [], myTITLE)
    
    myTITLE = ['|\nabla SST| (' num2str(si1), ':'  num2str(si2), ','  num2str(sj1), ':'  num2str(sj2), ')'];
    pcolor_image( 302, longitude, latitude, grad_mag_per_km, [], myTITLE)
    
    myTITLE = ['|\nabla SST_{in}| (' num2str(si1), ':'  num2str(si2), ','  num2str(sj1), ':'  num2str(sj2), ')'];
    pcolor_image( 303, longitude, latitude, grad_mag_in_per_km, [], myTITLE)
    
    %% Plot SST, grad SST for fixed and input fields in geo coordinates
    
    myTITLE = ['\nabla_at SST (' num2str(si1), ':'  num2str(si2), ','  num2str(sj1), ':'  num2str(sj2), ')'];
    pcolor_image( 304, longitude, latitude, grad_at_per_km, [], myTITLE)
    
    myTITLE = ['\nabla_as SST (' num2str(si1), ':'  num2str(si2), ','  num2str(sj1), ':'  num2str(sj2), ')'];
    pcolor_image( 305, longitude, latitude, grad_as_per_km, [], myTITLE)
    
    pcolor_image( 306, longitude, latitude, grad_lon_per_km, [], '\nabla_{lon} SST')
    pcolor_image( 307, longitude, latitude, grad_lat_per_km, [], '\nabla_{lat} SST')
end