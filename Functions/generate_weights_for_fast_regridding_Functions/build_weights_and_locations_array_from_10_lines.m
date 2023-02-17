% build_weights_and_locations_array_from_10_lines
%
% This script reads in the weights and locations arrays developed
% previously for on group of 10 lines and then replicates them to build
% arrays that are 3x1354x40400 elements and saves them.

bb = load('/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weights_31191.mat');

new_weights = zeros(3,1354,40400);
new_locations = zeros(3,1354,40400);

nInc = 1354 * 10;

for iRep=1:40400/10
    new_weights(:,:,10*(iRep-1)+1:10*(iRep-1)+10) = bb.weights(:,:,1:10);
    new_locations(:,:,10*(iRep-1)+1:10*(iRep-1)+10) = (iRep-1)*nInc + double(bb.locations(:,:,1:10));
end

augmented_weights = single(new_weights);
augmented_locations = int32(new_locations);

save('/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weights_and_locations_from_31191.mat', 'augmented_weights', 'augmented_locations')


