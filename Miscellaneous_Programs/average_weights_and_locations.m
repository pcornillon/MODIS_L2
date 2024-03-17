% average_weighs_and_locations
%

filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/4*ordered*');

scans_to_read = 8000;

weights_out = zeros(6, 1354, 40271);

tic
for iScan=1:scans_to_read:40271
    
    for iFile=1:length(filelist)
        
        filename = [filelist(iFile).folder '/' filelist(iFile).name];
        load(filename);
        
        super_weights(iFile,:,:,:) = weights( 1:6, :, iScan:iScan+scans_to_read-1);
        super_locations(iFile,:,:,:) = locations( 1:6, :, iScan:iScan+scans_to_read-1);
        
%         weights_array(iFile,:,:) = squeeze(weights( 1, :, iScan:iScan+scans_to_read-1));
    end
    
    super_weights(super_weights==0) = nan;

    median_weights = squeeze( median( super_weights(:,1,:,:), 1, 'omitnan'));
        
    which_orbit = zeros(size(median_weights));
   
    %% Make new weights and locations arrays with the weights and locations corresponding to the median of the weights in dimension 1.
    
    for iOrbit=1:size(super_weights,1)
        
        which_weights = squeeze(super_weights(iOrbit, 1, :, :)) - median_weights;
        
        nn = find(which_weights == 0);
        mm = find(which_weights ~= 0);
        
        [iPixel, jScan] = ind2sub(size(which_weights), nn);
        
        for iImpact=1:6
            temp_weights = squeeze(super_weights( iOrbit, iImpact, :, :));
            temp_weights(mm) = 0;
            
            weights_out(iImpact, :, iScan:iScan+scans_to_read-1) = temp_weights;
    
            temp_locations = squeeze(super_locations( iOrbit, iImpact, :, :));
            temp_locations(mm) = 0;
            
            locations_out(iImpact, :, iScan:iScan+scans_to_read-1) = temp_locations;
    
        end
    end
    
    fprintf('Time to process for orbit %i: %f\n', iOrbit, toc)
    tic
end

