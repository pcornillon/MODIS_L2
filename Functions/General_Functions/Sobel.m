function [grad_x grad_y, grad_mag] = Sobel( ImageIn, get_mag)
%
% Apply the Sobel operator to an image.
%
% INPUT
%
%  ImageIn - the image to which the Sobel operator is to be applied.
%
% OUTPUT
% 
%  grad_x - the gradient in the x direction.
%  grad_y - ...
%

% Remember that the first dimension increases downward in the array
%
%  1,1     1,2     1,3
%  2,1     2,2     2,3
%  3,1     3,2     3,3
%
% Also note, that this means that the 1st dimension really corresponds to
% what we would think of as y and the 2nd dimension as x.

% SX = [1 2 1; 0 0 0; -1 -2 -1];
SY = [ 1  2  1; 
       0  0  0; 
       -1 -2 -1];
   
% SY = [-1 0 1; -2 0 2; -1 0 1];
SX = [1 0 -1; 
      2 0 -2; 
      1 0 -1];

%SA = [2 1 0;1 0 -1; 0 -1 -2];
%SB = [0 1 2; -1 0 1;-2 -1 0];

if ~strcmp(class(ImageIn),'uint16')
    ImageIn = single(ImageIn);
end

tt = conv2( ImageIn, SX);
grad_x = tt(2:end-1,2:end-1) / 8;

tt = conv2( ImageIn, SY);
grad_y = tt(2:end-1,2:end-1) / 8;

%ImageOutA = conv2( ImageIn, SA);
%ImageOutB = conv2( ImageIn, SB);

if exist('get_mag')
    grad_mag = sqrt(grad_x.^2 + grad_y.^2);
else
    grad_mag = nan;
end

return
