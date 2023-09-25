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

var_array = whos;

nbytes = 0;
for ipcc=1:length(var_array)
nbytes = nbytes + var_array(ipcc).bytes;
end

end