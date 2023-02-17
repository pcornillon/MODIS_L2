% Set_Graphic_Plotting_Parameters_and_Flags_


% % % global AxisFontSize TitleFontSize Trailer_Info
 
% AxisFontSize = 20;
% TitleFontSize = 30;
% % % Trailer_Info = '';

inLiveScript = 0; % To skip plotting in live script.

% Font size parameters

% Plotting flags for the input data.

% % % global Plot_SST_In Plot_flags_sst Plot_Individual_flags_sst

Plot_SST_In = 0;                      % sst field read in from the netCDF file.
Plot_flags_sst = 0;                         % flags_sst read in from the netCDF file.
Plot_Individual_flags_sst = 0;              % The flags set for each of the bits in flags_sst

% Meanings_of_flags_sst = {'ISMASKED-data'   'BTBAD-NO data'      'BTRANGE'-data   'BTDIFF-data'    'SSTRANGE-data' ...
%     'SSTREFDIFF-data' 'SST4DIFF-NO data'   'SST4VDIFF-NO data' 'BTNONUNIF-data' 'BTVNONUNIF-data' ...
%     'BT4REFDIFF-data' 'REDNONUNIF-NO data' 'HISENZ-data'    'VHISENZ-data'   'SSTREFVDIFF-data' ...
%     'CLOUD'-data};

% Plotting flags for 

% % % global Plot_Mask_Bits_1_3_4_5_6p_9_10_11_16 Plot_No_Fronts_Mask Plot_Problem_Pixels Plot_Object_Labels Plot_Mask_of_Objects Plot_Candidate_Pixels


Plot_Mask_Bits_1_3_4_5_6p_9_10_11_16 = 0;   
Plot_No_Fronts_Mask = 0;
Plot_Problem_Pixels = 0;
Plot_Object_Labels = 0;

% The Candidate_Pixels mask is the same as the Object_Labels mask except
% only 0s and 1s; no object labels.

Plot_Mask_of_Objects = 0;
Plot_Candidate_Pixels = 0;  

Plot_Object_Labels_After_Pruning = 0;

Plot_Final_Mask = 0;

% % % % % Plot_Individual_flags_sst = 0;
Plot_Individual_flags_sst = 0;
Plot_No_Fronts_Mask = 0;
Plot_Problem_Pixels_No_Singletons = 0;
Plot_Problem_Pixels_Clear_Holes_Filled = 0;
Plot_Mask_Inverted = 0;
Plot_Mask_Inverted_Filled = 0;

Plot_Final_Mask = 0;

Plot_Eroded_9x9 = 0;
Plot_Dilated_9x9_15x15 = 0;
Plot_dd_9x9 = 0;

Plot_Histograms = 0;

Plot_SST_with_Object_Location = 0;

Plot_SST_Original_Mask = 0;
Plot_SST_Final_Mask = 0;
Plot_SST_Final_Mask_Showing_Fixed = 0;

%% Threaholds

global Thresholds

Thresholds.Reference_SST_Diff = 9;
Thresholds.Reference_SST_Diff_Factor = 1.1;
Thresholds.Area = 30;
Thresholds.FracArea = 0.4;
% Thresholds.Eccentricity = 0.95;
Thresholds.Eccentricity = 0.90;
Thresholds.FilledArea = 2000;
Thresholds.Percent_Clear_in_Rectangle = 50;
Thresholds.Number_of_Problem_Pixels = 40;
Thresholds.Percent_Good_in_Dilated_Mask = 0.65;
Thresholds.Percent_Good_in_Final_Segment_Mask = 0.7;
Thresholds.Percentage_in_Object_1 = 10;
Thresholds.Percentage_in_Object_2 = 15;
Thresholds.Percent_Good_Dot_Products = 70;
Thresholds.Percent_SST_in_Range = 75;
Thresholds.Dot_Product = 0.8;
Thresholds.hist_max = 20; % # to exceed for sst values to be flagged in segment mask if less than Thresholds.hist_min counts in a bin
Thresholds.hist_min = 5;

% The following thresholds selected after significant comparisons.

Thresholds.segment_length = 6;
Thresholds.skewness = 1.6;
Thresholds.skewness_count_test = 25;

