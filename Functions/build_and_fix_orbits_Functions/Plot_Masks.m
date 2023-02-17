function  Figno = Plot_Masks( Plot_This_one, Figno, inLiveScript, Image_to_Plot, TITLE_Image_to_Plot, XLabelS, YLabelS, Map_to, Save_to_Figure_Name, pcc_pal, SST_Range)
% Plot_Masks - plots masks for Fix_MODIS_Mask - pcc
%
% INPUT
%   Plot_This_one - 1 to actually do the plot; 0 to return without doing anything. 
%   Figno - figure number
%   inLiveScript - 1 if in a live script; will put figure in live script
%    area. Otherwise plot in regular space.
%   Image_to_Plot - mask to plot
%   TITLE_Image_to_Plot - title of mask to plot
%   XLabelS - for the plot.
%   YLabelS - for the plot.
%   Map_to - if present will map the axes of this plot to the figure number
%    provided here.
%
% OUTPUT
%   Figno - the figure number used incremented by 1 if the figure is to be
%    plotted.

global AxisFontSize TitleFontSize Trailer_Info

if ~exist('TITLE_Image_to_Plot')
    TITLE_Image_to_Plot = '';
end

if Plot_This_one
    hFig = figure(Figno);
    clf
    
    if inLiveScript==0
        set(gcf,'Visible','on')
    end
    
    imagesc(Image_to_Plot')
    set(gca, 'fontsize', AxisFontSize)
    colorbar
    
    if strfind(TITLE_Image_to_Plot, '\_')
        % Can't have \_ in the string or it will end up with \\_, which causes problems.
        title( [TITLE_Image_to_Plot strrep(Trailer_Info, '_', '\_')], 'fontsize', TitleFontSize, 'interpreter', 'latex')
    else
        title( strrep([TITLE_Image_to_Plot Trailer_Info], '_', '\_'), 'fontsize', TitleFontSize, 'interpreter', 'latex')
    end
    
    if exist('Map_to')
        if ~isempty(Map_to)
            Map_Axis_Range('a', Map_to, Figno)
        end
    end
    
    if exist('XLabelS')
        xlabel(XLabelS)
    end
    
    if exist('YLabelS')
        ylabel(YLabelS)
    end
    
    if exist('Save_to_Figure_Name')
        colormap(pcc_pal);
        caxis([SST_Range])
        
        savefig(hFig, Save_to_Figure_Name, 'compact')
        print(strrep(Save_to_Figure_Name, '.fig', '.png'), '-dpng')
    end
    Figno=Figno+1;
end

end
