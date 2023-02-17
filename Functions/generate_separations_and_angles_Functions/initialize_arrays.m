function [array_out, array_out_2, num_out] = initialize_arrays( array_in)
% % % function [array_out, array_out_2, num_out] = initialize_arrays( array_in, nn)
% initialize_arrays - create three single precision arrays based on the input array - PCC 
%
% This function has been designed to setup an array, its square and to zero
% a counter array for generate_separations_angles. These arrays are used
% when for sums over a set of orbits.path
%
% INPUT
%   array_in - the input array.
% % % %   nn - if present will set the counter array, num_out, for these elements
% % % %    to zero. This is used if the element has failed some other test.
%
% OUTPUT
%   array_out - the input array set to single precision
%   array_out_2 - the square of the input array, also set to single precision.
%   num_out - a single precision array the same size as array_in set to 1s
%    except at nn locations, which are set to 0.
%

array_out = single(array_in);
array_out_2 = single(array_in.^2);

num_out = single(ones(size(array_out)));
nn = find(isnan(array_out)==1);
% % % if isempty(nn) == 0
    num_out(nn) = 0;
% % % end

end
