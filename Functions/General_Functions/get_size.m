function nbytes = get_size
% get_size - get the total number of bytes assigned to variables in this workspace - PCC
%
% This function issues the whos command, saving the results in a structure.
% It then loops over all elements of the resulting structure, one element
% for each varible in the workspace and sums the bytes associated with the
% element.
% 
% INPUT 
%   None
%
% OUTPUT
%   nbytes - the total # of bytes with variables in the current workspace.
%

var_array = evalin('caller', 'whos');

nbytes = 0;
for ipcc=1:length(var_array)
    nbytes = nbytes + var_array(ipcc).bytes;
end

fnnames = dbstack;

if nbytes < 10^5
    fprintf('\n%5.2f kilobytes required by all variables in %s at line %i.\n\n', nbytes/10^3, fnnames(2).name, fnnames(2).line)
elseif nbytes < 10^8
    fprintf('\n%5.2f megabytes required by all variables in %s at line %i.\n\n', nbytes/10^6, fnnames(2).name, fnnames(2).line)
else
    fprintf('\n%5.2f gigabytes required by all variables in %s at line %i.\n\n', nbytes/10^9, fnnames(2).name, fnnames(2).line)
end

end