function [lonArray, nn, mm] = fix_lon_steps_and_constrain(Case, lonArrayIn, nn, mm)
% fix_lon_steps_and_constrain - shifts longitudes to elminiate steps and constrain longitudes to -360 to +360 for ll2 algorithms - PCC
%
% This function takes a input an array of longitude values and then
% constrains the array to -306 to 360 by adding and subtracting 360 to
% values that fall outside of this range. It's needed because the ll2ps2ll
% algorithms do not accept values outside of these limits. It will result
% in some regridding problems but not severe, especially since there is so
% little water in the regions where ll2ps2ll are being used.
%
% INPUT
%   Case: 'fixSteps' to shift longitudes to address steps in input
%    longitude array; 'constrainLongitude' to constrain lonArray between
%    -360 and 360 and 'unconstrainLongitude' to add and subtract 360 where
%    appropriate. 
%   lonArray: the longitude array to be constrained.
%   nn: the elements of lonArray that were shifted up 360 degrees. This
%    variable is empty if constrainLongitude, otherwise, it is the value
%    written out when this function was called with constrainLongitude.
%   mm: similarly, except for values shifted down 360 degrees.
%
% OUTPUT
%   lonArray: the longitude array constrained to be between -360 and 360.
%   nn: the elements of lonArray that were shifted up 360 degrees.
%   mm: the elements of lonArray that were shifted down 360 degrees.


% binCountThreshold is the number of consecutive 0s in the histogram ouput
% of lonArray that define an acceptable gap, one for which all values either
% above or below will be shifted by +/- 360 degrees.

binCountThreshold = 10;
lonArray = lonArrayIn;

% longitude values can't be less than -360 or probably larger than 360
% for the ll2p functions so will shift all values < -360 up by 360 and
% those > 360 down by 360.

nn = [];
mm = [];

switch Case
    
    case 'fixSteps'
        %% Recast longitude to not go from -180 to + 180
        
        lon_step_threshold = 190;

        indN1 = 18821;
        indN2 = 19681;
 
        [mpixels, nscans] = size(lonArray);
        nadirPixel = ceil(mpixels / 2);
               
        % Start by fixing the along-track direction. Will work on the
        % along-track pixels first.
       
        diffcol = diff(lonArray, 1, 2);
        
        for iCol=1:mpixels
            
            xx = lonArray(iCol,:);
            
            [~, jpix] = find( abs(diffcol(iCol,:)) > lon_step_threshold);
            
            if ~isempty(jpix)
                                
                for kPix=1:length(jpix)
                    lonStep(kPix) = -sign(xx(jpix(kPix)+1) - xx(jpix(kPix))) * 360;
                end
                
                if ~isempty(jpix)
                    
                    % Now get steps excluding ones between indN1 and indN2
                    
                    llpix = find( (jpix<indN1) | (jpix>indN2) );
                    if ~isempty(llpix)
                        jpix = jpix(llpix);
                        lonStep = lonStep(llpix);
                    end
                end
                
                % If number of jpix elements is odd, add one more element
                % corresponding to the number of scans in the orbit. We don't need
                % to add the last lonStep, since it wouldn't be used.
                
                if ~isempty(jpix)
                    if rem(length(jpix),2)
                        jpix(length(jpix)+1) = length(xx);
                    end
                    
                    for ifix=1:2:length(jpix)
                        locs2fix = [jpix(ifix)+1:jpix(ifix+1)];
                        
                        xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
                    end
                end
                
                lonArray(iCol,:) = xx;
            end
        end
        
        % Now fix steps in the along-scan dirctions. The trick here is to
        % fix from the nadir track out since this track does not go over
        % the poles. Do the scans on the right side of the orbit first,
        % then the left side (right when looking in the direction in which
        % the satellite is moving.
        
        for iRow=1:nscans
            xx = lonArray(nadirPixel:end,iRow);
            diffrow = diff(xx);
            ipix = find(abs(diffrow) > lon_step_threshold);
            if ~isempty(ipix)
                for kPix=1:length(ipix)
                    lonStep(kPix) = -sign(xx(ipix(kPix)+1) - xx(ipix(kPix))) * 360;
                end
                if rem(length(ipix),2)
                    ipix(length(ipix)+1) = length(xx);
                end
                for ifix=1:2:length(ipix)
                    locs2fix = [ipix(ifix)+1:ipix(ifix+1)];
                    xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
                end
            end
            lonArray(nadirPixel:end,iRow) = xx;
        end
        
        for iRow=1:nscans
            xx = lonArray(1:nadirPixel,iRow);
            diffrow = diff(xx);
            ipix = find(abs(diffrow) > lon_step_threshold);
            if ~isempty(ipix)
                
                % Reverse the order since we are going from nadir.
                
                ipix = flip(ipix);
                
                clear lonStep
                for kPix=1:length(ipix)
                    if xx(ipix(kPix)+1) > xx(ipix(kPix))
                        lonStep(kPix) = 360;
                    else
                        lonStep(kPix) = -360;
                    end
                end
                if rem(length(ipix),2)
                    ipix(length(ipix)+1) = 1;
                end
                for ifix=1:2:length(ipix)
                    locs2fix = [ipix(ifix+1):ipix(ifix)];
                    xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
                end
            end
            lonArray(1:nadirPixel,iRow) = xx;
        end
        
        % Now shift the entire longitude range if too positive or too negative.
        
        if min(lonArray(:)) < -360
            lonArray = lonArray + 360;
        elseif max(lonArray) > 360
            lonArray = lonArray - 360;
        end
        
        % Now move outliers, which seem to have escaped the above.
        
        [Values, Edges] = histcounts(lonArray);
        
        nn = find(Values > 0);
        
        cc = 0;
        for jBin=nn(1):nn(end)
            iBin = nn(1) + jBin - 1;
            
            if Values(iBin) == 0
                cc = cc + 1;
                if cc > 10
                    edgeToUse = Edges(iBin);
                    break
                end
            else
                cc = 0;
            end
        end
        
        % If cc >= 10, it found a pretty long area with no values. That means that
        % there are likely outliers so we need to shift them.
        
        if cc >= 10
            nn = find(lonArray < edgeToUse);
            
            % If the number of elements found is less than 1/2, then shift these
            % up, otherwise find the ones > edgeToUse and shift them down.
            
            if length(nn) < nscans * mpixels / 2
                lonArray(nn) = lonArray(nn) + 360;
            else
                nn = find(lonArray > edgeToUse);
                lonArray(nn) = lonArray(nn) - 360;
            end
        end
        
        if (min(lonArray) < -360) | (max(lonArray) > 360)
            fprintf('Longitude values range from %f to %f, which is going to results in an error from ll2 function.\n', min(lonArray), max(lonArray))
        end
        
%% Constrain longitudes for ll2psx
        
    case 'constrainLongitude'
        
        % Here to shift values up or down by 360 degrees.
        
        nn = find(lonArray < -360);
        mm = find(lonArray > 360);
        
        if ~isempty(nn)
            lonArray(nn) = lonArray(nn) + 360;
        end
        
        if ~isempty(mm)
            lonArray(mm) = lonArray(mm) - 360;
        end
        
        % Now move outliers, which seem to have escaped the above.
        
        [Values, Edges] = histcounts(lonArray);
        
        nn = find(Values > 0);
        
        cc = 0;
        for jBin=nn(1):nn(end)
            iBin = nn(1) + jBin - 1;
            
            if Values(iBin) == 0
                cc = cc + 1;
                if cc > binCountThreshold
                    edgeToUse = Edges(iBin);
                    break
                end
            else
                cc = 0;
            end
        end
        
        % If cc >= 10, it found a pretty long area with no values. That means that
        % there are likely outliers so we need to shift them.
        
        if cc >= 10
            nn = find(lonArray < edgeToUse);
            
            % If the number of elements found is less than 1/2, then shift these
            % up, otherwise find the ones > edgeToUse and shift them down.
            
            if length(nn) < nscans * mpixels / 2
                lonArray(nn) = lonArray(nn) + 360;
            else
                nn = find(lonArray > edgeToUse);
                lonArray(nn) = lonArray(nn) - 360;
            end
        end

%% Unconstrain longitudes for ll2psx

    case 'unconstrainLongitude'
        
        % Now need to undo the shifting around that was done to accommodate ll2
        
        if ~isempty(nn)
            lonArray(nn) = lonArray(nn) - 360;
        end
        
        if ~isempty(mm)
            lonArray(mm) = lonArray(mm) + 360;
        end
        
end

end

