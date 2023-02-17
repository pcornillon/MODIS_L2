function pcolor_image( FigNo, x, y, z, myCAXIS, myTITLE)
% pcolor_image - use pcolor to plot an image and annotate it for generate_separations_and_angles - PCC
%
% INPUT
%   FigNo - figure number to use.
%   x - longitude locations of points to plot.
%   y - latitude locations of points to plot.
%   z - values to plot at x and y locations.
%   myCAXIS - colorbar range.
%   myTITLE - plot title.
%
% OUTPUT
%   None

if FigNo > 0
    figure(FigNo)
    hold off
    
    pcolor( x, y, z)
    shading flat
    
    if isempty(myCAXIS) == 0
        caxis(myCAXIS)
    end
    set(gca,fontsize=20)
    colorbar
    
    xlabel('^\circ E')
    ylabel('^\circ N')
    
    title(myTITLE, fontsize=24)
end

end
