% sort_weights_and_locations - for all orbits from largest to smallest - PCC
%
% For each orbit for which generate_weights_and_locations has produced a
% file, read the weights and locations arrays and sort on the 1st dimension
% of weights and apply to locations.

filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/4*');

for iFile=1:length(filelist)
    
    % Get the input filename.
    
    filename_in = [filelist(iFile).folder '/' filelist(iFile).name];
    
    % Make the output filename. 
    
    nn = strfind( filename_in, '.mat');
    filename_out = [filename_in(1:nn-1) '_reordered.mat'];
    
    % Get the weights and locations for this orbit.
    
    load(filename_in)
    
    % Sort the weights and locations arrays on the 1st dimension in descending order.
    
    % The idea here is for the 1st weight in the set of 5 to be the largest,
    % the 2nd the 2nd largest,... and then to sort locations in the same
    % order as weights. First, set any location for which the weights sum
    % to zero to nan; there was no interpolated value for this location.
    
    sum_weights = squeeze(sum(weights,1));
    [isum, jsum] = find(sum_weights == 0);
    for ksum=1:length(isum)
        weights(:,isum(ksum),jsum(ksum)) = nan;
    end
    
    % Next, permute, I think that the sorting requires the column soted on
    % to be the last dimension.
    
    temp = permute( weights, [2, 3, 1]);
    clear weights
    
    % Sort
    
    [m,n,o] = size(temp);
    
    [~,ix] = sort(temp,3,'descend');
    
    temp2 = temp((ix-1)*m*n + reshape(1:m*n,m,[]));
    
    % Permute back to the expected order
    
    weights = permute(temp2, [3, 1, 2]);
    
    % Now do the locations.
    
    temp = permute( locations, [2, 3, 1]);
    temp2 = temp((ix-1)*m*n + reshape(1:m*n,m,[]));
    
    locations = permute(temp2, [3, 1, 2]);
    
    % Save the results
    
    save( filename_out, 'filename_in', 'weights', 'locations', '-v7.3')
end
