% debug_gradient_angles - script to help sort out the rotation from along_scan to eastward - PCC
%
% Put a break point in line 762 of build_and_fix_orbits for 
% Run submit_a_job( [2010 6 19 5 0 0], [2010 6 19 7 30 0])
% Should stop with:
%
% oinfo(iOrbit)
% 
% ans = 
% 
%   struct with fields:
% 
%                       name: '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/output/2010/06/AQUA_MODIS_orbit_43221_20100619T051536_L2_SST.nc4'
%                 start_time: 7.3431e+05
%                   end_time: 7.3431e+05
%               orbit_number: 43221
%         data_global_attrib: []
%                      ginfo: [1×20 struct]
%        time_to_build_orbit: 21.9313
%           time_to_fix_mask: 123.8143
%     time_to_address_bowtie: 360.3429
%
% We will look at the gradients at element 837, 9042
%

% Need to get the track_angle array, which was deleted in build_and_fix...
% to save space

load(gradient_filename)

% Now locate the region to test the gradients.

scanc = 837;
trackc = 9042;

scanrl = scanc - rem(scanc,100) - 100;
scanru = scanrl + 200;

trackrl = trackc - rem(trackc,100) - 100;
trackru = trackrl + 200;

lonc = regridded_longitude(scanc,trackc);
latc = regridded_latitude(scanc,trackc);

lon_scan_p20 = regridded_longitude(scanc+20,trackc);
lat_scan_p20 = regridded_latitude(scanc+20,trackc);

lon_track_p20 = regridded_longitude(scanc,trackc+20);
lat_track_p20 = regridded_latitude(scanc,trackc+20);

% Plot orbit in scan,track coordinate system and locate 3 points to
% indicate the direction of scan elements (blue to red) and track elements
% (blue to yellow).

figure(1)

imagesc(regridded_sst')
caxis([27 29])
axis([scanrl scanru trackrl trackru])

hold on
plot( scanc, trackc, 'ko', markersize=10, markerfacecolor='b')
plot( scanc+20, trackc, 'ko', markersize=10, markerfacecolor='r')
plot( scanc, trackc+20, 'ko', markersize=10, markerfacecolor='m')

axis([700 1000 8900 9200])

% Plot the orbit in lat, lon coordinate system. 

figure(2)

pcolor( regridded_longitude, regridded_latitude, regridded_sst); shading flat; caxis([27 30]); axis equal; axis([118 123 -19 -17])

hold on
plot( lonc, latc, 'ko', markersize=10, markerfacecolor='b')
plot( lon_scan_p20, lat_scan_p20, 'ko', markersize=10, markerfacecolor='r')
plot( lon_track_p20, lat_track_p20, 'ko', markersize=10, markerfacecolor='y')

% Assign variables to make equations easier to follow.

asc = grad_as_per_km(scanc,trackc);
atc = grad_at_per_km(scanc,trackc);

gmc = sqrt(atc^2 + asc^2);

cosc = cosd(track_angle(scanc,trackc));
sinc = sind(track_angle(scanc,trackc));

ewc = atc * cosc + asc * sinc;
nsc = -atc * sinc + asc * cosc;

[asc atc; ewc nsc; eastward_gradient(scanc,trackc) northward_gradient(scanc,trackc)]

% Now plot vectors.

h1 = quiver( lonc, latc, atc*cosc, -atc*sinc);
h2 = quiver( lonc, latc, atc*cosc, -atc*sinc, 10);
h3 = quiver( lonc, latc, atc*cosc, -atc*sinc, 10, 'r', linewidth=3);
h4 = quiver( lonc, latc, asc*sinc, atc*cosc, 10, 'r', linewidth=3);

h5 = quiver( lonc, latc, gmc*sinc, gmc*cosc, 10, 'w', linewidth=3);

% Make sure that sins and cosines result in different values in the four
% quadrants.

[cosd(45) sind(45); cosd(135) sind(135); cosd(225) sind(225); cosd(315) sind(315)]
