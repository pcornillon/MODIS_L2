% fix_weights - Replace nan values in one set of fast weights with non-nan values from another - PCC
%
% Get all orbits with weights and locations. Then, replace nans in all
% obits using values from a specified orbit.
%

% Get the list of orbits with weights and locations already calculated.
filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/*reordered*');

for iFile=1:length(filelist)
    fprintf('%i) %s\n', iFile, filelist(iFile).name)
end

ref_orbit_no = input('Above are the orbits with weights and locations, choose a reference orbit: ', 's');

% Loop over files looking for the reference orbit

for iFile=1:length(filelist)
    filename = [filelist(iFile).folder '/' filelist(iFile).name];
    
    % Skip if this is the reference orbit.
    nn = strfind(filelist(iFile).name, ref_orbit_no);
    
    if ~isempty(nn)
        iRef = iFile;
        
        [ref_weights, ref_locations] = get_and_trim_weights(filename) ;       
    end
end

% Now loop over orbits, correcting them with the reference orbit.

for iFile=1:length(filelist)
    filename = [filelist(iFile).folder '/' filelist(iFile).name];
    orbit_no = filelist(iFile).name(1:5);
    
    fprintf('%i) Working on orbit number %s with filename %s\n', iFile, orbit_no, filelist(iFile).name)
    
    % Skip if this is the reference orbit.
    nn = strfind(filename, ref_orbit_no);
    if isempty(nn)

        % Get weights & locations from this orbit.
        
        [weights, locations] = get_and_trim_weights(filename) ;       

        % Find nans in orbit this orbit.
        
        nn = find(isnan(weights) == 1);
        
        % Replace the nans with values from orbit 41821.
        
        augmented_weights = weights;
        augmented_weights(nn) = ref_weights(nn);
        
        augmented_locations = locations;
        augmented_locations(nn) = ref_locations(nn);
        
        % Save the fixed weights and locations for use in build_and_fix...
        
        save(['~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights_and_locations_' orbit_no '_fixed.mat'], 'augmented_weights', 'augmented_locations');
    else
        fprintf('Skipping file''s, this is the reference obit.\n', filename)
    end
end

%% Functions

function [weights, locations] = get_and_trim_weights(filename)
% get_and_trim_weights - and locations for the specified file
%
% Reads the file with the weights and locations and if there are more than
% 6 levels, makes sure that the higher levels do not contribute much and
% then, assuming that they don't trims the file.
%
% INPUT 
%   filenname - name of file with data.
%
% OUTPUT
%   weights - trimmed to 6 levels from input file.
%   locations - trimmed to 6 levels from input file.

% Get weights & locations for this orbit

load(filename);
[nLevels, nPixels, nScans] = size(weights);

% Make sure that it is at least 6 levels of weights.

if nLevels < 6
    fprintf('%i levels. Need at least 6. Will return nan.\n', nLevels)
    weights = nan;
    locations = nann;
    return
end

% Make sure that there are at most 6 levels of weights

if nLevels > 6
    fprintf('%i levels, will trim to 6.\n', nLevels)
    
    for iLevel=7:nLevels
        xx = squeeze(weights(iLevel,:,:));
        fprintf('Level %i) min/max %f/%f\n', iLevel, min(xx(:)), max(xx(:)))
        
        if (abs(min(xx(:))) > 0.1) | (abs(max(xx(:))) > 0.1)
            fprinntf('Problem; min or max value exceeds 0.1\n')
            weights = nan;
            locations = nan;
            return
        end
    end
    
    weights = weights(1:6,:,:);
    locations = locations(1:6,:,:);
end

end

