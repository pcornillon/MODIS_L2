function Map_Axis_Range( WhichAxis, Input_Figure, Output_Figure)
% Map_Axis_Range - impose axis range from Input_Figure to Output_Figure - PCC.
%
% INPUT
%  WhichAxis - 'a' for xy and 'c' for color.
%  Input_Figure - the figure number of the figure to use in determining the
%   axis range.
%  Output_Figure - the figure number of the figure to which to apply the
%   axis range of the input figure

% If the input figure is in subplot, parse the input figure number.

subplot_in = 1;

tt = num2str(Input_Figure);
nn = strfind(tt,'.');
if isempty(nn)
    subplot_in = 0;
else
    Input_Figure = str2num(tt(1:nn-1));
    SUBPLOT_IN = str2num(tt(nn+1:end));
end

subplot_out = 1;

tt = num2str(Output_Figure);
nn = strfind(tt,'.');
if isempty(nn)
    subplot_out = 0;
else
    Output_Figure = str2num(tt(1:nn-1));
    SUBPLOT_OUT = str2num(tt(nn+1:end));
end

figure(Input_Figure)

if subplot_in
    subplot(SUBPLOT_IN)
end

switch WhichAxis
    case 'a'
        XLIM = get(gca,'xlim');
        YLIM = get(gca,'ylim');
        
        figure(Output_Figure)
        
        if subplot_out
            subplot(SUBPLOT_OUT)
        end
        
        axis([XLIM YLIM])
        
    case 'c'
        CLIM = get(gca,'Clim');
        
        figure(Output_Figure)
        
        if subplot_out
            subplot(SUBPLOT_OUT)
        end
        
        caxis(CLIM)
        
    otherwise
        disp(['You entered ' WhichAxis '. Must be either a or c.'])
end


end

