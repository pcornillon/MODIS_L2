function generate_weights_and_locations(pattern_in, num_in_range)
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
%   pattern_in - to use in directory search as follows: ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/03/AQUA_MODIS_orbit_*_' pattern_in '*']
%    generally it is YYYMMDDT but it could be something different in the
%    time range.
%   num_in_range - the number of orbits in the range found with the
%    patter_in.
%
% OUTPUT
%  none - the results are saved in a mat file.
%
% EXAMPLE
%   generate_weights_and_locations('20100301T', 3)
%

% Define some variables

Method = 'linear';
% Method = 'nearest';

in_size_x = 3;
in_size_y = 12;
out_size_x = 1;
out_size_y = 12;

% Turn off warnings for duplicate values in griddata.

id = 'MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId';
warning('off',id)

% Get the list of files for the pattern passed in.

filelist = dir(['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/2010/03/AQUA_MODIS_orbit_*' pattern_in '*']);
numfiles = length(filelist);

file_step = floor(numfiles / num_in_range);

% Read in the data

for iFile=1:file_step:numfiles
    jFile = iFile;
    
    while 1==1
        filename_in = [filelist(jFile).folder '/' filelist(jFile).name];
        
        nn = strfind(filename_in, 'orbit_');
        mm = strfind(filename_in, '.nc4');
        filename_out = ['~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/' filename_in(nn+7:mm-1) '_weights.mat'];
        
        if exist(filename_out)
            jFile = jFile + 1;
            
            if jFile > numfiles
                return
            end
        else
            break
        end
    end
    
    fprintf('Working on %s\n', filename_in)
    % Read in the data for this file.
    
    latitude = single(ncread(filename_in, 'latitude'));
    regridded_latitude = single(ncread(filename_in, 'regridded_latitude'));
    longitude = single(ncread(filename_in, 'longitude'));
    regridded_longitude = single(ncread(filename_in, 'regridded_longitude'));
    
    [nPixels, nScanlines] = size(latitude);

    % Make sure that there are not nan's in the input.
    
    nn = find(isnan(latitude)==1);
    if ~isempty(nn)
        fprintf('Sorry but nans in this file; griddata does not like this. Returning\n')
        weights = nan;
        locations = nan;
        return
    end
    
    % Intialize output arrays.
    
% % %     weights = single(zeros(6,size(latitude,1),size(latitude,2)));
% % %     locations = single(zeros(6,size(latitude,1),size(latitude,2)));
% % %     Num = int16(zeros(6,size(latitude,1),size(latitude,2)));
    
    weights = zeros(6,size(latitude,1),size(latitude,2));
    locations = zeros(6,size(latitude,1),size(latitude,2));
    Num = zeros(6,size(latitude,1),size(latitude,2));
    
    % Now get the weights and locations
    
    tStart = tic;
    
    % % %     for iPix=4:size(latitude,1)-4
    % % %         tic
    % % %         for iScan=4:size(latitude,2)-4
    % % %
    % % %             isi = iPix-3;
    % % %             iei = iPix+3;
    % % %
    % % %             jsi = iScan-3;
    % % %             jei = iScan+3;
    % % %
    % % %             iso = max([1 iPix-15]);
    % % %             ieo = min([iPix+15 size(latitude,1)]);
    % % %
    % % %             jso = max([1 iScan-15]);
    % % %             jeo = min([iScan+15 size(latitude,2)]);
    % % %
    % % %             vin = zeros(7,7);
    % % %             vin(4,4) = 1;
    % % %
    % % %             vout = griddata( longitude(isi:iei,jsi:jei), latitude(isi:iei,jsi:jei), vin, regridded_longitude(iso:ieo,jso:jeo), regridded_latitude(iso:ieo,jso:jeo));
    % % %
    % % %             [iot, jot] = find(vout>0);
    % % %             sol = sub2ind(size(vout), iot, jot);
    % % %
    % % %             so = sub2ind(size(latitude), iso+iot-1, jso+jot-1);
    % % %
    % % %             [wo, wio] = sort(vout(sol), 'desc');
    % % %
    % % %             num_to_process = min([9 length(sol)]);
    % % %             % %             fprintf('More than 9 hist for (iPix, iScan) = (%i, %i)\n', iPix, iScan)
    % % %             % %         else
    % % %
    % % %             for k=1:num_to_process
    % % %                 weights( k, iPix, iScan) = vout(sol(wio(k)));
    % % %                 locations( k, iPix, iScan) = so(wio(k));
    % % %             end
    % % %         end
    % % %         fprintf('Took %5.2f s to process for iPix = %i\n', toc, iPix)
    % % %     end
    
    % % %     for iScan=1:nScanlines
    % % %         tic
    for iPixel=1:nPixels
        tic
        for iScan=1:nScanlines
            
            % Get the indices for the subregion to grid.
            
            isi = max([1 iPixel-in_size_x]);
            iei = min([iPixel+in_size_x nPixels]);
            
            jsi = max([1 iScan-in_size_y]);
            jei = min([iScan+in_size_y nScanlines]);
            
            iso = max([1 iPixel-out_size_x]);
            ieo = min([iPixel+out_size_x nPixels]);
            
            jso = max([1 iScan-out_size_y]);
            jeo = min([iScan+out_size_y nScanlines]);
            
            if iei <= 2*in_size_x
                jPixel = iei - in_size_x;
            else
                jPixel = in_size_x + 1;
            end
            
            if jei <= 2*in_size_y
                jScan = jei - in_size_y;
            else
                jScan = in_size_y + 1;
            end
            
            % Define the input array to regrid - all zeros except for one
            % point, which is set to 1. This point is in the center of the
            % array except when near the edges.
            
            vin = zeros(iei-isi+1, jei-jsi+1);
            vin(jPixel,jScan) = 1;
            
            % Regrid.
            
% % %             lon_temp = double(longitude(isi:iei,jsi:jei));
% % %             lat_temp = double(latitude(isi:iei,jsi:jei));
% % %             regridded_lon_temp = double(regridded_longitude(iso:ieo,jso:jeo));
% % %             regridded_lat_temp = double(regridded_latitude(iso:ieo,jso:jeo));

% % %             vout = griddata( lon_temp, lat_temp, vin, regridded_lon_temp, regridded_lat_temp);
            vout = griddata( longitude(isi:iei,jsi:jei), latitude(isi:iei,jsi:jei), vin, regridded_longitude(iso:ieo,jso:jeo), regridded_latitude(iso:ieo,jso:jeo));
            
            nn = find( (vout ~= 0) & (isnan(vout) == 0) );
            
            if ~isempty(nn)
                [iot, jot] = find( (vout ~= 0) & (isnan(vout) == 0) );
                
                % Get the subscripts for the found pixels in the input array.
                
                at = iot + isi - 1;
                bt = jot + jsi - 1;
                
                a = max([ones(size(at')); at'])';
                a = min([at'; ones(size(at')) * nPixels])';
                
                b = max([ones(size(bt')); bt'])';
                b = min([bt'; ones(size(bt')) * nScanlines])';
                
                sol = sub2ind(size(latitude), a, b);
                
                % Add the weight values and location values to the weights
                % and locations arrays at the point in output array
                % affected by this input value.
                
                for iNum=1:length(sol)
                    Num(sol(iNum)) = Num(sol(iNum)) + 1;
                    k = Num(sol(iNum));
                    
                    weights(k,a(iNum),b(iNum)) = vout(nn(iNum));
                    locations(k,a(iNum),b(iNum)) = sub2ind(size(latitude), iPixel, iScan);
                    
                    if locations(k,a(iNum),b(iNum)) > numel(latitude)
                        keyboard
                    end
                end
            end
        end
        
        fprintf('%f s to process iPixel %i\n', toc, iPixel)
        tic

    end
    
    fprintf('Took %f s to process for the entire run.\n', toc(tStart))
    
    % And save the results
    
    save( filename_out, 'filename_in', 'weights', 'locations')
    clear weights locations
end
