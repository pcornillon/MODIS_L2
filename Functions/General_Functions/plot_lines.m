function plot_lines( FigNo, x, y, myAXIS, myLineColor, myLineWidth, myXLABEL, myYLABEL, myTITLE, myLEGEND)
% plot_lines - plots lines in for diagnostic plots for generate_separations_and_angles - PCC
%
% INPUT
%   FigNo - figure number to use.
%   x - a vector of x values.
%   y - a cell array y vectors for each of the lines to plot.
%   myAXIS - 4-element axis vector for plot.
%   myLineColor - cell array with a symbol/color for each line to plot.
%   myLineWidth - vector of line widths for each line to plot.
%   myXLABEL - lable for x-axis.
%   myYLABEL - label for y-axis.
%   myTITLE - plot title.
%   myLEGEND - cell array of legend for each of the lines to plot.
%
% OUTPUT
%   None

if FigNo > 0
    figure(FigNo)
    hold off
    
    for iLineNum=1:length(y)
        
        if isempty(x)
            x = 1:length(y{iLineNum});
        end
        
        if isempty(myLineColor)
            plot( x, y{iLineNum}, linewidth=myLineWidth(iLineNum))
        else
            plot( x, y{iLineNum}, myLineColor{iLineNum}, linewidth=myLineWidth(iLineNum))
        end
        
        hold on
    end
    
    set(gca,fontsize=20)
    axis(myAXIS)
    grid on
    
    nn = strfind(myTITLE, '$');
    if isempty(nn)
        title(myTITLE, fontsize=24)
    else
        title(myTITLE, interpreter='latex', fontsize=24)
    end
    xlabel(myXLABEL)
    ylabel(myYLABEL)
    
    if exist('myLEGEND')
        legend(myLEGEND)
    end
end

end
