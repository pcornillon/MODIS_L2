function [array_out] = cleanup_arrays( array_in, mean_array_in, Threshold)
% % % function [array_out, nn_out] = cleanup_array( array_in, mean_array_in, Threshold)
% cleanup_array - Used by generate_separation_and_angles to set outlier pixels to nan - PCC
%
% This function has been designed to cleanup separation arrays for individual
% orbits. It has been designed to be used with generate_separations_angles. 
% It does this using several thresholds an ageraged array--averaged over a 
% number of orbits--and a vector of thresholds. 
%
% First it copies the input array into a temporary array and sets all 
% elements of this array exceeding Threshold(1) to nan. It then averages 
% the resulting array in the along track direction to obtain a mean scan of
% the variable in the input array (either the along-scan or along-track
% separation). Next it replicates the mean scan line by the number of scan
% lines in the input image to obtain an array that is the same size as the 
% input array. Following this is subtracts the replicated scan line array
% from the input array and tests to find elements that are farther from the 
% differenced array than Threshold(2). These are set to nan. Finally, if 
% Threshold(3) is non-zero, it subtracts the input mean array (determined 
% by averaging arrays over a number of orbits) from the input array and
% tests to to find elements that are greater than Threshold(3). These are 
% also set to nan.
%
% Note that if Threshold(1) is greater than Threshold(2), which should be
% the case, the test with Threshold(2) will also set values in the input
% array that exceed Threshold(1) to nan. The reason that a temporary
% variable was used in the first step was so that the two subsequent tests
% define elements set to nan. The list of these elements is returned to the
% calling routine.
%
% INPUT
%   array_in - array to be cleaned up.
%   mean_array_in - This is an array of the same sort of elements in the
%    input array averaged over a number of orbits.
%   Threshold - 3 element vector of threshold values to use to clean up.
%       - 1st element: absolute threshold; array_in elements > than this 
%         value set to nan.
%       - 2nd element: absolute values of the difference between the input
%         array and the input array averaged in the along-track direction
%         and then replicated back to the size of the input array greater
%         than this threshold are set to nan.
%       - 3rd element: if the input array exceeds the mean array by this
%        threshold, the value of the input array is set to nan.
%
% OUTPUT
%   array_out - the cleaned up input array.
% % % %   nn_out - elements of the input array that failed the tests on
% % % %    Threshold(2) and (3).
%

array_out = array_in;

% Set bad values, ones that exceed Threshold(1), to nan in a new temporary
% array. This array will be used to develope an along-track mean of the
% input variable excluding nans. Note that this function is to be used with
% separations only and they are aways positive so the next line, which is
% testing for large excursions need only test for array_in > Threshold(1).

nn = find(array_out > Threshold(1));

% % % tt = array_in;
% % % tt(nn) = nan;
% % % 
% % % % Build an array that is the same size as the input array but for which
% % % % everl scan line is equal to the average scan line.
% % % 
% % % along_track_mean_array = repmat( mean(tt, 2, 'omitnan'), 1, size(array_in,2));

array_out(nn) = nan;

% Build an array that is the same size as the input array but for which
% everl scan line is equal to the average scan line.

along_track_mean_array = repmat( mean(array_out, 2, 'omitnan'), 1, size(array_in,2));

% Test the input array against the array built above and, if Threshold(3)>0, 
% also test the input array against the mean of input arrays averaged over
% a number of orbits.

if Threshold(3) > 0
% % %     % Test to see if test on Threshold(3) should be on the absolute value?
% % %     mm = find(mean_array_in > array_in + Threshold(3));
% % %     if length(mm) > 0
% % %         keyboard
% % %     end
% % %     % End of test.
% % %     nn_out = find( (abs(along_track_mean_array - array_in) > Threshold(2)) & ((array_in - mean_array_in) > Threshold(3)));
    nn_out = find( (abs(along_track_mean_array - array_in) > Threshold(2)) & (abs(array_in - mean_array_in) > Threshold(3)));
else
    nn_out = find( abs(along_track_mean_array - array_in) > Threshold(2));
end

array_out(nn_out) = nan;

end
