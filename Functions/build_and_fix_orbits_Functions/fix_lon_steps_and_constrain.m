function [lonArray, nn, mm, shiftBy] = fix_lon_steps_and_constrain(Case, lonArrayIn, nn, mm, shiftBy)
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
%   shiftBy: If the range of longitudes passed to ll2ps is < 360 but the
%    max longitude > 360 or the min longitude < -360, will shift longitudes
%    by this amount--or unshift them later. Only relevant for calls to
%    either constrainLongitude or unconstrainLongitude.
%
% OUTPUT
%   lonArray: the longitude array constrained to be between -360 and 360.
%   nn: the elements of lonArray that were shifted up 360 degrees.
%   mm: the elements of lonArray that were shifted down 360 degrees.
%   shiftBy: same as the input value except output for unconstrainLongotude. 
%
%  CHANGE LOG
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/13/2024 - Initial version - PCC
%   1.0.1 - 5/13/2024 - Added versioning. Also fixed portion of the
%           function that shifts longitudes around. The problem was that it
%           was shifting the bulk of the good values if they were less than
%           the total longitudes, which occurred wehn there were missing
%           longitudes. This shouldn't happen but does when there are bad
%           granules - PCC

global version_struct
version_struct.fix_lon_steps_and_constrain = '1.0.1';

% binCountThreshold is the number of consecutive 0s in the histogram ouput
% of lonArray that define an acceptable gap, one for which all values either
% above or below will be shifted by +/- 360 degrees.

binCountThreshold = 10;
lonArray = lonArrayIn;

[mpixels, nscans] = size(lonArray);

% longitude values can't be less than -360 or probably larger than 360
% for the ll2p functions so will shift all values < -360 up by 360 and
% those > 360 down by 360.

nn = [];
mm = [];
shiftBy = [];

switch Case
    
    case 'fixSteps'
        %% Recast longitude to not go from -180 to + 180
        
        lon_step_threshold = 190;

        indN1 = 18821;
        indN2 = 19681;
 
        nadirPixel = ceil(mpixels / 2);
               
        % Start by fixing the along-track direction. Will work on the
        % along-track pixels first.
       
        diffcol = diff(lonArray, 1, 2);
        
        for iCol=1:mpixels
            
            xx = lonArray(iCol,:);
            
            [~, jPixStep] = find( abs(diffcol(iCol,:)) > lon_step_threshold);
            
            if ~isempty(jPixStep)
                
                clear iPixStep lonStep
                mPix = 0;
                for kPix=1:length(jPixStep)

                    mPix = mPix + 1;
                    iPixStep(mPix) = jPixStep(kPix);

                    lonStep(kPix) = -sign(xx(jPixStep(kPix)+1) - xx(jPixStep(kPix))) * 360;
                    lonStep(mPix) = lonStep(kPix);

                    % Deal with consecutive steps in the same direction.

                    if kPix > 1

                        if lonStep(kPix) == lonStep(kPix-1)
                            mPix = mPix + 1;
                            iPixStep(mPix) = jPixStep(kPix);
                            
                            lonStep(mPix) = lonStep(kPix) + lonStep(kPix-1);
                        end
                    end
                end

                jPixStep = iPixStep;

                if ~isempty(jPixStep)

                    % Now get steps excluding ones between indN1 and indN2
                    
                    llpix = find( (jPixStep<indN1) | (jPixStep>indN2) );
                    if ~isempty(llpix)
                        jPixStep = jPixStep(llpix);
                        lonStep = lonStep(llpix);
                    end
                end
                
                % If number of jPixStep elements is odd, add one more element
                % corresponding to the number of scans in the orbit. We don't need
                % to add the last lonStep, since it wouldn't be used.
                
                if ~isempty(jPixStep)
                    if rem(length(jPixStep),2)
                        jPixStep(length(jPixStep)+1) = length(xx);
                    end
                    
                    for ifix=1:2:length(jPixStep)
                        locs2fix = [jPixStep(ifix)+1:jPixStep(ifix+1)];
                        
                        xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
                    end
                end
                
                lonArray(iCol,:) = xx;
            end
        end
        
        % Now fix steps in the along-scan direction. The trick here is to
        % fix from the nadir track out since this track does not go over
        % the poles. Do the scans on the right side of the orbit first,
        % then the left side (right when looking in the direction in which
        % the satellite is moving.
        
        for iRow=1:nscans
            xx = lonArray(nadirPixel:end,iRow);
            diffrow = diff(xx);
            iPixStep = find(abs(diffrow) > lon_step_threshold);
            if ~isempty(iPixStep)
                for kPix=1:length(iPixStep)
                    lonStep(kPix) = -sign(xx(iPixStep(kPix)+1) - xx(iPixStep(kPix))) * 360;
                end
                if rem(length(iPixStep),2)
                    iPixStep(length(iPixStep)+1) = length(xx);
                end
                for ifix=1:2:length(iPixStep)
                    locs2fix = [iPixStep(ifix)+1:iPixStep(ifix+1)];
                    xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
                end
            end
            lonArray(nadirPixel:end,iRow) = xx;
        end
        
        for iRow=1:nscans
            xx = lonArray(1:nadirPixel,iRow);
            diffrow = diff(xx);
            iPixStep = find(abs(diffrow) > lon_step_threshold);
            if ~isempty(iPixStep)
                
                % Reverse the order since we are going from nadir.
                
                iPixStep = flip(iPixStep);
                
                clear lonStep
                for kPix=1:length(iPixStep)
                    if xx(iPixStep(kPix)+1) > xx(iPixStep(kPix))
                        lonStep(kPix) = 360;
                    else
                        lonStep(kPix) = -360;
                    end
                end
                if rem(length(iPixStep),2)
                    iPixStep(length(iPixStep)+1) = 1;
                end
                for ifix=1:2:length(iPixStep)
                    locs2fix = [iPixStep(ifix+1):iPixStep(ifix)];
                    xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
                end
            end
            lonArray(1:nadirPixel,iRow) = xx;
        end

        % Now move outliers, which seem to have escaped the above.

        numShifts = 0;
        while 1==1

            % Make sure that were not in an infinite loop.

            numShifts = numShifts + 1;
            if numShifts > 4
                fprintf('Have shifted histograms >4 times. Maybe in a loop, breaking out of shifts.\n')
                break
            end

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
            else
                break
            end
        end

        % Now shift the entire longitude range if too positive or too negative.

        if min(lonArray(:)) < -360
            lonArray = lonArray + 360;
        elseif max(lonArray) > 360
            lonArray = lonArray - 360;
        end
        
        % Are there any issues at this point?

        if (min(lonArray) < -360) | (max(lonArray) > 360)
            fprintf('Longitude values range from %f to %f, which may result in an error from ll2 function.\n', min(lonArray), max(lonArray))
        end

        %% Constrain longitudes for ll2psx

    case 'constrainLongitude'
        
        % Shift up or down if the range of values is less than 360 and
        % either the max value > 360 or the min value < -360.

        minLon = min(lonArray,[],'all','omitnan');
        maxLon = max(lonArray,[],'all','omitnan');

        lonSep = maxLon - minLon;
        if lonSep < 360
            
            if maxLon > 360
                shiftBy = 360 * floor(maxLon / 360);
                lonArray = lonArray - shiftBy;
            elseif minLon < -360
                shiftBy = 360 * (floor(maxLon / 360) + 1);
                lonArray = lonArray + shiftBy;
            end
        end

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

            nn_nan = find(isnan(lonArray) == 0);
            
            % If the number of elements found is less than 1/2, then shift these
            % up, otherwise find the ones > edgeToUse and shift them down.
            
            if length(nn) < nn_nan / 2
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

        if abs(shiftBy) ~= 0
            lonArray = lonArray + shiftBy;
        end
        
end

end

