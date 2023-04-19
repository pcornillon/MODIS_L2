function [weights, locations] = generate_weights_and_locations(filename)
% generate_weights_and_locations - does this for inputs to fix bow-tie - PCC
%
% This function reads in the longitudes, latitude, regridded longitudes and
% regridded latitudes for an orbit. It then builds a 7x7 element array of
% zeros with 1 in the middle, the array centered on an input pixel and scan
% line location. It performs a griddata to the 31x31 regridded fields
% centered on the same point to determine which of these pixels is impacted
% by the input value at iPixel, iScan.
%
% INPUT
%   filename - the name of the file with the orbit of interest.
%
% OUTPUT
%   weights - a 3d array of the resulting griddata value in the regridded 
%    array. The resulting griddata values are written in this array at the
%    location of iPixel, iScan.
%   locations - the location array of each of the resulting griddata values 
%    in the full array.
 
% First, pull out the first 50 pixels of each scan line.

test_case = 0;

switch test_case
    case 0
        lat = o1.latitude;
        lon = o1.longitude;
        
        regridded_lat = o1.regridded_latitude;
        regridded_lon = o1.regridded_longitude;

    case 1
        lat = o1.latitude(1:51,:);
        lon = o1.longitude(1:51,:);
        
        regridded_lat = o1.regridded_latitude(1:51,:);
        regridded_lon = o1.regridded_longitude(1:51,:);
        
    case 2
        lat = o1.latitude(1:51,1:100);
        lon = o1.longitude(1:51,1:100);
        
        regridded_lat = o1.regridded_latitude(1:51,1:100);
        regridded_lon = o1.regridded_longitude(1:51,1:100);
        
end

% Intialize output arrays.

weights = single(nan(9,size(lat,1),size(lat,2)));
locations = single(nan(9,size(lat,1),size(lat,2)));

% Now get the weights and locations

tStart = tic;

for iPix=4:size(lat,1)-4
    tic
    for iScan=4:size(lat,2)-4
        
        isi = iPix-3;
        iei = iPix+3;
        
        jsi = iScan-3;
        jei = iScan+3;
        
        iso = max([1 iPix-15]);
        ieo = min([iPix+15 size(lat,1)]);
        
        jso = max([1 iScan-15]);
        jeo = min([iScan+15 size(lat,2)]);
        
        vin = zeros(7,7);
        vin(4,4) = 1;
        
        vout = griddata( lon(isi:iei,jsi:jei), lat(isi:iei,jsi:jei), vin, regridded_lon(iso:ieo,jso:jeo), regridded_lat(iso:ieo,jso:jeo));
        
        [iot, jot] = find(vout>0);
        sol = sub2ind(size(vout), iot, jot); 
        
        so = sub2ind(size(lat), iso+iot-1, jso+jot-1); 
        
        [wo, wio] = sort(vout(sol), 'desc');
                
        num_to_process = min([9 length(sol)]);
% %             fprintf('More than 9 hist for (iPix, iScan) = (%i, %i)\n', iPix, iScan)
% %         else
            
            for k=1:num_to_process
                weights( k, iPix, iScan) = vout(sol(wio(k)));
                locations( k, iPix, iScan) = so(wio(k));
            end
        end
    end
    fprintf('Took %5.2f s to process for iPix = %i\n', toc, iPix)
end

fprintf('Took %f s to process for the entire run.\n', toc(tStart))
