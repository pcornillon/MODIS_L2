% average_weighs_and_locations 
%

filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/4*');

filename = [filelist(1).folder '/' filelist(1).name];

ww = load(filename, 'weights');

w(1,:,:) = ww.weights(1,:,:);

for i=2:length(filelist)
    
    filename = [filelist(i).folder '/' filelist(i).name];
    ww = load(filename, 'weights');
    
    w(i,:,:) = ww.weights(1,:,:);
end

wm = mean(w, 1, 'omitnan');

