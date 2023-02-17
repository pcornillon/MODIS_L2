function [orbit_weights, orbit_locations] = Build_weight_and_location_arrays( ancillary_data_dir, base_scan_line_string, type_of_weights, one_to_save, region_end)
% Build_weight_and_location_arrays - for fast regridding
%
% This function will read the 11 scan line array for the weights and
%  locations of obtained from one image and generate new weight and
%  location arrays for the entire orbit. Actually, it will do so for a
%  hypothetical orbit that is longer than any of the orbits likely to be
%  encountered. 
%
% For the 'inidividual' mode the weights simply repeat every 10 scan line, 
%  the 11th scan line in the set read in is ignored since it is a repeat of 
%  the first scan line with the exception of the locations. The locations 
%  are augmented for each each set of 10 scan line to point to the
%  appropriate locations.
%
% For the 'merged' mode, sets of 11 weights and locations are read in for
%  every 500th or so scan line and the new weight and location arrays are
%  parsed together from these. Since I'm going with the 'individual' mode,
%  I have not focussed on the 'merged' mode - be careful if you want to use
%  it.
%
% INPUT
%   ancillary_data_dir - location of the input weight and location files. 
%   base_scan_line_string - a string for the scan line for which the weights to
%    be used were created. These are strings like: '03501' or '20001'.
%   type_of_weights - if 'individual', will build the weights and locations
%    for an orbit based on a given set of 10 detector weights. If 'merged',
%    will build the weights and locations for based on weights for the
%    nearest region for which they were generated. Will use the weights for
%   one_to_save - 0, simply return the new arrays; 1 save them as well. 
%   region_end - the end point of the regions into which the orbits have
%    been divided. There are typically 4 regions, a polar region, a lower
%    latitude region, a second polar region and a final polar region. This
%    is only used to get the maximum length of an orbit for the 'merged'
%    version. No need to enter it if the 'individual' version. 
%    
% OUTPUT
%   orbit_weights - these are the weights for the complete orbit, either
%    merged from a set of weights or repeated for just one weight.
%   orbit_locations - same for the locations associated with the weights.
%
% EXAMPLE
%

switch type_of_weights
    
    case 'individual'
        % Will generate weights and locations arrays to be bigger than the longest
        % orbit. Orbits seem to range in length from 40261 to 40271 so will make
        % the weights and locations arrays 40301 long
        
        nReps = 4040;
        
        % Read in the weights and locations.
        
%         fi_weights = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weights_' base_scan_line_string '.mat'];
        fi_weights = [ancillary_data_dir 'Data/weights_' base_scan_line_string '.mat'];
        aa = load(fi_weights);
        
        % Get maximum number of input pixels contributing to put elements.
        
        [nMax, mElements, mScans] = size(aa.weights);
        
        % % % if nElements ~= mElements
        % % %     fprintf(['\n***** The number of elements/scan line in the weights ' ...
        % % %         'array, %i, \n is not equal to the number of elements on scan lines in the orbit, %i \n'], ...
        % % %         mElements, nElements)
        % % %     keyboard
        % % % end
        
        % Now generate the weights and locations arrays to use for the entire orbit.
        
        orbit_weights = zeros( nMax, mElements, nReps*10);
        orbit_locations = zeros( nMax, mElements, nReps*10);
        
        % The script that generated weights and locations did so for 11 scan lines
        % so as to use the first one in a group of 10 detectors to the first one in
        % the next group of detectors but we are only interested in the values for
        % the first 10.
        
        weights_temp = aa.weights(:,:,1:10);
        locations_temp = aa.locations(:,:,1:10);
        
        % % % locations_temp(2,:,:) = locations_temp(2,:,:) + 13540;
        % % % locations_temp(3,:,:) = locations_temp(3,:,:) + 13540;
        
        % The index location of points in the array needs to be augmented by number
        % of elements in a scan line times the ten scan lines.
        
        % % % nInc = numel(weights_temp);
        nInc = numel(weights_temp) / nMax;
        
        for iRep=1:nReps
            orbit_weights(:,:,10*(iRep-1)+1:10*(iRep-1)+10) = weights_temp;
            orbit_locations(:,:,10*(iRep-1)+1:10*(iRep-1)+10) = (iRep-1)*nInc + double(locations_temp);
        end
        
        if one_to_save
            save(['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/Orbit_Weights_and_Locations_' base_scan_line_string], 'augmented*', 'fi_*', '-v7.3')
        end
        
    case 'merged'
        
        %% This portion of the script will build the weights and locations for an orbit based on the local fits.
        
        % First generate the list of starting scanlines for 10 detector
        % groups for which weights exist.
        
        weights_filelist = dir('/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weight*');
        
        weights_to_exclude = [];
        jWeight = 0;
        for iWeight=1:length(weights_filelist)
            if sum(weights_to_exclude == iWeight) == 0                
                Name = weights_filelist(iWeight).name;

                nn_ = strfind(Name, '_');
                nn_period = strfind(Name, '.');
                
                jWeight = jWeight + 1;
                base_scan_line_string{jWeight} = Name(nn_+1:nn_period-1);
                base_scan_line(jWeight) = str2num(base_scan_line_string{jWeight});
            end
        end
% % %         % First get the list of weights and locations for 11 scan line segments.
% % %         
% % %         filelist = dir('/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weights_*.mat');
% % %         
% % %         for iSegment=1:length(filelist)
% % %             nn = strfind(filelist(iSegment).name, '_') + 1;
% % %             base_scan_line_s(iSegment) = convertCharsToStrings(filelist(iSegment).name(nn:nn+4));
% % %             base_scan_line(iSegment) = str2num(base_scan_line_s(iSegment));
% % %         end
        
        % Now get the range of scans to cover with each weight/location set.
        % After the intermediate points are set the last break point to the end
        % of the array.
        
        seg_break(1) = 1;
        for iSegment=1:length(base_scan_line)-1
            seg_break(iSegment+1) = (base_scan_line(iSegment) + base_scan_line(iSegment+1)) / 2;
        end
        seg_break(iSegment+2) = region_end(end);
        
        % Build the weights and locations for an orbit.
        
        for iSegment=1:length(base_scan_line)
            
            % Get the start for this segment and the number of 10 scanline segments.
            
            seg_start = floor(seg_break(iSegment)/10) + 1;
            seg_length = floor(seg_break(iSegment+1)/10) - seg_start;
            % % %         num_10_segs = seg_length / 10;
            
            % Read in the 10 scanline weights/locations for this segment
            
            fi_weights = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weights_' base_scan_line_string{iSegment} '.mat'];
            aa = load(fi_weights);
            
            % Get maximum number of input pixels contributing to put elements.
            
            [nMax, mElements, mScans] = size(aa.weights);
            
            % Populate the 10 scanline segments
            
            weights_temp = zeros(5,mElements,mScans-1);
            weights_temp(1:nMax,:,:) = aa.weights(:,:,1:10);
            
            locations_temp = zeros(5,mElements,mScans-1);
            locations_temp(1:nMax,:,:) = aa.locations(:,:,1:10);
            
            nInc = numel(weights_temp) / nMax;
            for iRep=seg_start:seg_start+seg_length
                orbit_weights(:,:,10*(iRep-1)+1:10*(iRep-1)+10) = weights_temp;
                orbit_locations(:,:,10*(iRep-1)+1:10*(iRep-1)+10) = (iRep-1)*nInc + double(locations_temp);
            end
        end
        
        if one_to_save
            save('/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/Orbit_Weights_and_Locations_merged', 'augmented*', 'fi_*', '-v7.3')
        end
        
    otherwise
        fprintf('\n******\n\nYou entered type_of_weights as %s. It must be either ''individual'' or ''merged''.\n', type_of_weights)
        keyboard
end

