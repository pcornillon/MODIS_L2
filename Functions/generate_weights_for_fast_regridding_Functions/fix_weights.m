% fix_weights - Replace nan values in one set of fast weights with non-nan values from another - PCC
%
% Use weights and location from orbit 41616 as the base. Replace nans in
% this orbit with non-nan values from orbit 41821.
%

% Get weights & locations from 41616.

wghts_41616 = load('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/41616_20100301T000736_L2_SST_weights_reordered.mat');

% Get weights & locations from 41821 and eliminate the last set of values.
% Weights for the 7th layer are all essentially 0.

xx = load('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/41821_20100315T015843_L2_SST_weights_reordered.mat');
wghts_41821 = xx;
wghts_41821.weights = xx.weights(1:6,:,:);
wghts_41821.locations = xx.locations(1:6,:,:);

clear xx

% Find nans in orbit 41616.

xx = squeeze(wghts_41616.weights(1,:,:));
nn = find(isnan(wghts_41616.weights) == 1);

% Replace the nans with values from orbit 41821.

wghts_41616_fixed.weights = wghts_41616.weights;
wghts_41616_fixed.weights(nn) = wghts_41821.weights(nn);
wghts_41616_fixed.locations = wghts_41616.locations;
wghts_41616_fixed.locations(nn) = wghts_41821.locations(nn);

% Save the fixed 41616 weights and locations for use in build_and_fix...

agumented_weights = wghts_41616_fixed.weights;
agumented_locations = wghts_41616_fixed.locations;
save('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights_and_locations_41616_fixed.mat', 'agumented_weights', 'agumented_locations');
