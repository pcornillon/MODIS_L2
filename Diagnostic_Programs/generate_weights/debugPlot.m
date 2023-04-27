function debugPlot(iFig, AXIS, lon, lat, rlon, rlat, i1, j1, rii, rji)
% debugPlot - plots points to debug weights, locations generator - PCC
%
% This function is to be called from either test_interpolations or
% generate_weights_and_locations. It will plot the grids, the location
% where there is a 1 in the input field and the output locations affected
% by the input location.
%
% INPUT
%   iFig - the figure number to use.
%   AXIS - the vector of left, right, upper, lower values for axis(AXIS)
%   lon - the input longitude array
%   lat - the input latitude array
%   rlon - the regridded longitude array.
%   rlon - the regridded latitude array.
%   i1 - the 1st dimenstion of the location of the pixel in the array with a 1 value
%   j1 - the 2nd dimenstion of the location of the pixel in the array with a 1 value
%   rii - the 1st dimension of the impacted pixels in the regridded array.
%   rji - the 1st dimension of the impacted pixels in the regridded array.

    figure(iFig)
    clf
    
    % Plot the location of the pixel with a 1 in it in the input grid.
    
    plot( lon(i1,j1), lat(i1,j1), 'ok', markerfacecolor='y', markersize=20)
    
    hold on

    % Plot the location of the impacted regridded data points in lat, lon space.
    
    nn = sub2ind( size(rlon), rii, rji);
    plot( rlon(nn), rlat(nn), 'ok', markerfacecolor='c', markersize=15)

    % Plot the locations of the input lat,lon
    
    plot( lon, lat, 'ok', markerfacecolor='k', markersize=10)

    % Plot the location of the regridded lats and lons

    plot( rlon, rlat, 'or', markerfacecolor='r', markersize=8)
    
    % Replot the input locations but smaller so that I can see them if they
    % are on top of regridded location.
    
    plot( lon, lat, 'ok', markerfacecolor='k', markersize=4)
    
    % Annotate the plot 
    
    set(gca,fontsize=20)
    
    % Add locations of input grid points in grid to the figure.
    
    for ip=1:30
        for jp=1:40
            text( lon(ip,jp)+0.02, lat(ip,jp), ['(' num2str(ip) ', ' num2str(jp) ')'], fontsize=15)
        end
    end
    
    % Add locations of regridded grid points in grid to the figure.
    
    for ip=1:30
        for jp=1:40
            text( rlon(ip,jp)+0.02, rlat(ip,jp), ['(' num2str(ip) ', ' num2str(jp) ')'], fontsize=15, color=[1 0 0])
        end
    end
    
    axis(AXIS)

