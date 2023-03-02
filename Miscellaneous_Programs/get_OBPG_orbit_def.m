% get_OBPG_orbit_def - reads orbit #s, start times for each file and the nadir track.
%
% This script was written to help sort out how NASA (or at least OBPG)
% defines an orbit. The idea is to sort out where the NASA orbit number
% changes. To achieve this I copied the 1st 100 granules of 2002 from the
% day directory into a day_night_2002 directory and merged the 1st 100
% granules from the night directory into the day_night_2002 directory. I
% say merged because some files are repeate; they have both day and night
% pixels in them. The script reads the orbit number, start time and the
% latitude and longitude of the nadir track from the granules in the merged
% set. I then finds the granule in which the orbit number changed. This
% occurs about every 19 to 20 granules. It then makes longitude increase
% monotonically in the lon vector for the 100 granules. Finally, it plots
% the nadir track for the 100 granules, with the portion of the nadir track
% for the 1st granule colored cyan, the 2nd black, the 3rd cyan,... It also
% plots a meatball on the nadir track at the start of the granule for which
% the orbit number changes.
%
% The result is that the orbit number changes for the ascending granule
% that crosses the Equator. I'm guessing that this means that the orbit
% number actually changes when the ascending satellite crosses the Equator.

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
clf

% Plot the nadir track for the first 100 granules.

for i=1:length(latlon_start)
    if rem(i,2) == 0
        plot( Lon(latlon_start(i):latlon_end(i)),  Lat(latlon_start(i):latlon_end(i)), 'k', linewidth=2)
    else
        plot( Lon(latlon_start(i):latlon_end(i)),  Lat(latlon_start(i):latlon_end(i)), 'c', linewidth=2)
    end
    hold on
end

% Plot meatballs at the beginning of each granule for which the orbit
% number changes.

dd = diff(orbit_number);
nn = find(dd>0.5);

for j=1:length(nn)
    plot(Lon(latlon_start(nn(j))), Lat(latlon_start(nn(j))), 'ok', markerfacecolor='r', markersize=10)
end

% Annotate the plot
grid on
plot( [-2000 500], [0 0], 'm')

set(gca,fontsize=16)


% Plot a line at 78 S, the starting point of each of my orbits.

plot( [-2000 500], [-78 -78], 'r')