% compare_versions_of_angles_etc - 

fiold = '~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/Separation_and_Angle_Arrays.n4';
finew = '~/Dropbox/Data/MODIS_L2/Data/Separation_and_Angle_Arrays.n4';

% Plot along scan and track separations

iFig = 10;

iFig = iFig + 1;
figure(iFig)
clf

plot(along_scan_seps)
hold on
plot(along_track_seps,'r')

set(gca, fontsize=24);
ylim([0 5])
title('xxx\_seps', fontsize=30)
legend('along\_scan', 'along\_track')

iFig = iFig + 1;
figure(iFig)
clf

plot(along_track_seps)
set(gca, fontsize=24);
title('along\_track\_seps', fontsize=30)

% Plot rms of separation differences

iFig = iFig + 1;
figure(iFig)
clf

plot(rms_along_scan_diff)
hold on
plot(rms_along_track_diff,'r')

set(gca, fontsize=24);
legend('along\_scan', 'along\_track')
title('rms\_xxx\_diff', fontsize=30)

% Plot rms of min data

iFig = iFig + 1;
figure(iFig)
clf

plot(min_rms_along_scan_diff)
hold on
plot(min_rms_along_track_diff,'r')

set(gca, fontsize=24);
legend('along\_scan', 'along\_track')
title('min\_rms\_xxx\_diff', fontsize=30)
xlim([0 41000])

% Plot min and smoothed min factors

iFig = iFig + 1;
figure(iFig)
clf

plot(min_along_scan_factor)
hold on
plot(min_along_track_factor)
plot(smoothed_min_along_scan_factor, 'k')
plot(smoothed_min_along_track_factor,'m')

set(gca, fontsize=24);
legend('along\_scan', 'along\_track','smoothed...along\_scan', 'smoothed...\_along\_track')
title('\_min\_xxx\_factor', fontsize=30)
xlim([0 41000])

% Now for the full separation and angle fields.

iFig = iFig + 1;
figure(iFig)
clf

imagesc(along_track_seps_array')
colormap(jet)
colorbar
set(gca, fontsize=24);
title('along\_track\_seps\_array', fontsize=30)

iFig = iFig + 1;
figure(iFig)
clf

imagesc(along_scan_seps_array')
colormap(jet)
colorbar
set(gca, fontsize=24);
title('along\_scan\_seps\_array', fontsize=30)
fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/';
    gradient_filename = [fixit_directory 'Separation_and_Angle_Arrays.n4'];
    track_angle = ncread( gradient_filename, 'track_angle');

iFig = iFig + 1;
figure(iFig)
clf
imagesc(track_angle')
colormap(jet)
colorbar
set(gca, fontsize=24);
title('along\_scan\_seps\_array', fontsize=30)
fiold = '~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/Separation_and_Angle_Arrays.n4';
title('along\_scan\_seps\_array Old', fontsize=30)

% % % 
% % % 
% % % figure
% % % plot(min_along_scan_factor)
% % % hold on
% % % plot(min_along_track_factor,'r')
% % % figure(3)
% % % figure(5)
% % % figure(6)
% % % set(gca, fontsize=24);
% % % legend('along\_scan', 'along\_track','smoothed...along\_scan', 'smoothed...\_along\_track',)
% % % title('\_min\_xxx\_factor', fontsize=30)
% % % xlim([0 41000])
% % %  legend('along\_scan', 'along\_track','smoothed...along\_scan', 'smoothed...\_along\_track',)
% % %                                                                                             ↑
% % % Invalid expression. When calling a function or indexing a variable, use parentheses. Otherwise, check for mismatched delimiters.
% % % 
% % % legend('along\_scan', 'along\_track','smoothed...along\_scan', 'smoothed...\_along\_track')
% % % title('\_min\_xxx\_factor', fontsize=30)
% % % xlim([0 41000])
% % % hold on
% % % plot(along_track_seps,'r')
% % % ylim([0 5])
% % % title('along\_xxx\_seps', fontsize=30)
% % % legend('along\_scan', 'along\_track')
% % % title('xxx\_seps', fontsize=30)
% % % figure
