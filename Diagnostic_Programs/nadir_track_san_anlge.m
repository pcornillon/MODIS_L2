% nadir_track_scan_angle - script to determine this angle - PCC
% 
% I chose granules near the equator so that I didn't have to worry about
% change in kms per degree of longitude. The angle determined may change
% aroung the orbit but this code will show the basic idea.

% Granule in 2010 or 2003. 

GranuleIn2010 = false;

if GranuleIn2010
    EqIndex = 1300;
    fi = '/Volumes/Data_1/MODIS_L2/combined/2010/AQUA_MODIS.20100619T045008.L2.SST.nc';
else
    EqIndex = 1750;
    fi = '/Volumes/Data_1/MODIS_L2/combined/2003/AQUA_MODIS.20030101T002505.L2.SST.nc';
end

% Get the longitude, latitude and time.

Lon = ncread( fi, '/navigation_data/longitude');
Lat = ncread( fi, '/navigation_data/latitude');

millisecond = ncread( fi, '/scan_line_attributes/msec');

% Plot the basics of this granule.

figure(1)
plot(Lon(677,:), Lat(677,:), '.b')
hold on
plot(Lon(:,EqIndex), Lat(:,EqIndex), '.r')
axis square

% Now get lats and lons near the equator and the center of the scan line.

EqIndexPlus1 = EqIndex + 1;
EqIndexPlus5 = EqIndex + 5;
EqIndexPlus10 = EqIndex + 10;

Lat1s = Lat(671,EqIndexPlus5);
Lat2s = Lat(682,EqIndexPlus5);
Lon1s = Lon(671,EqIndexPlus5);
Lon2s = Lon(682,EqIndexPlus5);

Lat1n = Lat(677,EqIndexPlus1);
Lat2n = Lat(677,EqIndexPlus10);
Lon1n = Lon(677,EqIndexPlus1);
Lon2n = Lon(677,EqIndexPlus10);

% And get the slopes.

nadir_slope = (Lat1n - Lat2n) / (Lon1n - Lon2n);
scan_slope = (Lat2s - Lat1s) / (Lon2s - Lon1s);

fprintf('Nadir slope: %6.2f, Scan line slope: %6.2f, -1 / ( line slope): %6.2f\n', nadir_slope, scan_slope, -1/scan_slope)

% Next calculate the location of the latitude on near the scan line, which
% defines a line that crosses the nadir track at 90 degrees.

Lat2sp = Lat1s - (Lon2s - Lon1s) * (Lon1n - Lon2n) / (Lat1n - Lat2n);

% [(Lat2sp-Lat1s)/(Lon2s-Lon1s) (Lat1n-Lat2n)/(Lon1n-Lon2n)]
% [(Lat2sp-Lat1s)/(Lon2s-Lon1s) -1/((Lat1n-Lat2n)/(Lon1n-Lon2n))]

% Plot zoomed in on the new line.

figure(2)
plot( [Lon1n Lon2n], [Lat1n Lat2n], 'k')
hold on
plot( [Lon1s Lon2s], [Lat1s Lat2s], 'k')
axis equal
plot( [Lon2s Lon1s], [Lat2sp Lat1s], 'r')

% And the last point in the previous group of 10 detectors.

plot( Lon(677,EqIndex), Lat(677,EqIndex), '.r', markersize=5)

% Determine the offset of consequtive groups of 10 detectors.

dend = (Lat2sp - Lat2s) * 111;
dlen = sqrt( (Lon1s - Lon2s).^2 + (Lat1s - Lat2s).^2) * 111;
dGroupOf10 = sqrt( (Lon1n - Lon2n).^2 + (Lat1n - Lat2n).^2) * 111;

offset = dend * (dGroupOf10/0.9) / dlen;

% But the group of 10 detectors is no parallel to the nadir track so the
% actual offet is much more than this. Let's calculate it. Extending the
% line defined by the group of 10 we have been working with to the latitude
% of the last point in the previous group we find LonNew for which:
%
% (LonNew - Lon1n) / (Lat(677,EqIndex) - Lat1n) = (Lon2n - Lon1n) / (Lat2n - Lat1n)


LonNew = Lon1n + (Lat(677,EqIndex) - Lat1n) * (Lon2n - Lon1n) / (Lat2n - Lat1n);

NewOffset = (LonNew - Lon(677,EqIndex)) * 111;

fprintf('The offset of subsequent groups of 10 is %6.2f meters.\n', NewOffSet * 1000)

