function [Num, weights, locations] = regrid_subregion( nPixels, nScanlines, SizeIn, iPixel, iScan, iso, jso, vout, Num, weights, locations, nearest_neighbor)
% regrid_subregion - get weights and locations for this subregion - PCC
%
% This function receives the regridded array corresponding to a 1 at
% iPixel, iScan in the parent array. It finds all non-zero values in the
% subregion, which are impacted pixels. It then sorts out where these fall
% in the parent array and updates the number of impacted pixels, their
% weights and their locations.
%
% INPUT
%   nPixels - the number of pixels in the along-scan direction for the
%    parent region from which this subregion was drawn.
%   nScanlines - the number of pixels in the along-track direction for the
%    parent region from which this subregion was drawn.
%   SizeIn - the size of the input subregion.
%   iPixel - the along-scan location in the input array of the pixel that
%    will be assigned a 1 to determine the impacted pixels associated with
%    this pixel.  
%   iScan - the y location of the pixel of interst.
%   iso - the starting value in the along-scan direction of the output
%    subregion.  
%   jso - the starting value in the along-track direction of the output
%    subregion.
%   vout - the regridded array for this subrgion corresponding a value of 1
%    in the input subregion.
%   Num - the number of times this pixel has been impacted.
%   weights - the weights of the impacted pixel.
%   locations - the locations in the output parent region of the impacted
%    pixel.
%   nearest_neighbor - 1 if these data are for nearest neighbor
%    interpolation. 0 if linear interpolation.
%
% OUTPUT
%   Num - the number of times this pixel has been impacted, updated for
%    this subregion 
%   weights - the weight of the impacted pixel.
%   locations - the location in the output parent region of the impacted
%    pixel.
%

% Start by finding all pixels impacted in the subregion and map these to
% the parent region. If no pixels in the output region are impacted, skip
% this part.

[iot, jot] = find(vout ~= 0);

if ~isempty(iot)
    
    % Get the subscripts for the impacted pixels in the full regridded array.
    
    at = iot + iso - 1;
    bt = jot + jso - 1;
    
    % Make sure that the location of pixels in the full output array are
    % not out of bounds. 
    
    kk = find((at > 0) & (at <= nPixels) & (bt > 0) & (bt <= nScanlines));
    
    if length(kk) ~= length(at)
        fprintf('\n******************\n******************\n at or bt out of bounds for (iPixel, iScan) = (%i, %i)\n******************\n******************\n\n', iPixel, iScan)
    end
    
    a = at(kk);
    b = bt(kk);
    
    % Hopefully, some pixels remain.
    
    if length(a) > 0
        
        % Get the indices of the impacted  pixels in the full array.
        
        sol = sub2ind( SizeIn, a, b);
        nLevels = length(sol);
        
        % Loop over all impacted pixels saving their weight and location.
        
        if nearest_neighbor == 1
            
            % Make sure that there are between 1 and 5 values. Should
            % really only be 1 but could be up to 3--I think.
                        
            if length(a) > 6
                fprintf('\n******************\n******************\n length(a)=%i for (iPixel, iScan) (%i, %i). Should be between 1 and 5, inclusive.\n******************\n******************\n\n', length(a), iPixel, iScan)
                a = a(1:6);
                b = b(1:6);
                
                nLevels = 6;
            end
        end
        
        for iNum=1:nLevels
            
            % Eliminate phantom hits from the list.
            
            if abs(vout(iot(iNum),jot(iNum))) > -0.1
                Num(sol(iNum)) = Num(sol(iNum)) + 1;
                k = Num(sol(iNum));
                
                weights(k,a(iNum),b(iNum)) = vout(iot(iNum),jot(iNum));
                locations(k,a(iNum),b(iNum)) = sub2ind( SizeIn, iPixel, iScan);
            end
        end
    end
end

