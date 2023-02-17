function string_out = return_a_string(num_in)
% return_a_string = returns a 2 digit string with leading 0 if ivar < 10 - PCC
%
% Converts the input variable from a number to a string and adds 0 to the
% front if the number is less than 10.
% 
% INPUT
%   num_in - the number to convert to a string.
%
% OUTPUT
%   string_out - the string to return.

string_out = num2str(num_in);
if num_in < 10
    string_out = ['0' string_out];
end
