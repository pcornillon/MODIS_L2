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
    
    wm = mean(w, 1, 'omitnan');
end

