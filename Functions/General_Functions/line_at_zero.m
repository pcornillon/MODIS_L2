function line_at_zero( FontSize, LineWidth, LineColor)
% line_at_zero - plot a line at y=0 - PCC
%
% This function will get the xlimits of the plot and plot a line of width
% linewidth and color linecolor at y=0 between the x limits. Will hold plot
% before plotting.
%
% INPUT
%   FontSize - size of font on axis. If empty will not change it.
%   LineWidth - width of line to plot. If empty will default to 1.
%   LineColor - color of line to plot. If empty will default to 'k'.
%
% OUTPUT
%   none

if exist('FontSize')
    if isempty(FontSize) == 0
        set( gca, fontsize=FontSize)
    end
end

if exist('LineColor') == 0
    LineColor = 'k';
end

if exist('LineWidth') == 0
    LineWidth = 1;
end

XLIM = get(gca,'xlim');
hold on

plot( XLIM, [0 0], LineColor, linewidth=LineWidth)