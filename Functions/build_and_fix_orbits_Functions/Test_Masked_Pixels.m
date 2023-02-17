function [Mask_Pixels_to_Discard, Masked_Pixels_to_Keep, Test_Counts] =  Test_Masked_Pixels(Debug_dot_product, inLiveScript, L, ...
    Test_Counts, iObject, SST_In_Object, Problem_Pixel_Mask_In_Object, Full_Mask_In_Object, Linear_Indices, Grad_X, Grad_Y, GMag_in_Object)
%  LONGEST_SEGMENT Test this object to determine if it is a mistakenly masked front.
%
% This function will skeletize the object defined by Problem_Pixel_Mask_In_Object,
% determine the local normal to the skeleton, calculate the dot product of the
% gradient of SST with the local normal for each point on the skeleton, determine
% the SST on a section along the local normal and then perform several tests to
% determine whether or not the mask for this object should be removed.
%
% INPUT
%%
% # Debug_dot_product - 1 if debug plots are to be produced for this object.
% # L - array with all objects numbers in it. This is only used if Debug_dot_product
% = 1;
% # iObject - the object number. Only uses this if Debug_dot_product = 1;
% # SST_In_Object - the SST field in which the object of interest is found.
% This array is slightly larger than the object. All of the remaining arrays are
% the same size as this ont.
% # Problem_Pixel_Mask_In_Object - this is an array of 1s object pixels and
% 0s.
% # Linear_Indices
% # Grad_X - the gradient in the direction of the 1st dimension.
% # Grad_Y - the gradient in the direction of the 2nd dimension.
% # Grad_Mag - the magnitude of the gradient.
%%
% OUTPUT
%%
% # dot_product - this is a vector of the normalized dot product of the local
% normal to the segment and the gradient vector; i.e., it is the cosine of the
% angle between these two vectors. The local normal to the segment is taken so
% that it points to the left when facing the direction in which the segment elements
% are increasing.
% # norm_sst_section - is a 2d matrix of the SST values along the local normal
% to the the segment. The length of the 1st dimension is the number of elements
% on the segment. The length of the 2nd dimension, npts_fit,  is the number of
% SST values taken along the normal. The sampling is nearest neighbor.
% Initialize return parameters in case have to leave early.

global Thresholds

global Skewness_Counts_Dilated_Good Skewness_Counts_Segment_Good iSkewness_Dilated_Good iSkewness_Segment_Good
global Skewness_Counts_Dilated_Bad Skewness_Counts_Segment_Bad iSkewness_Dilated_Bad iSkewness_Segment_Bad

% Initialize the output maks.

sz = size(Problem_Pixel_Mask_In_Object);
Masked_Pixels_to_Keep = zeros(sz);
Mask_Pixels_to_Discard = zeros(sz);

% Initialize control variables.

Debug = 0;

% % % dot_product = nan;
% % % norm_sst_section = nan;
% % % norm_Under_Dilated_Part_of_Object = nan;
% % % Percent_Good_Dot_Products = nan;
% % % percent_SST_in_range_a = nan;
% % % percent_SST_in_range_b = nan;

% Mask all pixels in SST_In_Object that are flagged but are not problem
% pixels.

bad_pixels = Full_Mask_In_Object;
bad_pixels(bad_pixels<0) = 0;
bad_pixels(bad_pixels>0) = 1;
bad_pixels = bad_pixels - Problem_Pixel_Mask_In_Object;
bad_pixels(bad_pixels<0) = 0;

SST_In_Object(bad_pixels==1) = nan;

%% Skeletize the object.

if Debug == 2
    global AxisFontSize TitleFontSize Trailer_Info
    AxisFontSize = 20;
    TitleFontSize = 30;
    Trailer_Info = '';
    
    pccpal = colormap(jet);
    pccpal(1,:) = [1 1 1];
    pccpal(256,:) = [.5 .5 .5];
    
    iFig_Debug = 501;
end

% % % tic
Segments = Skeletize_Segments(iObject, Problem_Pixel_Mask_In_Object);
% % % disp(['Object: ' num2str(iObject) ' - time: ' num2str(toc)])

if isempty(Segments(1).Pixels)  % Couldn't find a skeleton so leave the mask on.
    if Debug_dot_product
        disp(['Mask for object ' num2str(iSegment) ' will remain. No skeleton found for this object.'])
    end
    return
end

% Now associate a region in the input mask to each segment. Will need the
% mask of all really bad pixels not including problem pixels.

npts_fit = 9;
sample_distance = 1.5;
total_samples = 21;

sz = size(Problem_Pixel_Mask_In_Object);

Really_Bad = Full_Mask_In_Object - Problem_Pixel_Mask_In_Object;
Really_Bad(Really_Bad<0) = 0;
Really_Bad_Complement = imcomplement(Really_Bad);

% % % Mask_These_Pixels = zeros(sz);

iStart = 2;
for iSegment=1:length(Segments)
    
    % Create mask for this segment and dilate ==> Segment_Mask. Will
    % not use the entire segment for this; will truncate the first iStart-1
    % points and the same number of points at the end of the segment. Skip
    % this segment if less than iStart points.
    
    % % %     if length(Segments(iSegment).Pixels) < iStart
    % % %         Test_Counts.segment_fraction = Test_Counts.segment_fraction + 1;
    % % %
    % % %         if Debug_dot_product
    % % %             disp(['Mask for object/segment: ' num2str(iSegment) '/' num2str(iSegment) ' will be retained. Only ' num2str(iStart) ' poits on the segment'])
    % % %         end
    % % %     else
    
    iLoc = Segments(iSegment).Pixels(iStart:end-iStart+1,1);
    jLoc = Segments(iSegment).Pixels(iStart:end-iStart+1,2);
    
    temp_image = zeros(sz);
    temp_image(sub2ind(sz, iLoc, jLoc)) = 1;
    temp_image = imdilate( temp_image, strel('disk', 5));
    
    Segment_Mask = Problem_Pixel_Mask_In_Object .* temp_image;
    pixels_in_object = find(Segment_Mask == 1);
    segment_mask_count = length(pixels_in_object);
    
    SST_under_segment_mask = SST_In_Object;
    SST_under_segment_mask(Segment_Mask==0) = nan;
    
    Skewness_Segment = skewness(SST_under_segment_mask(:));

    if Debug == 2
        iFig_Debug = Plot_Masks( 1, iFig_Debug, 1, Problem_Pixel_Mask_In_Object, 'Problem_Pixel_Mask_In_Object');
        colormap(pccpal)
        hold on
        
        [x,y] = find(Problem_Pixel_Mask_In_Object==1);
        
        plot(Segments(iSegment).Pixels(:,1), Segments(iSegment).Pixels(:,2), 'ok', 'markersize',5, 'MarkerFaceColor','r')
        %             plot(x,y,'.k')
    end
    
    % Dilate the segment mask and remove the segment mask from the dilated
    % version. This will build a mask for pixels surrounding the segment
    % mask.
    
    temp_image = imdilate( Segment_Mask, strel('disk', 5));
    Segment_Mask_Dilated = temp_image - Segment_Mask;
    dilated_pixel_count = length(find(Segment_Mask_Dilated==1));
    
    Segment_Mask_Dilated_Final = Really_Bad_Complement .* Segment_Mask_Dilated;
    dilated_pixel_count_final = length(find(Segment_Mask_Dilated_Final==1));
        
% % %     Skewness_Segment = skewness(SST_In_Object(Segment_Mask==1));
    
    SST_Under_Final_Dilated_Mask = SST_In_Object .* Segment_Mask_Dilated_Final;
    SST_Under_Final_Dilated_Mask(SST_Under_Final_Dilated_Mask==0) = nan;

% % %     Skewness_Dilated = skewness(SST_Under_Final_Dilated_Mask(SST_Under_Final_Dilated_Mask~=0));    
    Skewness_Dilated = skewness(SST_Under_Final_Dilated_Mask(:));    
    
    Failed_Skewness_Test = 0;
    
    if sqrt(Skewness_Segment^2 + Skewness_Dilated^2) > Thresholds.skewness
        
        % Do a skewness test on the SST values in the segment mask. Do it
        % this way to avoid doing histograms if it passes the initial test.
        % This test addresses issues related to a thin filament of water of
        % one temperature in a region of different temperature.
        
        %         HIST1 = histcounts(SST_In_Object(Segment_Mask==1),[-2:0.5:33]);
% % %         hist_counts = histcounts(SST_In_Object(Segment_Mask_Dilated_Final==1),[-2:0.5:33]);
        hist_counts = histcounts(SST_Under_Final_Dilated_Mask,[-2:0.5:33]);
        
        hist_counts_sorted = sort(hist_counts);
        largest_values = mean(hist_counts_sorted(end-1:end));
        
        hist_counts_only = hist_counts(hist_counts>0);
        if length(hist_counts_only) < 2
            Failed_Skewness_Test = 1;
        elseif hist_counts_only(2) < largest_values/Thresholds.skewness_count_test
            Failed_Skewness_Test = 1;
        end
    end
    
    if Failed_Skewness_Test == 1
        Masked_Pixels_to_Keep = Masked_Pixels_to_Keep + Segment_Mask;
        
        iSkewness_Dilated_Bad = iSkewness_Dilated_Bad + 1;
        Skewness_Counts_Dilated_Bad(iSkewness_Dilated_Bad) = skewness(SST_Under_Final_Dilated_Mask(SST_Under_Final_Dilated_Mask~=0));
        
        iSkewness_Segment_Bad = iSkewness_Segment_Bad + 1;
        Skewness_Counts_Segment_Bad(iSkewness_Segment_Bad) = skewness(SST_In_Object(Segment_Mask==1));
        
        Test_Counts.skewness = Test_Counts.skewness + 1;
        
        if Debug_dot_product
            disp(['Mask for object/segment: ' num2str(iSegment) '/' num2str(iSegment) ' will be retained. Failed the dilated fraction test.'])
        end
    else
        
        if (dilated_pixel_count_final == 0) | (dilated_pixel_count_final/dilated_pixel_count < Thresholds.Percent_Good_in_Dilated_Mask)
            Masked_Pixels_to_Keep = Masked_Pixels_to_Keep + Segment_Mask;
            
% % %             SST_Under_Final_Dilated_Mask = SST_In_Object .* Segment_Mask_Dilated_Final;
            iSkewness_Dilated_Bad = iSkewness_Dilated_Bad + 1;
            Skewness_Counts_Dilated_Bad(iSkewness_Dilated_Bad) = skewness(SST_Under_Final_Dilated_Mask(SST_Under_Final_Dilated_Mask~=0));
            
            iSkewness_Segment_Bad = iSkewness_Segment_Bad + 1;
            Skewness_Counts_Segment_Bad(iSkewness_Segment_Bad) = skewness(SST_In_Object(Segment_Mask==1));
            
            Test_Counts.dilated_fraction = Test_Counts.dilated_fraction + 1;
            
            if Debug_dot_product
                disp(['Mask for object/segment: ' num2str(iSegment) '/' num2str(iSegment) ' will be retained. Failed the dilated fraction test.'])
            end
        else
% % %             SST_Under_Final_Dilated_Mask = SST_In_Object .* Segment_Mask_Dilated_Final;
            
            if Debug == 2
                iFig_Debug = Plot_Masks( 1, iFig_Debug, 1, Segment_Mask_Dilated, 'Segment_Mask_Dilated');
                colormap(pccpal)
                hold on
                
                [x,y] = find(Problem_Pixel_Mask_In_Object==1);
                
                plot(Segments(iSegment).Pixels(:,1), Segments(iSegment).Pixels(:,2), 'ok', 'markersize',5, 'MarkerFaceColor','r')
                plot(x,y,'.k')
            end
            
            % *********************************** Do two peak test ***********************************
            
            hh1_BinEdges = [-2:0.2:32];
            
            % Histogram the SST values under the dilated portion of the mask;
            % i.e., on either side of the object.
            
            hh1_Values = histcounts(SST_Under_Final_Dilated_Mask(:), hh1_BinEdges);
            
            % Find the peaks in this histogram.
            
            tt = islocalmax(hh1_Values);
            nn = find((tt > 0) & (hh1_Values > 2));
            
            % If less than two peaks, this object is a cloud; i.e., do not unmask.
            % If 2 or more peaks test to see if SST values under the object
            % fall between them. If it does (on average) set Temperature_Test_Mean
            % to 1 else it remains 0. Also test the standard deviation of the
            % SST values under the object versus those under the dilated
            % portion of the mask. Sigma under the object must be less than
            % twice that under the dilated portion of the mask. If so, set
            % Temperature_Test_Sigma to 1, 0 otherwise.
            
            if length(nn) > 1
                
                % Get the mean and sigma of the objects SST values.
                
                Mean_SST = nanmean(SST_In_Object(:));
                Sigma_SST_Base_Mask = nanstd(SST_In_Object(:));
                
                % Get the sigma of the SST values under the dilated portion of the
                % mask.
                
                Sigma_SST_Dilated_Mask = std(SST_Under_Final_Dilated_Mask(:),0,'omitnan');
                
                Lower_SST_Peak = hh1_BinEdges(nn(1));
                Upper_SST_Peak = hh1_BinEdges(nn(end)+1);
                
                if (Mean_SST > Lower_SST_Peak) & (Mean_SST < Upper_SST_Peak)
                    Temperature_Test_Mean = 1;
                else
                    Temperature_Test_Mean = 1000;
                end
                
                if Sigma_SST_Base_Mask < Sigma_SST_Dilated_Mask*2
                    Temperature_Test_Sigma = 1;
                else
                    Temperature_Test_Sigma = 1000;
                end
            else
% % %                 disp(['Segment # ' num2str(iSegment) ' of Object # ' num2str(iObject) ' does not have two peaks in the histogram under the dilated mask.'])
                Temperature_Test_Mean = 0;
                Temperature_Test_Sigma = 0;
            end
            
            % *********************************** End two peak test ***********************************
            
            
            % ************************** Do temperature range and variance tests ***********************
            
% % %             Min_Object_SST = min(SST_In_Object,[],'all','omitnan');
% % %             Max_Object_SST = max(SST_In_Object,[],'all','omitnan');
            Min_Object_SST = min(SST_under_segment_mask,[],'all','omitnan');
            Max_Object_SST = max(SST_under_segment_mask,[],'all','omitnan');
            Min_Dilated_Region_SST = min(SST_Under_Final_Dilated_Mask,[],'all','omitnan');
            Max_Dilated_Region_SST = max(SST_Under_Final_Dilated_Mask,[],'all','omitnan');
            
% % %             nn = length(find(SST_In_Object < Min_Dilated_Region_SST));
            nn = length(find(SST_under_segment_mask < Min_Dilated_Region_SST));
            Percentage_in_Object_Below_Min_in_Dilated_Region = 100 * nn / segment_mask_count;
            
            if Percentage_in_Object_Below_Min_in_Dilated_Region < Thresholds.Percentage_in_Object_1
                Test_Percentage_in_Object = 1;
            else
                Test_Percentage_in_Object = 0;
            end
            
            % Sort SST in dilated region and find the temperature defining
            % the lowest 5% of the SST values
            
            % % %         SST_D = SST_Under_Final_Dilated_Mask(isnan(SST_Under_Final_Dilated_Mask)==0);
            SST_D = SST_Under_Final_Dilated_Mask(SST_Under_Final_Dilated_Mask~=0);
            SST_D_sorted = sort(SST_D);
            SST5percent = SST_D_sorted(max(1,floor(length(SST_D_sorted)/20)));
            % % %         nn5percent = length(find(SST_In_Object SST_D_sorted));
            nn5percent = length(find( (SST_In_Object(Segment_Mask==1)<SST5percent) & (SST_In_Object(Segment_Mask==1)>SST_D_sorted(1))));
            Percentage_in_Object_Below_SST_5_in_Dilated_Region = 100 * nn5percent / segment_mask_count;
            
            if Percentage_in_Object_Below_SST_5_in_Dilated_Region < Thresholds.Percentage_in_Object_2
                Test_5_Percentage_in_Object = 1;
            else
                Test_5_Percentage_in_Object = 0;
            end
            
            % Now do the test on the variance in-out of object.
            
            Sigma_Object_SST = std(SST_In_Object,0,'all','omitnan');
            Sigma_Dilated_Region_SST = std(SST_Under_Final_Dilated_Mask,0,'all','omitnan');
            
            if Sigma_Object_SST < Sigma_Dilated_Region_SST
                Test_Sigma_in_Object = 1;
            else
                Test_Sigma_in_Object = 0;
            end
            
            % ****************>********* End temperature range and variance tests **********************
            
            % If failed the sigma and percentage tests skip to next object;
            % i.e., do not remove the mask.
            
            % % %             if (Test_Percentage_in_Object==0) | (Test_5_Percentage_in_Object==0)
            if (Test_Percentage_in_Object==0)
                Masked_Pixels_to_Keep = Masked_Pixels_to_Keep + Segment_Mask;
                
                iSkewness_Dilated_Bad = iSkewness_Dilated_Bad + 1;
                Skewness_Counts_Dilated_Bad(iSkewness_Dilated_Bad) = skewness(SST_Under_Final_Dilated_Mask(SST_Under_Final_Dilated_Mask~=0));
                
                iSkewness_Segment_Bad = iSkewness_Segment_Bad + 1;
                Skewness_Counts_Segment_Bad(iSkewness_Segment_Bad) = skewness(SST_In_Object(Segment_Mask==1));
                
                Test_Counts.sst_out_of_range = Test_Counts.sst_out_of_range + 1;
                
                if Debug_dot_product
                    disp(['Mask for object/segment: ' num2str(iSegment) '/' num2str(iSegment) ' will be retained. Failed the # clear in masks tests.'])
                end
            else
                
                % At each element of the sekelton, get the dot product of the gradient
                % vector with the local normal to the skeleton and get sections on the
                % local normal.
                
                [dot_product, norm_sst_section, norm_Under_Dilated_Part_of_Object] = ...
                    get_dot_product_and_norms( -1, SST_In_Object, Grad_X, Grad_Y, GMag_in_Object, Segments(iSegment).Pixels, SST_Under_Final_Dilated_Mask, ...
                    npts_fit, sample_distance, total_samples);
                
                % Determine the fraction of dot products that exceed the dot product threshold.
                
                if isempty(dot_product)
                    disp(['No dot product for object ' num2str(iSegment)])
                    Percent_Good_Dot_Products = [];
                else
                    nn = find(abs(dot_product) >= Thresholds.Dot_Product);
% % %                     Percent_Good_Dot_Products = length(nn) * 100 / length(dot_product);
                    Percent_Good_Dot_Products = length(nn) * 100 / length(dot_product(isnan(dot_product)==0));
                end
                
                % Test SST of object relative to SST on perpendiculars, away from the
                % object to determine whether or not the SST value within a couple of
                % pixels of the skeleton fall between the SST on either side.
                
                if isempty(norm_sst_section)
                    disp(['No dot product for object ' num2str(iSegment)])
                    percent_SST_in_range_a = [];
                    percent_SST_in_range_b = [];
                    
                    SST_in_range_a = [];
                    SST_in_range_b = [];
                else
                    total_samples_o2 = floor(total_samples / 2);
                    
                    i_central_1 = total_samples_o2;
                    i_central_2 = total_samples_o2 + 2;
                    
                    i_lower_1 = 1;
                    i_lower_2 = total_samples_o2 - 2;
                    
                    i_upper_1 = size(norm_sst_section,2) - total_samples_o2 + 3;
                    i_upper_2 = size(norm_sst_section,2);
                    
                    % Do two different tests for SST in range, one based on SST along the
                    % entire line and the second only on SSTs under the two masks.
                    % SST_in_range_a is a vector of the same length as the number of
                    % normals to the skeleton. Each value of the vector is the mean of the
                    % central 3 SST values on the section minus the mean of the
                    % total_samples_o2-2 values on the lower end of the section over the
                    % mean of the total_samples_o2-2 values on the lower end of the section
                    % minus the mean of the total_samples_o2-2 values on the lower end of
                    % the section:
                    %   (mean(SST_central) - mean(SST_lower)) /  (mean(SST_upper) - mean(SST_lower))
                    % Good values are between 0 and 1.
                    
                    temp_image_1 = norm_sst_section;
                    temp_image_1(temp_image_1==0) = nan;
                    temp_image_2 = norm_Under_Dilated_Part_of_Object;
                    temp_image_2(temp_image_2==0) = nan;
                    
                    if ~isempty(temp_image_1)
                        for ipc=1:size(temp_image_1,1)
                            SST_in_range_a(ipc) = (mean(temp_image_1(ipc,i_central_1:i_central_2),2,"omitnan") - mean(temp_image_1(ipc,i_lower_1:i_lower_2),2,"omitnan")) / ...
                                (mean(temp_image_1(ipc,i_upper_1:i_upper_2),2,"omitnan") - mean(temp_image_1(ipc,i_lower_1:i_lower_2),2,"omitnan"));
                        end
                        % % %                         percent_SST_in_range_a = length(find(abs(SST_in_range_a)<1))*100 / size(norm_sst_section,1);
                        nGood = sum(isnan(SST_in_range_a)==0);
                        if nGood > 0
                            percent_SST_in_range_a = length(find(abs(SST_in_range_a)<1))*100 / nGood;
                        else
                            percent_SST_in_range_a = 0;
                        end
                    else
                        percent_SST_in_range_a = 0;
                        SST_in_range_a = [];
                    end
                    
                    if ~isempty(temp_image_1) & ~isempty(temp_image_2)
                        for ipc=1:size(temp_image_1,1)
                            SST_in_range_b(ipc) = (mean(temp_image_1(ipc,i_central_1:i_central_2),2,"omitnan") - mean(temp_image_2(ipc,1:total_samples_o2),2,"omitnan")) / ...
                                (mean(temp_image_2(ipc,i_upper_1-3:i_upper_2),2,"omitnan") - mean(temp_image_2(ipc,1:total_samples_o2),2,"omitnan"));
                        end
                        % % %                         percent_SST_in_range_b = length(find(abs(SST_in_range_b)<1))*100 / size(norm_sst_section,1);
                        nGood = sum(isnan(SST_in_range_b)==0);
                        if nGood > 0
                            percent_SST_in_range_b = length(find(abs(SST_in_range_b)<1))*100 / nGood;
                        else
                            percent_SST_in_range_b = 0;
                        end
                    else
                        percent_SST_in_range_b = 0;
                        SST_in_range_b = [];
                    end
                end
                
                % Get the normalized dot product
                
                Normalized_Vector_Mean_Gmag = sqrt(nansum(Grad_X(pixels_in_object))^2 + nansum(Grad_Y(pixels_in_object))^2) / nansum(GMag_in_Object(pixels_in_object));
                
                %% Now do the main tests, main because we have already done some.
                
                Grad_Test_1 = Percent_Good_Dot_Products > Thresholds.Percent_Good_Dot_Products;
                
                SST_Test_2a = percent_SST_in_range_a > Thresholds.Percent_SST_in_Range;
                SST_Test_2b = percent_SST_in_range_b > Thresholds.Percent_SST_in_Range;
                SST_Test_2 = SST_Test_2a | SST_Test_2b;
                
                SST_Test_3a = Temperature_Test_Mean == 1;
                SST_Test_3b = Temperature_Test_Sigma == 1;
                SST_Test_3 = SST_Test_3a & SST_Test_3b;
                
                SST_Tests = SST_Test_2 | SST_Test_3;
                
                if Grad_Test_1==0 | SST_Tests==0
                    % Here if failed the gradient and/or the SST tests; mask will be kept.
                    
                    Masked_Pixels_to_Keep = Masked_Pixels_to_Keep + Segment_Mask;
                    
                    iSkewness_Dilated_Bad = iSkewness_Dilated_Bad + 1;
                    Skewness_Counts_Dilated_Bad(iSkewness_Dilated_Bad) = skewness(SST_Under_Final_Dilated_Mask(SST_Under_Final_Dilated_Mask~=0));
                    
                    iSkewness_Segment_Bad = iSkewness_Segment_Bad + 1;
                    Skewness_Counts_Segment_Bad(iSkewness_Segment_Bad) = skewness(SST_In_Object(Segment_Mask==1));
                    
                    Test_Counts.gradient_and_sst = Test_Counts.gradient_and_sst + 1;
                    
                    if Debug_dot_product
                        disp(['Mask for object/segment: ' num2str(iSegment) '/' num2str(iSegment) ' will be retained. Failed the gradient tests.'])
                    end
                else
                    % Here if passed all tests; mask will be discarded.
                    
                    % Skip this last test for now; maybe for good.
                    
                    if 0==1
                        
                        % Do one final test to locate possible bad pixels in
                        % this segment mask and to keep them on; i.e., do not
                        % discard them.
                        
                        SST_under_segment_mask = SST_In_Object;
                        SST_under_segment_mask(Segment_Mask==0) = nan;
                        [hist_counts, hist_sst] = histcounts(SST_under_segment_mask,[floor(min(SST_under_segment_mask,[],'all','omitnan')):0.5:ceil(max(SST_under_segment_mask,[],'all','omitnan'))]);
                        
                        hist_counts_sorted = sort(hist_counts);
                        largest_values = mean(hist_counts_sorted(end-1:end));
                        
                        if largest_values >= Thresholds.hist_max
                            bin_count_exceed_hist_min = find(hist_counts > Thresholds.hist_min);
                            if ~isempty(bin_count_exceed_hist_min)
                                [iMax, jMax] = size(Segment_Mask);
                                
                                SST_threshold = hist_sst(bin_count_exceed_hist_min(1));
                                [ipcc, jpcc] = find(SST_under_segment_mask < SST_threshold);
                                
                                for i=1:length(ipcc)
                                    Segment_Mask(max(ipcc(i)-1,1):min(ipcc(i)+1,iMax), max(jpcc(i)-1,1):min(jpcc(i)+1,jMax)) = 0;
                                end
                            end
                        end
                    end
                    
                    Mask_Pixels_to_Discard = Mask_Pixels_to_Discard + Segment_Mask;
                    
                    iSkewness_Dilated_Good = iSkewness_Dilated_Good + 1;
                    Skewness_Counts_Dilated_Good(iSkewness_Dilated_Good) = skewness(SST_Under_Final_Dilated_Mask(SST_Under_Final_Dilated_Mask~=0));
                    
                    iSkewness_Segment_Good = iSkewness_Segment_Good + 1;
                    Skewness_Counts_Segment_Good(iSkewness_Segment_Good) = skewness(SST_In_Object(Segment_Mask==1));
                    
                    if Debug_dot_product
                        disp(['Mask for object/segment: ' num2str(iSegment) '/' num2str(iSegment) ' will be removed. All tests passed.'])
                    end
                end % Gradient tests
            end % Percentage good in object.
        end % Test on fraction of good pixels under dilated mask.
    end % Skewness tests on SST in segment mask and dilated mask
    % % %     end % Test on fraction in segment mask.
end  % Loop over segments:: iSegment=1:length(Segments)

%% Debug plot

if Debug == 2
    pccpal(1,:) = [1 1 1];
    pccpal(256,:) = [.5 .5 .5];
    iFig = Plot_Masks( 1, iFig, 1, Object_Mask, 'Object_Mask'); hold on
    for iSeg=1:length(Segments)
        temp_image = zeros(sz);
        temp_image(sub2ind(sz, Segments(iSeg).Pixels(2:end-1,1), Segments(iSeg).Pixels(2:end-1,2))) = 1;
        temp_image = imdilate( temp_image, strel('disk', 5));
        [x,y] = find(temp_image==1);
        plot(Segments(iSeg).Pixels(:,1), Segments(iSeg).Pixels(:,2), 'ok', 'markersize',5, 'MarkerFaceColor','r')
        plot(x,y,'.k')
    end
    colormap(pccpal)
end

end