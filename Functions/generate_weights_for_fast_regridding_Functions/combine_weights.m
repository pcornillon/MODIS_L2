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

num_levels_to_keep = 3;

% Where are the weights and locations files?

filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/*fixed.mat*');

% Read the files -- turns out that the 4th one in the above directory is bad. 

% for ii=1:length(filelist)

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

final_weights = wl2.weights;
final_locations = wl2.locations;

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
        eval(['final_weights(ii,nn) = wghts' num2str(groups_of_2(i,1)) '(ii,nn);'])
        eval(['final_locations(ii,nn) = locs' num2str(groups_of_2(i,1)) '(ii,nn);'])
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
        eval(['final_weights(ii,nn) = wghts' num2str(groups_of_3(i,1)) '(ii,nn);'])
        eval(['final_locations(ii,nn) = locs' num2str(groups_of_3(i,1)) '(ii,nn);'])
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
    final_weights(ii,nn) = wghts1(ii,nn);
    final_locations(ii,nn) = locs1(ii,nn);
end

