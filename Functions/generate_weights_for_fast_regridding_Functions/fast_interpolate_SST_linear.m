function [SST_Out] = fast_interpolate_SST_linear( weights, locations, SST_In)
% fast_interpolate_SST_linear - interpolate to regridded orbit - PCC
%  
% EXAMPLE: 
%   fi_orbit = '/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/07/AQUA_MODIS.20100701T004317.L2.SST.nc4';
%   SST_In = ncread(fi_orbit, 'SST_In');
%   qual = ncread(fi_orbit, 'qual_sst');
%   regridded_sst = ncread(fi_orbit, 'regridded_sst');
%   [SST_Out] = fast_interpolate_SST_linear( augmented_weights, augmented_locations, SST_In);
%

[nElements, nScans] = size(SST_In);
[nMax, mElements, mScans] = size(weights);

% Check number of elements/scan line; should be the same for weights and sst.

if mElements > nElements
    fprintf('\n\n****************\nNumber of weight elements/scan (%i) is not equal to the number of SST elements/scans (%i).\n****************\n\n ', mElements, nElements)
    
    regridded_sst = [];
    return
end

% Make sure that there are more weight scan lines than SST scan lines.

if mScans < nScans
    fprintf('\n\n****************\nNumber of weight scans (%i) is less than the number of SST scans (%i).\n****************\n\n ', mScans, nScans)
    
    regridded_sst = [];
    return
end

% Truncate weights array to same number of scan lines as SST array.

weights = weights(:,:,1:nScans);

% Now regrid.

SST_Out = zeros([nElements, nScans]);

for iC=1:nMax
    weights_temp = weights(iC,:,:);
    locations_temp = locations(iC,:,:);
    
    non_zero_weights = find(weights_temp ~= 0);
    
    SST_temp = zeros([nElements, nScans]);
    SST_temp(non_zero_weights) = weights_temp(non_zero_weights) .* SST_In(locations_temp(non_zero_weights));
    
    SST_Out = SST_Out + SST_temp;
end

% % %     non_zero_weights = find(weights ~= 0);
% % %     
% % %     SST_temp = zeros([nMax, nElements, nScans]);
% % %     SST_temp(non_zero_weights) = weights(non_zero_weights) .* SST_In(locations_temp(non_zero_weights));
% % %     
% % %     SST_Out = SST_Out + SST_temp;
% % % end
