% combine_weights - combine weights from different orbits - PCC
%
% In this function available weights and locations files for which the
% weights (and locations) have been sorted placing the largest weight for a
% location first, second largest second... and limiting the number of
% weights per location to 7 are read in. They are then examined in groups
% of 3 to find all pixels for which the locations are the same for all
% three. These are then put together to form final weights and locations
% arrays for fast regridding.
%

% Initialize variables.

Approach = 3;

num_levels_to_keep = 3;

switch Approach
    case 1
        % Where are the weights and locations files?
        
        filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/*fixed.mat*');
        
        % Read the files -- turns out that the 4th one in the above directory is bad.
        
        jj = 0;
        for ii=[1 2 3 5]
            fi = [filelist(ii).folder '/' filelist(ii).name];
            tt = load(fi);
            
            % Save only the first 3 levels.
            
            jj = jj + 1;
            eval(['wl' num2str(jj) '.locations = tt.augmented_locations(1:num_levels_to_keep,:,:);'])
            eval(['wl' num2str(jj) '.weights = tt.augmented_weights(1:num_levels_to_keep,:,:);'])
        end
        
        % Initialize the final arrays with the second one read in.
        
        augmented_weights = wl3.weights;
        augmented_locations = wl3.locations;
        
        % Reshape weights and locations for later use.
        
        wghts1 = reshape( wl1.weights, [num_levels_to_keep 1354*40271]);
        locs1 = reshape( wl1.locations, [num_levels_to_keep 1354*40271]);
        
        wghts2 = reshape( wl2.weights, [num_levels_to_keep 1354*40271]);
        locs2 = reshape( wl2.locations, [num_levels_to_keep 1354*40271]);
        
        wghts3 = reshape( wl3.weights, [num_levels_to_keep 1354*40271]);
        locs3 = reshape( wl3.locations, [num_levels_to_keep 1354*40271]);
        
        %% Find all pixels for which the locations in two orbits are the same.
        
        groups_of_2 = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
        
        for i=1:size(groups_of_2,1)
            eval(['locsum = wl' num2str(groups_of_2(i,1)) '.locations;'])
            
            for ii=groups_of_2(i,2:end)
                eval(['locsum = locsum - wl' num2str(ii) '.locations;'])
            end
            
            % Sum over levels.
            
            locsumsum = squeeze(sum(locsum));
            
            % Begin populating the final weights and locations arrays, pixel locations
            % for which all orbits are making use of the same locations in the regridding.
            
            nn = find(locsumsum == 0);
            fprintf('Percent of pixels with the same locations for all orbits used: %f\n', 100*length(nn)/numel(locsumsum))
            
            for ii=1:num_levels_to_keep
                eval(['augmented_weights(ii,nn) = wghts' num2str(groups_of_2(i,1)) '(ii,nn);'])
                eval(['augmented_locations(ii,nn) = locs' num2str(groups_of_2(i,1)) '(ii,nn);'])
            end
        end
        
        %% Find all pixels for which the locations in three orbits are the same.
        
        groups_of_3 = [1 2 3; 1 2 4; 1 3 4; 2 3 4];
        
        for i=1:size(groups_of_3,1)
            eval(['locsum = 2 * wl' num2str(groups_of_3(i,1)) '.locations;'])
            
            for ii=groups_of_3(i,2:end)
                eval(['locsum = locsum - wl' num2str(ii) '.locations;'])
            end
            
            % Sum over levels.
            
            locsumsum = squeeze(sum(locsum));
            
            % Begin populating the final weights and locations arrays, pixel locations
            % for which all orbits are making use of the same locations in the regridding.
            
            nn = find(locsumsum == 0);
            fprintf('Percent of pixels with the same locations for all orbits used: %f\n', 100*length(nn)/numel(locsumsum))
            
            for ii=1:num_levels_to_keep
                eval(['augmented_weights(ii,nn) = wghts' num2str(groups_of_3(i,1)) '(ii,nn);'])
                eval(['augmented_locations(ii,nn) = locs' num2str(groups_of_3(i,1)) '(ii,nn);'])
            end
        end
        
        %% Finally, find all pixels for which the locations in all of the read in locations are the same.
        
        locsum = (jj - 1) * wl1.locations;
        
        for ii=[2 3 4]
            eval(['locsum = locsum - wl' num2str(ii) '.locations;'])
        end
        
        % Sum over levels.
        
        locsumsum = squeeze(sum(locsum));
        
        % Begin populating the final weights and locations arrays, pixel locations
        % for which all orbits are making use of the same locations in the regridding.
        
        nn = find(locsumsum == 0);
        fprintf('Percent of pixels with the same locations for all orbits used: %f\n', 100*length(nn)/numel(locsumsum))
        
        for ii=1:num_levels_to_keep
            augmented_weights(ii,nn) = wghts1(ii,nn);
            augmented_locations(ii,nn) = locs1(ii,nn);
        end
        
        % Save the results
        
        save('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights_and_locations_final_fixed.mat', 'augmented_weights', 'augmented_locations')
        
    case 2    %% New way.
                
        % Define global variables
        
        global fi
        global AXIS CAXIS_sst CAXIS_sst_diff_1 CAXIS_sst_diff_2 CAXIS_gm CAXIS_gm_diff
        global XLIM YLIM HIST_SST HIST_GM_1 HIST_GM_2 HIST_GM_3 COUNTS_LIM ZOOM_RANGE
        global title_fontsize axis_fontsize
        global along_scan_seps_array along_track_seps_array
        
        title_fontsize = 24;
        axis_fontsize = 18;
        
        % Get separations and angles for gradient calculations.
        
        fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/';   % Test run.
        gradient_filename = [fixit_directory 'Separation_and_Angle_Arrays.n4'];
        
        along_scan_seps_array = ncread(gradient_filename, 'along_scan_seps_array');
        along_track_seps_array = ncread(gradient_filename, 'along_track_seps_array');
        
        
        % Where are the weights and locations files?
        
        filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/*.mat');
        
        % Read the files -- turns out that the 4th one in the above directory is bad.
        
        jj = 0;
        kk = 0;
        
        for ii=1:length(filelist)
            
            % Only process files that are long enough; i.e., not partially constructed.
            
            if filelist(ii).bytes > 8 * 10^8
                fi = [filelist(ii).folder '/' filelist(ii).name];
                tt = load(fi);
                
                % Save only the first 3 levels.
                
                jj = jj + 1;
                if rem(jj, 3) == 1
                    kk = kk + 1;
                    eval(['locations_sum_' num2str(kk) ' = 2 * tt.locations(1:num_levels_to_keep,:,:);'])
                    %                 eval(['wl' num2str(kk) '.weights = tt.weights(1:num_levels_to_keep,:,:);'])
                    
                    eval(['locations_nn_sum_' num2str(kk) ' = 2 * tt.locations_nn(1,:,:);'])
                    %                 eval(['wl' num2str(kk) '.weights_nn = tt.weights_nn(1,:,:);'])
                else
                    eval(['locations_sum_' num2str(kk) ' = locations_sum_' num2str(kk) ' - tt.locations(1:num_levels_to_keep,:,:);'])
                    %                 eval(['wl' num2str(kk) '.weights = tt.weights(1:num_levels_to_keep,:,:);'])
                    
                    eval(['locations_nn_sum_' num2str(kk) ' = locations_nn_sum_' num2str(kk) ' - tt.locations(1:num_levels_to_keep,:,:);'])
                    %                 eval(['wl' num2str(kk) '.weights_nn = tt.weights_nn(1,:,:);'])
                end
                
                if rem(jj,3) == 0
                    eval(['ls' num2str(kk) ' = squeeze(sum(locations_sum_' num2str(kk) ',1,''omitnan''));'])
                end
            end
        end
        
    case 3  %% Based on nadir crossing of Equator.
        
        yearlist = dir('~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/Processed/2*');
        jFile = 0;
        
        for iYear=1:length(yearlist)
            monthlist = dir([yearlist(iYear).folder '/' yearlist(iYear).name '/']);
            
            iMonth = 0;
            for iMonthTemp=1:length(monthlist)
                if strcmp(monthlist(iMonthTemp).name(1), '.') == 0
                    iMonth = iMonth + 1;
                    filelist = dir([monthlist(iMonthTemp).folder '/' monthlist(iMonthTemp).name '/AQUA_MODIS_orbit_*']);
                                         
                    for iFile=1:length(filelist)
                        fi = [filelist(iFile).folder '/' filelist(iFile).name];
                        
                        kk = sttfind( fi, '_orbit_');
                        wl_stats(jFile).orbit = fi(kk+7:kk+11);
                        
                        jFile = jFile + 1;
                        
                        wl_stats(jFile).filename = fi;
                        wl_stats(jFile).nadir_lat(:) = ncread(fi, 'latitude', [677 1], [1 40271]);
                        wl_stats(jFile).nn_save = find(min(abs(wl_stats(iFile).nadir_lat(1:12000))) == abs(wl_stats(iFile).nadir_lat(1:12000)));
                        wl_stats(jFile).mm_save = find(min(abs(wl_stats(iFile).nadir_lat(12000:end))) == abs(wl_stats(iFile).nadir_lat(12000:end))) + 11999;
                        
                        fprintf('%i) %s: Equatorial crossing: ascending %i, descending %i\n', ...
                            jFile, filelist(iFile).name, wl_stats(jFile).nn_save, wl_stats(jFile).mm_save)
                    end
                end
            end
        end
end

