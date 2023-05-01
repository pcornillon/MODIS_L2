function [outputArg1,outputArg2] = plot_with_markers( FigNo, x, y, Color, Size)
% plot_with_markers - plot as hamburgers of color Color and size Siz - PCC
%
% Will start by holding the current plot and then plotting.
%
% INPUT
%   FigNo - the figure number to use for the plot.
%   x - the x coordinate
%   y - the y coordinate
%   Color - the color to use for the meatball.
%   Size - size of the meatball.
%
% OUTPUT
%   none

plot( x, y, 'ok', markerfacecolor=Color, markersize=Size)

end

