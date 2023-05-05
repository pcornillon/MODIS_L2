% fix_locations - fixes problems in locations in weights files - PCC
%
% I screwed up the indexing of the locations; I forgot to add the offset of
% the subregions. Because these files take so long to process, this program
% will fix them.

filelist = dir( '~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/*_L2_SST_weights.mat');

for iFile=1:length(filelist)
    filename_in = [filelist(iFile).folder '/' filelist(iFile).name];
    
    fprintf('Working on %s\n', filename_in)
    
    ww = load(filename_in);
    
    locations = ww.locations;
    
    % Fix region 2.
    
    locs = ww.locations;
    locs = locs + 1354 * (1990-40);
    
    locations(:,:,1990:20080) = locs(:,:,1990:20080);
    
    % Fix region 3.
    
    locs = ww.locations;
    locs = locs + 1354 * (20080-40);
    
    locations(:,:,20080:end) = locs(:,:,20080:end);
    
    % Fix region 4.
    
    locs = ww.locations;
    locs = locs + 1354 * (22070-40);
    
    locations(:,:,22070:end) = locs(:,:,22070:end);
    
    % Check that everything worked properly
    
    iBad = 0;
    for i=1:10:40271
        if locations(1,677,i) ~= 0
            [ii,jj] = ind2sub([1354,40271], locations(1,677,i));
            if jj ~= i
                iBad = iBad + 1;
                fprintf('%i) %i\n', i, jj)
            end
        end
    end
    
    if iBad > 5
        keyboard
    end
    
    % Get the output filename and save the rebuilt weights and locations.
    
    nn = strfind(filelist(iFile).name, '.mat');
    
    filename_out = [filelist(iFile).folder '/' filelist(iFile).name(1:nn-1) '_rebuilt.mat'];
    weights = ww.weights;
    
    save( filename_out, 'filename_in', 'weights', 'locations', '-v7.3')
end

   