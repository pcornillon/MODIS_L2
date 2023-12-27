function string_out = return_a_string( num_digits, num_in)
% return_a_string = returns a 2 digit string with leading 0 if ivar < 10 - PCC
%
% Converts the input variable from a number to a string and adds 0 to the
% front if the number is less than 10.
% 
% INPUT
%   num_digits - the number of digits in the output string. Will zero fill
%    the leading digits needed to make num_out the proper number of digits.
%   num_in - the number to convert to a string.
%
% OUTPUT
%   string_out - the string to return.

string_out = num2str(num_in);

% Make sure that the number of digits passed in is not longer than the
% number of requested digits. If so write a message and return, as a string,
% the number passed in.

if num_in > 10^(num_digits-1)
    fprintf('\n\n*******************\nPassed in %i but asked that the output have %i digits; clearly a conflict.\n********************\n\n', num_in, num_digits)
end

for iDigit=2:num_digits
    if num_in < 10^(iDigit-1)
        string_out = ['0' string_out];
    end
end