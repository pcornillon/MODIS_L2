function [array_out, array_out_2, num_out] = increment_arrays( array_in, array_out, array_out_2, num_out)
% % % function [array_out, array_out_2, num_out] = increment_arrays( array_in, nn, array_out, array_out_2, num_out)
% % % increment_arrays - Add the current input array and its square to an accumulating sum of these arrays - PCC 
%
% This function is used in generate_separations_angles to accumulate sums
% of arrays (excluding nans), their squares and the number of non-nan 
% elements contributing to the sums. 
%
% INPUT
%   array_in - the input array.
% % % %   nn - if present will set the counter array, num_out, for these elements
% % % %    to zero. This is used if the element has failed some other test.
%   array_out - the sum to present of input arrays.
%   array_out_2 - the sum to present of square of input arrays.
%   num_out - the counter for the number of times an element had an
%    acceptable, i.e., not nan, value.
%
% OUTPUT
%   array_out - the sum of input arrays including the one passed in here.
%   array_out_2 - the sum of the square of input arrays including this one.
%   num_out - the counter for the number of times an element had an
%    acceptable, i.e., not nan, value.
%

% % % % Test to see if we really need to pass in nn.
% % % 
% % % mm = find(isnan(array_in)==1);
% % % 
% % % if length(mm) ~= length(nn)
% % %     for ipcc=1:length(nn)
% % %         num_kk(ipcc) = length(find(nn(ipcc)==mm));
% % %     end
% % %     if isempty(find(num_kk==0)) == 0
% % %         keyboard
% % %     end
% % % else
% % %     dd = sum(mm-nn);
% % %     if dd ~= 0
% % %         keyboard
% % %     end
% % % end
% % % 
% % % % Done with test.

array_out = reshape(sum([array_out(:), array_in(:)], 2, 'omitnan'), size(array_in));
array_out_2 = reshape(sum([array_out_2(:), array_in(:).^2], 2, 'omitnan'), size(array_in));

cc = ones(size(array_out));
nn = find(isnan(array_in)==1);
% % % if isempty(nn) == 0
    cc(nn) = 0;
% % % end
num_out = num_out + cc;

end
