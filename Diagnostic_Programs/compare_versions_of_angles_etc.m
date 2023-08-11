% compare_versions_of_angles_etc -

anciallary_stuff = 0;

for iVersion=1:2
    
    switch iVersion
        case 1
            iFig = 10;
            fi = '~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/Separation_and_Angle_Arrays.n4';
            TITLE = 'Old ';
            
            var{1,1} = ncread( fi, 'along_scan_seps_array');
            var{2,1} = ncread( fi, 'along_scan_seps_array');
            var{3,1} = ncread( fi, 'track_angle');
            
        case 2
            iFig = 20;
            fi = '~/Dropbox/Data/MODIS_L2/Data/Separation_and_Angle_Arrays.n4';
            TITLE = 'New ';
            
            var{1,2} = ncread( fi, 'along_scan_seps_array');
            var{2,2} = ncread( fi, 'along_scan_seps_array');
            var{3,2} = ncread( fi, 'track_angle');
            
            var1_diff = var{1,1} - var{1,2};
            var2_diff = var{2,1} - var{2,2};
            var3_diff = var{3,1} - var{3,2};
    end
    
    if anciallary_stuff
        
        % Plot along scan and track separations
        
        
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
        
    end
    
    % Now for the full separation and angle fields.
    
    iFig = iFig + 1;
    figure(iFig)
    clf
    
    imagesc(var{1,iVersion}')
    
    colormap(jet)
    colorbar
    set(gca, fontsize=24);
    title('along\_scan\_seps\_array (km)', fontsize=30)
    fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/';
    gradient_filename = [fixit_directory 'Separation_and_Angle_Arrays.n4'];
    track_angle = ncread( gradient_filename, 'track_angle');
    
    %---
    
    iFig = iFig + 1;
    figure(iFig)
    clf
    
    imagesc(var{2,iVersion}')
    
    colormap(jet)
    colorbar
    set(gca, fontsize=24);
    title('along\_track\_seps\_array (km)', fontsize=30)
    
    %---
    
    iFig = iFig + 1;
    figure(iFig)
    clf
    
    imagesc(var{3,iVersion}')
    
    colormap(jet)
    colorbar
    set(gca, fontsize=24);
    title('Angle Counterclockwise from East', fontsize=30)
end

%% Now plot the differences

iFig = 30;

% Now for the full separation and angle fields.

iFig = iFig + 1;
figure(iFig)
clf

imagesc(var1_diff')

colormap(jet)
colorbar
set(gca, fontsize=24);
title('along\_scan\_seps\_array Old - New (km)', fontsize=30)

%---

iFig = iFig + 1;
figure(iFig)
clf

imagesc(var2_diff')

colormap(jet)
colorbar
set(gca, fontsize=24);
title('along\_track\_seps\_array Old - New (km)', fontsize=30)

%---

iFig = iFig + 1;
figure(iFig)
clf

imagesc(var3_diff')

colormap(jet)
colorbar
set(gca, fontsize=24);
title('Angle Old - New Counterclockwise from East', fontsize=30)
