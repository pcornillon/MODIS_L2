function [ jPixel, jScan, isi, iei, jsi, jei, iso, jso, ieo, jeo] = get_subregion_indicies( nPixels, nScanlines, iPixel, iScan, in_size_x, in_size_y, out_size_x, out_size_y)
% get_subregion_indicies - defines th subset of the input and ouput arrays to use - PCC.
%
% This function is called by generate_weights_and_locations. It finds the
% start and end for each of the dimensions for the input array to regrid
% and the output array to receive the regridded data. 
%
% INPUT 
%   nPixels - the number of pixels in the along-scan direction for the
%    parent region from which this subregion was drawn.
%   nScanlines - the number of pixels in the along-track direction for the
%    parent region from which this subregion was drawn.
%   iPixel - the along-scan location in the input array of the pixel that
%    will be assigned a 1 to determine the impacted pixels associated with
%    this pixel.  
%   iScan - the y location of the pixel of interst.
%   in_size_x - the number of pixels in the along-scan direction on each
%    side of iPixel to use to determine the regridded value. Note that the
%    actual number changes near the edges.
%   in_size_y - the number of pixels in the along-track direction on each
%    side of iScanto use.
%   out_size_x - similar to in_size_x but for the output array.
%   out_size_y - similar to in_size_y but for the output array.
%
% OUTPUT
%   jPixel - the along-scan location of the value of 1 in the input subregion.
%   jScan - the along-track location of the value of 1 in the input subregion.
%   isi - the actual starting value in the along-scan direction for the 
%    input subregion.
%   iei - the ending value for the input subregion.
%   jsi - similar to isi but for the along-track direction.
%   jei - and the ending value for the input subregion.
%   iso - as for iei but for the regriddd array.
%   jso - ...
%   ieo - ...
%   jeo - ...
%

% Get the starting and ending indices of the subregion in the original
% array on which griddata is being applied. 

isi = max([1 iPixel-in_size_x]);
iei = min([iPixel+in_size_x nPixels]);

jsi = max([1 iScan-in_size_y]);
jei = min([iScan+in_size_y nScanlines]);

iso = max([1 iPixel-out_size_x]);
ieo = min([iPixel+out_size_x nPixels]);

jso = max([1 iScan-out_size_y]);
jeo = min([iScan+out_size_y nScanlines]);

% Find the location at which the value of 1 is to be places in the
% subregion being regridded. 

if iei <= 2*in_size_x
    jPixel = iei - in_size_x;
else
    jPixel = in_size_x + 1;
end

if jei <= 2*in_size_y
    jScan = jei - in_size_y;
else
    jScan = in_size_y + 1;
end

