% average_weighs_and_locations
%

filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/4*ordered*');

scans_to_read = 8000;

for iScan=1:scans_to_read:40271
    for iFile=1:length(filelist)
        
        filename = [filelist(iFile).folder '/' filelist(iFile).name];
        load(filename, 'weights');
        
        weights_array(iFile,:,:) = squeeze(weights( 1, :, iScan:iScan+scans_to_read-1));
    end
    
    weights_array(weights_array==0) = nan;

    median_weights = squeeze( median( weights_array, 1, 'omitnan'));
        
    which_level = zeros(size(median_weights));
    
    for iLevel=1:size(weights_array,1)
        
        which_weights = squeeze(weights_array(iLevel, :, :)) - median_weights;
        
        nn = find(which_weights == 0);
        [jLevel, kLevel] = sub2ind(size(which_weights), nn);
        
        which_level(jLevel, kLevel) = iLevel;
    end
    
    median_locations = zeros(size(
    nn = find( which_level ~= 0 & isnan(which_level) == 0);
        median_locations(nn) = locations(nn);
    
end

