function plot_image( FigNo, x, y, z, myCAXIS, myXLABEL, myYLABEL, myTITLE)
% plot_image - use imagesc to plot an image and annotate it for generate_separations_and_angles - PCC
%
% INPUT
%   FigNo - figure number to use.
%   x - x locations of points to plot.
%   y - y locations of points to plot.
%   z - values to plot at x and y locations.
%   myCAXIS - colorbar range.
%   myXLABEL - lable for x-axis.
%   myYLABEL - label for y-axis.
%   myTITLE - plot title.
%
% OUTPUT
%   None

if FigNo > 0
    figure(FigNo)
    hold off
    
    imagesc( x, y, z)
    
    if isempty(myCAXIS) == 0
        caxis(myCAXIS)
    end
    set(gca,fontsize=20)
    colorbar
    
    title(myTITLE, fontsize=24)
    xlabel(myXLABEL)
    ylabel(myYLABEL)
end

end

