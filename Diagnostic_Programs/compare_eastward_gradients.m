function compare_eastward_gradients(output_file_directory)
% compare_eastward_gradients - test the output of a test run of build_and_fix_orbits.
% 
% The script will read in the eastward gradients from the file just
% createdc by build_and_fix_orbits and the eastward gradients output by
% the same program run previously. It then differences the files to and
% prints out the max and min differences. If all went well, these will be
% 0.
%
% INPUT
%   output_file_directory - the folder with the file just written by
%    build_and_fix_orbits and the comparison file downloaded from Zenodo.
%    This folder is needed for the comparison of the outputs.
%
% OUTPUT
%   none
%
% Sample call-note that the folder name is in quotes and ends with / (for a
% Mac):
%   compare_eastward_gradients(output_file_directory)
%

% Get the directory separator for this computer type.

if ~isempty(strfind(computer, 'MAC')) | ~isempty(strfind(computer, 'GLN'))
    DirectorySeparator = '/';
elseif ~isempty(strfind(computer, 'PC'))
    DirectorySeparator = '\';
end

% Get the eastward gradients from the file downloaded from Zenodo.

nn = strfind( output_file_directory, DirectorySeparator);

fi_orig = [output_file_directory(1:nn(end-1)) 'AQUA_MODIS.20100619T052031.L2.SST.nc4'];
e_grad_orig = ncread( fi_orig, 'eastward_gradient');

% Get the eastward gradients from the file just created.

fi_new = [output_file_directory '2010' DirectorySeparator '06' DirectorySeparator 'AQUA_MODIS.20100619T052031.L2.SST.nc4'];
e_grad_new = ncread( fi_new, 'eastward_gradient');

% Difference the fiedlds.

e_grad_diff = e_grad_orig - e_grad_new;

min_diff = min(e_grad_diff(:));
max_diff = min(e_grad_diff(:));

if min_diff == 0 & max_diff == 0
    fprintf('\n\nGood job, the test and comparison files are the same.\n\n')
else
    fprintf('\n\nGulp, the files do not compare. I''m going to turn control over to you.\n\n')
    keyboard
end