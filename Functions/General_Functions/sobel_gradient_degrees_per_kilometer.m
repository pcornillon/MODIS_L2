function [g1, g2, gm] = sobel_gradient_degrees_per_kilometer(sst, dist_1, dist_2)
% sobel_gradient_degrees_per_kilometer - gradients of the input field - PCC
%
% Returns gradients in degrees/km assuming that dist_as and dist_at are
% separations in kilometers. The g1 and g2 are the gradients in the first
% dimension of sst and the 2nd dimension, respectively.
%
% INPUT
%   sst - the two dimensional input array over which the gradient is to be calculated.
%   dist_1 - separations of pixels along the first dimension, presumably km but not necessary. 
%   dist_2 - separations of pixels along the second dimension.
%
% OUTPUT
%   g1 - gradient along the first dimension.
%   g2 - gradient along the second dimension.
%   gm - gradient magnitude.
%
        [g1, g2] = Sobel(sst);
        g1 = g1 ./ dist_1;
        g2 = g2 ./ dist_2;
        
        gm = sqrt(g1.^2 + g2.^2);
end