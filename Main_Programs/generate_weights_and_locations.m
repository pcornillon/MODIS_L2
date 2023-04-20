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
        filename_out = ['~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/' filename_in(nn+7:end) '_weights'];
        
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
            
    latitude = ncread(filename_in, 'latitude');
    regridded_latitude = ncread(filename_in, 'regridded_latitude');
    longitude = ncread(filename_in, 'longitude');
    regridded_longitude = ncread(filename_in, 'regridded_longitude');
    
    % Make sure that there are not nan's in the input.
    
    nn = find(isnan(latitude)==1);
    if ~isempty(nn)
        fprintf('Sorry but nans in this file; griddata does not like this. Returning\n')
        weights = nan;
        locations = nan;
        return
    end
    
    % Intialize output arrays.
    
    weights = single(nan(9,size(latitude,1),size(latitude,2)));
    locations = single(nan(9,size(latitude,1),size(latitude,2)));
    
    % Now get the weights and locations
    
    tStart = tic;
    
    for iPix=4:size(latitude,1)-4
        tic
        for iScan=4:size(latitude,2)-4
            
            isi = iPix-3;
            iei = iPix+3;
            
            jsi = iScan-3;
            jei = iScan+3;
            
            iso = max([1 iPix-15]);
            ieo = min([iPix+15 size(latitude,1)]);
            
            jso = max([1 iScan-15]);
            jeo = min([iScan+15 size(latitude,2)]);
            
            vin = zeros(7,7);
            vin(4,4) = 1;
            
            vout = griddata( longitude(isi:iei,jsi:jei), latitude(isi:iei,jsi:jei), vin, regridded_longitude(iso:ieo,jso:jeo), regridded_latitude(iso:ieo,jso:jeo));
            
            [iot, jot] = find(vout>0);
            sol = sub2ind(size(vout), iot, jot);
            
            so = sub2ind(size(latitude), iso+iot-1, jso+jot-1);
            
            [wo, wio] = sort(vout(sol), 'desc');
            
            num_to_process = min([9 length(sol)]);
            % %             fprintf('More than 9 hist for (iPix, iScan) = (%i, %i)\n', iPix, iScan)
            % %         else
            
            for k=1:num_to_process
                weights( k, iPix, iScan) = vout(sol(wio(k)));
                locations( k, iPix, iScan) = so(wio(k));
            end
        end
        fprintf('Took %5.2f s to process for iPix = %i\n', toc, iPix)
    end
    
    fprintf('Took %f s to process for the entire run.\n', toc(tStart))
    
    % And save the results
    
    save( filename_out, 'filename_in', 'weights', 'locations')
    clear weights locations
end
