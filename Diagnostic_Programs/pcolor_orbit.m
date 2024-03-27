function pcolor_orbit(iFig, sensorName, filename, longitude, latitude, SST)
% pcolor_orbit - plot an orbit with nadir track, end scans and end pixels - PCC
%
% INPUT
%   iFig: the figure number to use for the plot.
%   sensorName: the name of the sensor from which the data were collected.
%   filename: the name of the file from which the data were derived.
%   Lon: the longitude
%   Lat: the latitude
%   sst: the SST
%
% OUTPUT
%   none

% Load the continental outlines 
 
load coastlines.mat

% Plot the data. Note that the initial plot commands are all put on one
% line. I think that this is faster.

figure(iFig)

pcolor(Lon,Lat,sst); shading flat; colormap(jet); colorbar; hold on; plot(coastlon, coastlat,'k')

% Now add the nadir track, the swath edges and the beginning and end of the
% orbit.

nadirIndex = floor(size(Lon,1) / 2) + 1;

plot(Lon(nadirIndex,:),Lat(nadirIndex,:),'k',linewidth=2)
plot(Lon(1,:),Lat(1,:),'.b',linewidth=2)
plot(Lon(end,:),Lat(end,:),'.g',linewidth=2)
plot(Lon(nadirIndex,:),Lat(nadirIndex,:),'w',linewidth=2)
plot(Lon(nadirIndex,:),Lat(nadirIndex,:),'.k',linewidth=2)
plot(Lon(:,1),Lat(:,1),'g',linewidth=2)
plot(Lon(:,1),Lat(:,1),'w',linewidth=2)
plot(Lon(:,1),Lat(:,1),'.g',linewidth=2)
plot(Lon(:,1),Lat(:,1),'.m',linewidth=2)
plot(Lon(:,1),Lat(:,1),'.c',linewidth=2)
plot(Lon(:,end),Lat(:,end),'.r',linewidth=2)

set(gca, fontsize=20)

nn = strfind(filename, 'orbit_');
orbit = filename(nn+6:nn+11);
year = filename(nn+13:nn+16);
month = filename(nn+17:nn+18);
day = filename(nn+19:nn+20);
hour = filename(nn+22:nn+23);
minute = filename(nn+24:nn+25);

title(['Orbit: ' orbit ' on ' month '/' day '/' year ' at ' hour ':' minute], fontsize=30)