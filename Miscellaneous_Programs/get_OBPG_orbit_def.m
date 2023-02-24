% get_OBPG_orbit_def - reads orbit #s, start times for each file and the nadir track.
%
% This script was written to help sort out how NASA (or at least OBPG)
% defines an orbit. 

% Get the list of files if not alread in memory.

if exist('filelist') == 0
    filelist = dir( '/Volumes/Aqua-1/MODIS_R2019/day_night_2002/Aqua*');
end

Lat = [];
Lon = [];

for i=1:100
    
    % Get the granule name.
    
    fi = [filelist(i).folder '/' filelist(i).name];
    
    % Read global info.
    
    orbit_number(i) = ncreadatt(fi, '/', 'orbit_number');
    start_time{i} = ncreadatt(fi, '/', 'time_coverage_start');
    
    % Read nadir track info.
    
    latlon_start(i) = length(Lat) + 1;
    
    Lat = [Lat ncread( fi, '/navigation_data/latitude', [677,1], [1,inf])];
    Lon = [Lon ncread( fi, '/navigation_data/longitude', [677,1], [1,inf])];
    
    latlon_end(i) = length(Lat);
end

LonS = Lon;

% Now stretch longitude to make visualization more clear.

dd = diff(Lon);
nn = find(dd>100);

for i=1:length(nn)
    Lon(nn(i)+1:end) = Lon(nn(i)+1:end) - 180;
end

dd = diff(Lon);
nn = find(dd>100);

for i=1:length(nn)
    Lon(nn(i)+1:end) = Lon(nn(i)+1:end) - 180;
end

figure(1)

% for i=1:100
%     plot( Lon(latlon_start(i):latlon_end(i)),  Lat(latlon_start(i):latlon_end(i)), linewidth=2)
%     hold on
% end

for i=1:100
    if rem(i,2) == 0
        plot( Lon(latlon_start(i):latlon_end(i)),  Lat(latlon_start(i):latlon_end(i)), 'k', linewidth=2)
    else
        plot( Lon(latlon_start(i):latlon_end(i)),  Lat(latlon_start(i):latlon_end(i)), 'c', linewidth=2)
    end
    hold on
end

% And plot a meatball at the first point of each new orbit.

dd = diff(orbit_number); 
nn = find(dd>0.5);

for j=1:length(nn)
    plot(Lon(nn(j)), Lat(nn(j)), 'ok', markerfacecolor='r', markersize=10)
end

plot(Lon(nn(1)), Lat(nn(1)), 'ok', markerfacecolor='r', markersize=10)