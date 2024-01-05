function [Final_Mask] = fix_MODIS_full_orbit( file_in, longitude, latitude, SST_In, Qual_In, flags_sst, sstref, Month);
% % % function     [Final_Mask, Test_Counts, FracArea, nnReduced] = fix_MODIS_full_orbit( file_in, longitude, latitude, SST_In, Qual_In, flags_sst, sstref, Month);
% % % function [Figno Final_Mask, Test_Counts, length_FracArea, length_nnReduced, Total_Elapsed_Time] = Fix_MODIS_Mask_New( Figno, file_in, imdilate_flag, objects_to_inspect)
% Fix_MODIS_Mask - unflag pixels improperly flagged as bad because of a local high gradients - PCC
%
% This script goes through the steps to clean up problems associated with 
% flagging of high gradient regions as being of poor quality. The script 
% consists of n basic steps:
%
% STEP 1: Get the data
%   Read the input SST, reference SST and l2_flags fields. l2_flags is an int16 field.
%   Each bit in each word in this field corresponds to test for SST pixel
%   quality. The short hand version of these tests is:
%
%      Meanings = { 'ISMASKED'   'BTBAD'      'BTRANGE'   'BTDIFF'    'SSTRANGE' ...
%                   'SSTREFDIFF' 'SST4DIFF'   'SST4VDIFF' 'BTNONUNIF' 'BTVNONUNIF' ...
%                   'BT4REFDIFF' 'REDNONUNIF' 'HISENZ'    'VHISENZ'   'SSTREFVDIFF' ...
%                   'CLOUD'};
%
%   So, there are effectively 16 masks contained in l2_flags. These are
%   extracted as separate fields in this step.
%
% STEP 2: Generate masks to use in correcting improperly flagged pixels.
%   With the exception of bit fields 13-15, the 16 flag fields read in STEP 1 
%   are combined to form three masks, which are used in the correction process. 
%
%   a) No_Fronts_Mask - generated from bits 1-8, 11-12 and 16. Bit fields
%      2, 4 and 6 are dilated with a 9x9 square window. A new bit 6 field is
%      generated from the retrieved SST and the reference SST field. (It was
%      found that the threshold used to generate the original bit 6 field was
%      too strict. The bit 16 field was eroded with a 13 pixel square and the
%      resulting field was dilated with a 19 pixel square. These fields were
%      then summed and values greater than 1 were set to 1.
%   b) 


% The generated masks are based on the masks associated with the 16
%   flags of l2_flags. Masks for flags 2, 4 and 6 are dilated by 
%       Two 0/1 masks are generaged from these bits:
%           i) Mask_Bits_1_3_4_5_6p_9_10_11_16 - a mask for which a given
%              pixel value is set to zero if the corresponding pixel in any
%              of the masks 1-12 and 16 is set.
%          ii) problem_pixels - a mask of problem pixels; pixels to be that
%              may have been improperly flagged.
%
%
%       
% % % % 
% % % %         case {1, 2, 3, 4, 5, 6, 7, 8, 11, 12}
% % % % imdilate_flag   = [0 1 0 1 0 1 0 0 0  0  0  0  0  0  0  1             0       nan                     1 ];

% # Generate the base mask, Base_Mask.  This mask includes problem flags, which
% will be removed in subsequent steps. More details with regard to how this mask
% is generated are provided in the appropriate section.
% # Generate the mask consisting of suspected problem values, Problem_Pixels.
% These are values that failed the uniformity tests.
%%
% 2) Make Original_Mask, a preliminary mask is made either from the Quality
% field based on the Quality_Threshold or from the F2 flags. This is the mask
% that will be corrected and then applied to the input SST field to get Good_SST.
%
%
%
% 3) Make Original_non_Uniform, a mask of pixels flagged as BT non-uniform,
% bits 9 and 10 by summing these two bit fields.
%
% 4) Extract long, thin masked regions only from Original_non_Uniform --> Non_Uniform_pixels.
%
% 5) Clean
%
%
%%
% # Get the data needed (the SST field, the L2 flags and the quality field)
% and generate the base mask, Mask.
% # Only the specified region is read for each; the 2-element Start and Count
% arrays for a netCDF read are used to specify the region.
% # Generate the mask consisting of suspected problem values.
%%
% 2) Make Original_Mask, a preliminary mask is made either from the Quality
% field based on the Quality_Threshold or from the L2 flags. This is the mask
% that will be corrected and then applied to the input SST field to get Good_SST.
%
% If the latter, a field for each of the bits in the flags_sst is extracted
% from flags_sst and all non-zero values are set to 1. (The extraction ends up
% with the field consisting of 0s or $2^{Big\_Number}$, hence the reason for setting
% these values to 1.) All of these fields are summed except for bit numbers 6
% and 15 (exceeds SST-Ref_SST) and 13 (swath edge pixels).
%
% 3) Make Original_non_Uniform, a mask of pixels flagged as BT non-uniform,
% bits 9 and 10 by summing these two bit fields.
%
% 4) Extract long, thin masked regions only from Original_non_Uniform --> Non_Uniform_pixels.
%
% 5) Clean
%
% This script goes through the steps to clean up problems associated with flagging
% of high gradient regions as poor quality.
%% Variables Defined
%
% Masks
%
% Mask_Bits_1_3_4_5_6p_9_10_11_16 is the initial mask of all bad pixels with
% a few modifications. Specifically, the final mask to be made will start
% with this mask. It is the sum of masks constructed from the indicated
% bits. The flag for the reference field has been modified. It looks like
% the input flags differences between the reference field and the retrieved
% field of a bit over 2 K. The new field flags differences in excess of 9 K.
% The order 2 K flag masked a lot of good data in the vicinity of the Gulf
% Stream and likely other rapidly changing regions with large gradients. In
% the future the bit flag for the reference field should be a function of
% the SST variability in the vicinity of the pixel of interest.
%
% The idea of No_Fronts mask is to flag all pixels marked as bad in the
% netCDF file except those marked as bad because of the brightness temperature
% variability *** This mask is obtained by summing the dilated land (1), BT
% difference (4) and Reference temperature (6) masks, the undilated BTRange
% (3), SSTRange (5) and BT4RefDiff (11) masks and the eroded, then dilated
% cloud mask (16). The sum does not include the BTbad (2), SST4diff (7),
% SST4VDIFF (8), REDNonUnif (12), HiSenz (13), VHiSenz (14) or SSTRefVDiff
% (15).
%
% Problem_Pixels are the pixels that failed the BT variability tests (bits
% 9 and 10) minus pixels flagged in the No_Fronts mask. The idea here is to
% remove pixels flagged for another reason as well as pixels near these
% from the variability test, which were determined by dilating some of the
% masks. Connected pixels in this mask will define the objects to be fixed
% if they fail certain tests.
%
% Plot_Object_Labels is a mask with each of the originally identified
% object labels marked. The value of the pixels in the mask equals that of
% the object index.
%
% VERSION #
%   1.0 - original run
%   1.1 - added code to use a space-time temperature difference threshold
%    for comparisons with the reference field. This entailed moving the
%    call to generate the geolocation file up front.

tic
Start_Time = tic;

global oinfo iOrbit iGranule iProblem problem_list
global print_diagnostics save_just_the_facts

global sst_range sst_range_grid_size

global Skewness_Counts_Dilated_Good Skewness_Counts_Segment_Good iSkewness_Dilated_Good iSkewness_Segment_Good
global Skewness_Counts_Dilated_Bad Skewness_Counts_Segment_Bad iSkewness_Dilated_Bad iSkewness_Segment_Bad

iSkewness_Dilated_Good = 0;
iSkewness_Segment_Good = 0;

iSkewness_Dilated_Bad = 0;
iSkewness_Segment_Bad = 0;

single_granule = 0;

global oinfo iOrbit iGranule iProblem problem_list

global AxisFontSize TitleFontSize Trailer_Info

global mem_count mem_orbit_count mem_print print_dbStack mem_struct

global determine_fn_size

if determine_fn_size; get_job_and_var_mem; end

% What version of Fix_MODIS_Mask is this?

Fix_MODIS_Mask_number = '1.10';

% Set return variables

FracArea = nan;
length_nnReduced = nan;
length_FracArea = nan;
Total_Elapsed_Time = toc(Start_Time);

% Plot control and threshold parameters.  Will plot the specified fields if Plot_... is set to 1.

Set_Graphic_Plotting_Parameters_and_Flags

% Initialize counters for the reason the tests to remove the original bit
% flag failed.

% % % Test_Counts.segment_fraction = 0;
Test_Counts.skewness = 0;
Test_Counts.dilated_fraction = 0;
Test_Counts.sst_out_of_range = 0;
Test_Counts.gradient_and_sst = 0;

%% Initialize run control parameters.

% Set flags for which bit masks to dilate.
%   1 to 16 are for the masks corresponding to that bit in flags_sst.
%   If 16 is 1, then bit mask 16 will be eroded and dilated.
%   Bits 13-15 are not used so it doesn't matter what the values are.
%   Element 17: 1, will dilate the No_Fronts mask before removing it from
%    the sum of bit masks 9 and 10, the max-min difference masks.
%    0 will simply remove No_Fronts from the sum
%   Element 18: 1 use ones(5) when dilating the No_Fronts mask (if 17=1)
%               2 use strel('disk',4)
%               3 use my version of the disk.
%   Element 19: 0 do not dilate the mask of problem objects.
%               1 use ones(5) when dilating dilating the mask of problem objects.
%               2 use strel('disk',4) ...
%               3 use my version of the disk...

% imdilate_flag = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 Dilate_Fronts How_(1-3) Dilate_Problem_Pixels ];
imdilate_flag   = [0 1 0 1 0 1 0 0 0  0  0  0  0  0  0  1             0       nan                     1 ];

% Values to use for erosion and dilation of the No_Fronts_Mask.

nErode = 13;
nDilate = 19;

%% Initialize parameters to define region to be read and flags to use for mask

% Range to read. If Start does not exist, will read the entire field.

Debug = 0;
Debug_dot_product = 0;

Extra = 11; % The padding to add around each object selected for analysis.

RS = 9;  % The region size to use when averaging gradient magnitudes.

% If a subset of the image to read has not been identified, specify the
% entire image.

if exist('Start') == 0 | exist('Counts') == 0
    Start = [1 1];
    Counts = [Inf Inf];
end

Final_Mask = zeros(size(SST_In));

% Get the input quality. This is only used to see how good we did.

qual_2_or_worse = int8(zeros(size(Qual_In)));
qual_2_or_worse(Qual_In>=2) = 1;

nn = find(qual_2_or_worse==1);
oinfo(iOrbit).fix_mask_stats.num_qual_2_or_worse = length(nn);

% Check to see if there is any good data in this granule; if not, write out an empty mask and a median field of nans and go to the next granule

nn = find(SST_In > -2);
if isempty(nn)
    fprintf('...No good data in SST_In. Set Final_Mask field to 1, bad data, and returned.\n')

    status = populate_problem_list( 701, 'No good data in SST_In. Set Final_Mask field to 1 and returned.');

    Final_Mask = ones(size(SST_In));

    return
end

sizSST_In = size(SST_In);

% Initialize arrays to use to the size of the input field.

Mask_Pixels_to_Keep = zeros(size(SST_In));
Mask_Pixels_to_Discard = zeros(size(SST_In));

% Plot the field if requested: Plot_SST_In = 1.

% % Figno = Plot_Masks( Plot_SST_In, Figno, inLiveScript, SST_In, 'SST_In');
% % if Plot_SST_In; caxis([-2 32]); end

% % % Read flags_sst.
% % 
% % if single_granule
% %     flags_sst = int16(ncread( file_in, '/geophysical_data/flags_sst', Start, Counts));
% % end
% % Figno = Plot_Masks( Plot_flags_sst, Figno, inLiveScript, flags_sst, 'flags\_sst');

Time_to_Setup_and_Read = toc(Start_Time);
tic

%% Build the mask of problem pixels
%
%
% Here we want to build a mask for problem pixels, ones that may be flagged
% as bad because of high gradients. We use the various bits in flags_sst to do
% this and refer to the resulting mask as Problem_Pixels.
%
% The problem pixels are the ones that have been flagged as non-unform BTs (BTNONUNIF
% and BTVNONUNIF, bits 9 and 10). However, the resulting problem pixel objects
% may be connected to a large region flagged as bad and we do not want to include
% this region when we do the analysis to uncover improperly flagged pixels. So,
% two masks are generated here, one for pixels with BTNONUNIF and/or BTVNONUNIF
% turned on and one for most of the other pixels (bits 1, 3, 4, 5, 11 and 16:
% ISMASKED [this is land], BTRANGE, BTDIFF,     SSTRANGE, BT4REFDIFF and CLOUD).
% For bits 1 and 4 (ISMASKED and BTDIFF) we dilate the masks to get rid of crude
% around them. And for CLOUD (bit 16), we dilate and the erode to make sure that
% there are no remaining connections.
%
% Finally, there are some flags we choose not to use. Specifically, tests for
% the retrieved SST compared with reference SST fields (bit 6 and 15: SSTREFDIFF
% and SSTREFVDIFF) appear to be too vigorous and, on occasion, gets rid of a lot
% of good data in the vicinity of a quickly evolving fields, such as the near
% the Gulf Stream. And pixels near the swath edge are flagged because of the increased
% length through the atmosphere (bits 13 and 14: HISENZ and VHISENZ).
%
% To achieve the above, we first extract a field for each of the bits in flags_sst.
% We sum the two fields resulting from the BT variability test. (bits 9 and 10).
% We call this field Problem_Pixels. We sum the other fields (bits 1,3, 4, 5,
% 11 and 16) to be used, dilating and in the case of CLOUD subsequently eroding,
% to obtain a mask for the other pixels, which we call No_Fronts_Mask. We also
% accumilate all of the maske for the bits to be used without dilating or eroding
% into a base mask, which we call Mask_Bits_1_3_4_5_6p_9_10_11_16. (This is the
% base mask. Pixels flagged as bad (values of 1 in this mask) will be set to 0
% if it is determined that they were incorrectly masked.) Next set all values
% in all fields to 1 if > 1. Then remove No_Fronts_Mask from Problem_Pixels and
% set all values <0 to 0. This will be the mask we use to

% Use either the quality flag or the L2 flags.

No_Fronts_Mask = zeros(sizSST_In);
Flags_9_Plus_10 = zeros(sizSST_In);
Mask_Bits_1_3_4_5_6p_9_10_11_16 = zeros(sizSST_In);
% % % Mask_Excluding_Ref_Temp = int32(zeros(sizSST_In));

Meanings_of_flags_sst = {'ISMASKED'   'BTBAD'      'BTRANGE'   'BTDIFF'    'SSTRANGE' ...
    'SSTREFDIFF' 'SST4DIFF'   'SST4VDIFF' 'BTNONUNIF' 'BTVNONUNIF' ...
    'BT4REFDIFF' 'REDNONUNIF' 'HISENZ'    'VHISENZ'   'SSTREFVDIFF' ...
    'CLOUD'};

% Some of the bit values do not appear to be used. Below is an indication
% for the bits, which I think are used/not used.
%
% Meanings_of_flags_sst = {'ISMASKED-data'   'BTBAD-NO data'      'BTRANGE'-data   'BTDIFF-data'    'SSTRANGE-data' ...
%     'SSTREFDIFF-data' 'SST4DIFF-NO data'   'SST4VDIFF-NO data' 'BTNONUNIF-data' 'BTVNONUNIF-data' ...
%     'BT4REFDIFF-data' 'REDNONUNIF-NO data' 'HISENZ-data'    'VHISENZ-data'   'SSTREFVDIFF-data' ...
%     'CLOUD'-data};

% Do two passes. The first one will generate the basic masks and from that
% a mask for bit 6, the reference bit. The second pass will dilate these
% masks as needed.

mask = int32(zeros(16, sizSST_In(1), sizSST_In(2)));

for iBit=[1:16] 
        
    if iBit == 16
        
        % Bit 16 has to be handled differently. The netCDF file sees flags_sst
        % as int16 but seems to read it into a double file so I told it that it
        % is an int16 file when I read it. I tried to tell it that it was
        % unsigned but it doesn't like that. As a result any pixel with a
        % negative value of flags_sst has bit 16, the sign bit, set, so
        
       temp = int32(zeros(sizSST_In));
       temp(flags_sst<0) = 1;
       mask(16,:,:) = temp;
    else
        
        % All other bits actually get the value of the bit at each pixel location -
        % does it in one swell foop.
        
         temp = int32(bitand(flags_sst, 2^(iBit-1), 'int16'));
         nn = find(temp>0);
         temp(nn) = 1;
         mask(iBit,:,:) = temp;
    end
end

% Now go through dilating and summing.

for iBit=1:16
    
    Temp_Flag = squeeze(mask( iBit, :, :));
    
    if (iBit == 6)
        Old_Reference_Temperature_Flag = int8(Temp_Flag);
        
        % Set Temp_Flag to zeros; will add 1s using the reference threshold
        % fields.
        
        Temp_Flag = zeros(sizSST_In);
        
        % Get the difference between the reference field and this field.
        
        sstdiff = sstref - SST_In;

        lon_range_index_vec = floor((180 + longitude(:)) / sst_range_grid_size) + 1;
        lat_range_index_vec = floor((90 + latitude(:)) / sst_range_grid_size) + 1;
        
        lon_range_index_vec(lon_range_index_vec>180) = 180;
        lon_range_index_vec(lon_range_index_vec<-180) = -180;
        lat_range_index_vec(lat_range_index_vec>90) = 90;
        lat_range_index_vec(lat_range_index_vec<-90) = -90;
        
        
%         % If you want to plot ranges_for_this_month
%         
%         Lon_values = [-180+sst_range_grid_size/2:sst_range_grid_size:180-sst_range_grid_size/2]; 
%         Lat_values = [-90+sst_range_grid_size/2:sst_range_grid_si ze:90-sst_range_grid_size/2];
%         figure
%         imagesc(Lon_values, Lat_values, ranges_for_this_month)
%         set(gca,'fontsize',24,ydir='normal')
%         load coastlines.mat
%         hold on;plot(coastlon,coastlat,'w',linewidth=2)

        ranges_for_this_month = squeeze(sst_range(:,:,Month));
        
        temp_for_6 = zeros(sizSST_In);
        for iCheck=1:numel(temp_for_6)
            
            % The following check because at least one input image had nans
            % for the lat and lon fields at one end of the image.
            
            if isnan(lat_range_index_vec(iCheck)) | isnan(lon_range_index_vec(iCheck))
                temp_for_6(iCheck) = 10000;
            else
                temp_for_6(iCheck) = squeeze(ranges_for_this_month(lat_range_index_vec(iCheck), lon_range_index_vec(iCheck)));
            end
        end
        
        temp_for_6 = temp_for_6 * Thresholds.Reference_SST_Diff_Factor;
        Temp_Flag(sstdiff > temp_for_6) = 1;
        New_Reference_Temperature_Flag = int8(Temp_Flag);
    end
    
    % Add this bit plane to the appropriate mask.
    
    switch iBit
        case {1, 2, 3, 4, 5, 6, 7, 8, 11, 12}
            
            % Dilate these masks to get rid of some of the crumbs on their
            % edges if requested
            
            if imdilate_flag(iBit) == 1
                No_Fronts_Mask = No_Fronts_Mask + double(imdilate(Temp_Flag, ones(9)));
            else
                No_Fronts_Mask = No_Fronts_Mask + double(Temp_Flag);
            end
            
        case {9, 10}
            Flags_9_Plus_10 = Flags_9_Plus_10 + double(Temp_Flag);
            
        case 16
            % Erode and then dilate this field. The idea is to - can't
            % recall why - but it is important; if this is not done, we end
            % up with a lot more objects to check.
            
            if imdilate_flag(iBit) == 1
                Eroded_5x5 = imerode( Temp_Flag, ones(5));
                No_Fronts_Mask = No_Fronts_Mask + double(imdilate( Eroded_5x5, ones(9)));
            else
                No_Fronts_Mask = No_Fronts_Mask + double(Temp_Flag);
            end
            
    end
    
    % Make the base mask from all used bits - exclude bits 13-15 (zenith
    % angle and the flag for rtrieved SST out of range re the reference
    % field.
    
    if (iBit~=13) & (iBit~=14) & (iBit~=15)
        Mask_Bits_1_3_4_5_6p_9_10_11_16 = Mask_Bits_1_3_4_5_6p_9_10_11_16 + double(Temp_Flag);
    end
    
% %     % Plot the mask for this bit if requested.
% %     
% %     Figno = Plot_Masks( Plot_Individual_flags_sst, Figno, inLiveScript, double(Temp_Flag), ['Bit ', num2str(iBit), ': ', Meanings_of_flags_sst{iBit}]);
end

% Now set all masks to either 0 or 1 and plot if requested.

Mask_Bits_1_3_4_5_6p_9_10_11_16(Mask_Bits_1_3_4_5_6p_9_10_11_16>0) = 1;
% % Figno = Plot_Masks( Plot_Mask_Bits_1_3_4_5_6p_9_10_11_16, Figno, inLiveScript, Mask_Bits_1_3_4_5_6p_9_10_11_16, 'Mask_Bits_1_3_4_5_6p_9_10_11_16');

No_Fronts_Mask(No_Fronts_Mask>0) = 1;
% % Figno = Plot_Masks( Plot_No_Fronts_Mask, Figno, inLiveScript, No_Fronts_Mask, 'Base Mask No Fronts');

Flags_9_Plus_10(Flags_9_Plus_10>0) = 1;
Flags_9_Plus_10(Flags_9_Plus_10<0) = 0;

% Finally remove No_Fronts_Mask dilating and/or eroding if requesed from
% the union of bits 9 and 10. Best is imdilate_flag(17) = 0; no dilation.

if imdilate_flag(17)
    switch imdilate_flag(18)
        case 1
            Problem_Pixels = Flags_9_Plus_10 - imdilate(No_Fronts_Mask, ones(5));
        case 2
            Problem_Pixels = Flags_9_Plus_10 - imdilate(No_Fronts_Mask, strel('disk',4));
        case 3
            Problem_Pixels = imerode( Temp_Flag, pcc_disk(2));
    end
else
    Problem_Pixels = Flags_9_Plus_10 - No_Fronts_Mask;
end
Problem_Pixels(Problem_Pixels<0) = 0;
% % Figno = Plot_Masks( Plot_Problem_Pixels, Figno, inLiveScript, Problem_Pixels, 'Problem Pixels');

Time_to_Build_Basic_Masks = toc;
tic

%% Reduce the Number of Objects
% To unmask pixels, which were improperly masked because of the local BT variance
% the script will work on objects. There can be a lot of objects in an image resulting
% from, for example, real clouds. This section will reduce the number of these
% objects without, hopefully, getting rid of objects to be fixed. This is a multi-step
% process
%%
% # Set the value of Problem_Pixels to 0 for singleton values; i.e., pixels
% flagged as bad that are not connected to any other bad values. This assumes
% that the singleton SST value is good. It might make more sense to skip this
% step and when dealing with objects to treat this one as a special case: does
% the singleton SST value lie within the range of the 8 surrounding values. If
% so, keep it. If not do not set the mask value to 0.
% # Fill small clear objects surrounded by pixels flagged as bad. This step
% is important because following this we will erode the field cloud mask and holes
% in the clouds will become a lot larger.


% % % % Start with the mask obtained from the flags_sst
% % %
% % % Mask_Orig = Problem_Pixels;
% % %
% % % Figno = Plot_Masks( Plot_Mask_Orig, Figno, inLiveScript, Mask_Orig, 'Original Mask (M_o)');

%% Remove 1 pixel objects from Problem_Pixels: Problem_Pixels==> Problem_Pixels_No_Singletons
% The above assumes that 1 pixel objects flagged as bad are actually good SST values.

% Start by getting all objects in Problem_Pixels.

CC = bwconncomp(logical(Problem_Pixels));
L = labelmatrix(CC);
stats = regionprops( L, 'area', 'pixellist');
Areas = cat(1, stats.Area);

nn = find(Areas<=1);

Problem_Pixels_No_Singletons = Problem_Pixels;

for  iEliminate=1:length(nn)
    Coordinates = stats(nn(iEliminate)).PixelList;
    kk = sub2ind( sizSST_In, Coordinates(:,2), Coordinates(:,1));
    Problem_Pixels_No_Singletons(kk) = 0;
end

% % Figno = Plot_Masks( Plot_Problem_Pixels_No_Singletons, Figno, inLiveScript, Problem_Pixels_No_Singletons, 'Problem_Pixels_No_Singletons');

%% Fill small regions in the mask that are 'clear': Problem_Pixels_No_Singletons ==> Problem_Pixels_Clear_Holes_Filled

Mask_Inverted = imcomplement(Problem_Pixels_No_Singletons);

% % Figno = Plot_Masks( Plot_Mask_Inverted, Figno, inLiveScript, Mask_Inverted, 'Mask_Inverted');

% Get the properties for all objects (pixel value = 1) in the inverted mask.

CC = bwconncomp(logical(Mask_Inverted),4);
L = labelmatrix(CC);
stats = regionprops( L, 'area', 'pixellist');
Areas = cat(1, stats.Area);

% Find objects with areas < Thresholds.Area and set them to 0; i.e., set small
% regions flagged as clear to be temporarily flagged as bad.

nn = find(Areas<Thresholds.Area);

Mask_Inverted_Filled = Mask_Inverted;

for iEliminate=1:length(nn)
    Coordinates = stats(nn(iEliminate)).PixelList;
    kk = sub2ind( sizSST_In, Coordinates(:,2), Coordinates(:,1));
    Mask_Inverted_Filled(kk) = 0;
end

% % Figno = Plot_Masks( Plot_Mask_Inverted_Filled, Figno, inLiveScript, Mask_Inverted_Filled, ['Inverted Elements < ' num2str(Thresholds.Area) '=0 (M_if)']);

% Invert this mask 0--> 1-->0. This will be the original mask with objects
% having clear areas < Thresholds.Area flagged as bad.

Problem_Pixels_Clear_Holes_Filled = zeros(sizSST_In);
Problem_Pixels_Clear_Holes_Filled(Mask_Inverted_Filled==0) = 1;

% % Figno = Plot_Masks( Plot_Problem_Pixels_Clear_Holes_Filled, Figno, inLiveScript, Problem_Pixels_Clear_Holes_Filled, 'Problem_Pixels_Clear_Holes_Filled');

%% Dilate and erode the modified mask of problem objects:  Problem_Pixels_Clear_Holes_Filled ==> dd_9x9

% Now erode and dilate the filled mask. The idea here is to get rid of
% large cloud objects, which are not likely to be clear, without getting
% rid of improperly masked fronts. The first step, erosion will set pixels
% flagged as bad, which lie in narrow bands to 0. Dilation will fill the
% mask back out in regions that survived. The end result should be a mask
% of the large objects about the way they were before erosion/dilation but
% without the masked pixels of interest. Then, subtract the eroded/dilated
% field from Problem_Pixels with small clear areas filled. This will be the
% mask we use to look for objects. It is the original Problem_Pixel mask
% with large cloudy areas removed. Best results for imdilate_flag(19) = 1

switch imdilate_flag(19)
    case 1
        Eroded_9x9 = imerode( Problem_Pixels_Clear_Holes_Filled, ones(nErode)); % Better than ones(9) except for blotches at end of some segments
        Dilated_9x9_15x15 = imdilate( Eroded_9x9, ones(nDilate));
    case 2
        Eroded_9x9 = imerode( Problem_Pixels_Clear_Holes_Filled, strel('disk',6));
        Dilated_9x9_15x15 = imdilate( Eroded_9x9, strel('disk',9));
    case 3
        Eroded_9x9 = imerode( Temp_Flag, pcc_disk(4));
        Dilated_9x9_15x15 = imerode( Eroded_9x9, pcc_disk(7));
end

if imdilate_flag(19) ~= 0
% %     Figno = Plot_Masks( Plot_Eroded_9x9, Figno, inLiveScript, Eroded_9x9, 'Eroded_9x9');
% %     Figno = Plot_Masks( Plot_Dilated_9x9_15x15, Figno, inLiveScript, Dilated_9x9_15x15, 'Dilated_9x9_15x15');
    
    dd_9x9 = Problem_Pixels_Clear_Holes_Filled - double(Dilated_9x9_15x15);
    dd_9x9(dd_9x9<0) = 0;
% %     Figno = Plot_Masks( Plot_dd_9x9, Figno, inLiveScript, dd_9x9, 'dd_9x9');
else
    dd_9x9 = Problem_Pixels_Clear_Holes_Filled - double(Temp_Flag);
end

% % Figno_Save = Figno;

% Get All Candidate Objects from Problem_Pixels
%
% Start by getting all objects in Problem_Pixels. Save objects for which the fraction of
% the flagged area in bounding box of the object is less than Thresholds.FracArea or the
% eccentricity exceeds Thresholds.Eccentricity and the filled area is less than
% Thresholds.FilledArea pixels.
%
% % Get region properties.

CC = bwconncomp(logical(dd_9x9));
Object_Labels = labelmatrix(CC);

% % Figno = Plot_Masks( Plot_Object_Labels, Figno, inLiveScript, Object_Labels, 'Object Labels');                      % 9

%% Remove objects based on their area and eccentricity - these are likely clouds.
% Remember that this is the mask of objects to test to see
% Get properties for the objects in Object_Labels

new_stats = regionprops( Object_Labels, 'Area', 'MinorAxisLength', 'MajorAxisLength', 'Eccentricity', 'FilledArea', 'PixelList', 'PixelIdxList', 'BoundingBox');

% Move the properties from the structure to vectors to make them easier to
% manipulate.

Area = cat(1, new_stats.Area);
MinorAxisLength = cat(1, new_stats.MinorAxisLength);
MajorAxisLength = cat(1, new_stats.MajorAxisLength);
Eccentricity = cat(1, new_stats.Eccentricity);
FilledArea = cat(1, new_stats.FilledArea);

FullArea = MinorAxisLength .* MajorAxisLength;
FracArea = (FilledArea ./ FullArea);
length_FracArea = length(FracArea);

% Find objects that fail tests related to:
%   1) fraction of the area in the enclosing rectangular box (defined by the
%      length of the major and minor axes), occupied by each object,
%   2) the eccentricity of the object - it must be greater than a threshold
%   3) the total area of the object.

nnReduced = find(FracArea<Thresholds.FracArea | (Eccentricity>=Thresholds.Eccentricity & FilledArea<Thresholds.FilledArea));
length_nnReduced = length(nnReduced);

if isempty(nnReduced)
    fprintf('...No candidate objects found. Set Final_Mask field to 1, bad data, and returned.\n')

    status = populate_problem_list( 702, 'No candidate objects found. Set Final_Mask field to 1 and returned.');

    Final_Mask = ones(size(SST_In));
    
    return
else
    % if print_diagnostics
    %     fprintf('Out of a possible %i objects, %i meeting our thresholds were found in this file.\n', length_FracArea, length_nnReduced)
    % end
    
    oinfo(iOrbit).fix_mask_stats.length_FracArea = length_FracArea;
    oinfo(iOrbit).fix_mask_stats.length_nnReduced = length_nnReduced;
end

% Copy the objects, which met the above tests to a new structure called
% Candidate_Objects. Also, define a new array with each pixel for each
% object with the value of the object number --> Mask_of_Objects.

clear Candidate_Objects NewStruct Indices Mask_Fixed

for i=1:length(nnReduced)
    Candidate_Objects(i) = new_stats(nnReduced(i));
    NewStruct(i).Indices = new_stats(nnReduced(i)).PixelList;
    Indices(i) = nnReduced(i);
    Mask_Fixed(i) = 0;
end
Mask_of_Objects = Add_Objects_to_Array( zeros(sizSST_In), NewStruct, Indices);

% % Figno = Plot_Masks( Plot_Mask_of_Objects, Figno, inLiveScript, Mask_of_Objects, 'Output Array FracArea$<$0.4 $|$ (Eccentricity$>$=0.95 \& FilledArea$<$2000)');                      % 9

% Extract vectors from the new structure array to facilitate using in the following.

Area = cat(1, Candidate_Objects.Area);
Eccentricity = cat(1, Candidate_Objects.Eccentricity);
BoundingBox = cat(1, Candidate_Objects.BoundingBox);
PixelIdxList = cat(1, Candidate_Objects.PixelIdxList);

Quality = logical(Mask_of_Objects);

%% Continue generating masks.

% Start by removing some of the intermediate fields

% clear Flag_* Dilated_* Temp_Flag Problem_Pixels Output_Array Mask_* Object_Labels flags_sst DMO dd_*

Number_Corrected_Segments = 0;

% Get all objects in the modified Problem_Pixels mask.

Candidate_Pixels = Mask_of_Objects;
Candidate_Pixels(Candidate_Pixels>0) = 1;
% % Figno = Plot_Masks( Plot_Candidate_Pixels, Figno, inLiveScript, Candidate_Pixels, 'Candidate_Pixels');

CC = bwconncomp(logical(Candidate_Pixels));
Object_Labels_After_Pruning = labelmatrix(CC);

% % Figno = Plot_Masks( Plot_Object_Labels_After_Pruning, Figno, inLiveScript, Object_Labels_After_Pruning, 'Object Labels After Pruning');

% The following was an attempt to reduce the number of objects early on as
% well possibly finding a good measure to reject some of the problem
% objects. It takes a long time and didn't help to reject objects.
%
% % Skeletilize this object, get the number of branch points and the
% % ratio of the object areas to the number of pixels in the skeleton
%
% for i=1:length(nnReduced)
%     Skel_Test_Array = Object_Labels_After_Pruning;
%     Skel_Test_Array(Skel_Test_Array~=i) = 0;
%
%     Skel_Test_Skeleton = single(bwskel(logical(Skel_Test_Array)));
%     Skel_Test_Area_Number(i) = length(find(Skel_Test_Array > 0));
%     Skel_Test_Skel_Number(i) = length(find(Skel_Test_Skeleton > 0));
%     Skel_Test_Ratio(i) = Skel_Test_Skel_Number(i) / Skel_Test_Area_Number(i);
%
%     Skel_Test_Branch_Points = bwmorph( Skel_Test_Skeleton, 'branchpoints');
%     Skel_Test_Branch_Points_Number(i) = length(find(Skel_Test_Branch_Points > 0));
% end

% Initialize the final masks

Quality_Declouded = logical(zeros(sizSST_In));
Quality_Final = logical(Mask_Bits_1_3_4_5_6p_9_10_11_16);

%% Determine if the Selected Objects Have Been Improperly Masked

Have_not_plotted_SST_In = 1; % So that we only plot SST_In once but all of the rectangles on it.

% Zero temperature and gradient test.

Num_Objects = length(Candidate_Objects);

Temperature_Test_Mean = zeros(1,Num_Objects);
Temperature_Test_Sigma = zeros(1,Num_Objects);
Gradient_Test = zeros(1,Num_Objects);

%% Loop over the objects identified as possibly having masking issues.

if exist('objects_to_inspect')
    disp(['Will do a debug run for objects: ' num2str(objects_to_inspect) '. You asked to go to the keyboard here.'])
    
    Debug_dot_product = 1;
    Debug = 1;
    
    keyboard
else
    objects_to_inspect = 1:Num_Objects;
end

Time_for_Image_Wide_Tests = toc;
tic

for iObject=objects_to_inspect
        
    %     disp(['Object # ' num2str(iObject) '. Previous object took ' num2str(toc) ' seconds'])
    
    if mod(iObject,100) == 0 & Debug == 1
        disp(['Working on object ' num2str(iObject)])
    end
    
    % Define a region slightly larger than the bounding box for this object.
    
    Temp = Candidate_Objects(iObject).BoundingBox;
    Bounding_Box = [floor(Temp(1))+1 floor(Temp(2))+1 ceil(Temp(3)) ceil(Temp(4))];
    Pixel_List = Candidate_Objects(iObject).PixelIdxList;
    
    Left = floor(max( 1, Bounding_Box(1) - Extra));
    Right = ceil(min( sizSST_In(2), Bounding_Box(1) + Bounding_Box(3) + Extra));
    Bottom = floor(max( Bounding_Box(2) - Extra, 1));
    Top = ceil(min( Bounding_Box(2) + Bounding_Box(4) + Extra, sizSST_In(1)));
    
    % Get the indices of the pixel list so that we can recreate them in
    % the region just covering this object.
    
    [I, J] = ind2sub(sizSST_In,Pixel_List);
    
    % % %     % Plot these pixels in the Debug_Array
    % % %
    % % %     for i=1:length(I)
    % % %         Debug_Array(I(i),J(i)) = iObject;
    % % %     end
    
    % Next get the indices in the new region.
    
    NewI = I - Bottom + 1;
    NewJ = J - Left + 1;
    
    % In the remainder of this loop we will define arrays for the slightly
    % enlarged region surrounding the object.
    
    %% Generate the SST and gradient arrays for this object.
    
    SST_In_Object = SST_In(Bottom:Top,Left:Right);
    sizSST_In_Object = size(SST_In_Object);
    
    % Now get the linear indices corresponding to NewI and NewJ and how
    % many there are.
    
    Linear_Indices = sub2ind(sizSST_In_Object, NewI, NewJ);
    Number_in_Mask_of_Object(iObject) = length(Linear_Indices);
    
    % Get the mask with all of the flags being used. This mask includes the
    % mask for the problem pixels.
    
    Mask_of_All_Flagged_Pixels = Mask_Bits_1_3_4_5_6p_9_10_11_16(Bottom:Top,Left:Right);
    Number_in_Mask_of_All_Flagged_Pixels(iObject) = length(find(Mask_of_All_Flagged_Pixels(:)) == 1);
    
    % In some cases there are only a few pixels being considered and they occur
    % in a generally cloudy region. If this is the case for this object,
    % then skip it; i.e., leave the mask as is for it. Also, no need to
    % get the other fields for the object or do any other tests.
    
    Percent_Clear_in_Object_Rectangle(iObject) = 100 * (1 - (Number_in_Mask_of_All_Flagged_Pixels(iObject) - Number_in_Mask_of_Object(iObject)) / numel(Mask_of_All_Flagged_Pixels));
    
    if (Percent_Clear_in_Object_Rectangle(iObject) < Thresholds.Percent_Clear_in_Rectangle) & (Number_in_Mask_of_Object(iObject) < Thresholds.Number_of_Problem_Pixels)
        if Debug
            disp(['Object #' num2str(iObject) ' only had ' num2str(Number_in_Mask_of_Object(iObject)) ' which is less than the threshold of ' num2str(Thresholds.Number_of_Problem_Pixels) ' and only ' num2str(Percent_Clear_in_Object_Rectangle(iObject)) '% of the pixels were clear in this region.'])
        end
    else
        
        % Make an array for SST under the object.
        
        SST_of_Object = nan(sizSST_In_Object);
        SST_of_Object(Linear_Indices) = SST_In_Object(Linear_Indices);
        
        % Generate a mask of pixels surrounding the object we are working
        % on here. Do this by dilating the object mask and then removing
        % all pixels flagged as bad from this object mask. This will remove
        % the object pixels as well as other pixels flagged as bad. Start
        % by making a 0/1 array for the Problem_Pixel mask in this region.
        
        Object_Mask = zeros(sizSST_In_Object);
        Object_Mask(Linear_Indices) = 1;
        % % %         Dilated_Mask = imdilate( Object_Mask, SE);
        Dilated_Mask = imdilate( Object_Mask, strel( 'disk', 3));
        Dilated_Mask_Excluding_Object = Dilated_Mask - Object_Mask;
        
        % Get the Sobel vector gradient of the input SST field for this object.
        
        [Grad_X, Grad_Y] = Sobel(SST_In_Object);
        
        % Get the magnitude and direction of gradients.
        
        GMag_in_Object = sqrt(Grad_X.^2 + Grad_Y.^2);
        GDir_in_Object = atan(Grad_Y ./ Grad_X);
        
        %% Now perform the various tests
        %
        % The first test relates to the SST values of the object relative to that of the
        % surrounding waters. SSTs of the object must, on average, lie between two peaks,
        % one on either side. Do this with histograms. The histogram will be plotted if
        % Plot_Histograms=1 otherwise not. SST values will be histogrammed for the range
        % -2 to 32 in steps of 0.2
        %
        % Are there any good SST values under the dilated portion of the mask.
        % The reason for this test is that rivers will often be masked and the
        % region on the sides of the river are land so nans. This tests for
        % that and skips if it is the case.
        
        % Get other test parameters
        
        [Object_Mask_Pixels_to_Discard, Object_Mask_Pixels_to_Keep, Test_Counts] = Test_Masked_Pixels( Debug_dot_product, ...
            inLiveScript, Object_Labels_After_Pruning, Test_Counts, iObject, SST_In_Object, Object_Mask, ...
            Mask_of_All_Flagged_Pixels, Linear_Indices, Grad_X, Grad_Y, GMag_in_Object);
        
        % Update the final mask with the mask from this object.
        
        Mask_Pixels_to_Discard(Bottom:Top,Left:Right) = Mask_Pixels_to_Discard(Bottom:Top,Left:Right) + Object_Mask_Pixels_to_Discard;
        Mask_Pixels_to_Keep(Bottom:Top,Left:Right) = Mask_Pixels_to_Keep(Bottom:Top,Left:Right) + Object_Mask_Pixels_to_Keep;
        
    end
end

Time_to_Process_Objects = toc;

Mask_Pixels_to_Discard(Mask_Pixels_to_Discard>0) = 1;
Mask_Pixels_to_Keep(Mask_Pixels_to_Keep>0) = 1;

Final_Mask = Mask_Bits_1_3_4_5_6p_9_10_11_16;
Final_Mask(Final_Mask>0) = 1;
Final_Mask(Final_Mask<0) = 0;

Final_Mask = Final_Mask - Mask_Pixels_to_Discard;
Final_Mask(Final_Mask<0) = 0;

% Finally, remove 3 pixel objects from the mask, these tend to be good
% pixels but even if not, they screw up the regridding. Start by getting 
% all objects in mask.

CC = bwconncomp(logical(Final_Mask));
L = labelmatrix(CC);
stats = regionprops( L, 'area', 'pixellist');
Areas = cat(1, stats.Area);

nn = find(Areas<=3);

for  iEliminate=1:length(nn)
    Coordinates = stats(nn(iEliminate)).PixelList;
    kk = sub2ind( sizSST_In, Coordinates(:,2), Coordinates(:,1));
    Final_Mask(kk) = 0;
end

% % Figno = Plot_Masks( Plot_Final_Mask, Figno, inLiveScript, Final_Mask, 'Final_Mask');

% And write out stats for number of pixels fixed.

nn = find(Final_Mask == 1);
oinfo(iOrbit).fix_mask_stats.num_stlll_bad = length(nn);

nn_good_good = find( (qual_2_or_worse == 0) & (Final_Mask == 0));
nn_good_bad = find( (qual_2_or_worse == 0) & (Final_Mask == 1));
nn_bad_good = find( (qual_2_or_worse == 1) & (Final_Mask == 0));
nn_bad_bad = find( (qual_2_or_worse == 1) & (Final_Mask == 1));

oinfo(iOrbit).fix_mask_stats.qual_good_final_mask_good = length(nn_good_good);
oinfo(iOrbit).fix_mask_stats.qual_good_final_mask_bad = length(nn_good_bad);
oinfo(iOrbit).fix_mask_stats.qual_bad_final_mask_good = length(nn_bad_good);
oinfo(iOrbit).fix_mask_stats.qual_bad_final_mask_bad = length(nn_bad_bad);


