function [orbits_directory, granules_directory, metadata_directory, fixit_directory, ...
    logs_directory, output_file_directory_local] = setup_for_build_fix_test_run(base_dir)
% setup_for_build_fix_test_run - creates the folders into which the data required to test build_and_fix_orbits are placed.
% 
% Run this script to setup the directories needed for a test run of build_and_fix_orbits.
%
% After you have run this script you will need to download the various
% files needed either for an actual run or for a test run. For a test run
%
% INPUT
%   base_dir - the folder into which you will put all folders and data
%    needed for a test run.
%
% OUTPUT
%   orbits_directory -
%   granules_directory -
%   metadata_directory -
%   fixit_directory -
%   logs_directory -
%   output_file_directory_local - the folder with the file just written by
%    build_and_fix_orbits and the comparison file downloaded from Zenodo.
%    This folder is needed for the comparison of the outputs.
%
% Sample call-note that the folder name is in quotes and ends with / (for a
% Mac):
%   setup_for_build_fix_test_run('/Users/petercornillon/Desktop/')
%

% Get the directory separator for this computer type.

if ~isempty(strfind(computer, 'MAC')) | ~isempty(strfind(computer, 'GLN'))
    DirectorySeparator = '/';
elseif ~isempty(strfind(computer, 'PC'))
    DirectorySeparator = '\';
end

% Start by making the directories needed for the test run.

eval(['! mkdir ' base_dir 'build_test'])
eval(['! mkdir ' base_dir 'build_test' DirectorySeparator 'test_dir_a'])
eval(['! mkdir ' base_dir 'build_test' DirectorySeparator 'test_dir_b'])
eval(['! mkdir ' base_dir 'build_test' DirectorySeparator 'test_dir_c'])

eval(['! mkdir ' base_dir 'build_test' DirectorySeparator 'test_dir_c' DirectorySeparator 'Logs'])
eval(['! mkdir ' base_dir 'build_test' DirectorySeparator 'test_dir_c' DirectorySeparator 'Output'])
eval(['! mkdir ' base_dir 'build_test' DirectorySeparator 'test_dir_c' DirectorySeparator 'Output' DirectorySeparator '2010'])
eval(['! mkdir ' base_dir 'build_test' DirectorySeparator 'test_dir_c' DirectorySeparator 'Output' DirectorySeparator '2010' DirectorySeparator '06'])

% Define variables to use for the directory names used by build_and_fix_orbits. 

granules_directory = [base_dir 'build_test' DirectorySeparator 'test_dir_a' DirectorySeparator 'MODIS_R2019' DirectorySeparator];
orbits_directory = [base_dir 'build_test' DirectorySeparator 'test_dir_a' DirectorySeparator 'MODIS_R2019' DirectorySeparator 'Orbits' DirectorySeparator];
metadata_directory = [base_dir 'build_test' DirectorySeparator 'test_dir_a' DirectorySeparator 'MODIS_R2019' DirectorySeparator 'Data_from_OBPG_for_PO-DAAC' DirectorySeparator];
fixit_directory = [base_dir 'build_test' DirectorySeparator 'test_dir_b' DirectorySeparator];
logs_directory = [base_dir 'build_test' DirectorySeparator 'test_dir_c' DirectorySeparator 'Logs' DirectorySeparator];
output_file_directory_local = [base_dir 'build_test' DirectorySeparator 'test_dir_c' DirectorySeparator 'Output' DirectorySeparator];

lines = {'Great, you''ve created the necessary folders and the variables pointing to these folders,' ...
    'now populate them with data from https://doi.org/10.5281/zenodo.7655067 as follows' ...
    '(be patient, downloads can be slow, like 5-10 minutes for the bigger files):' ...
    ['1) Download and unzip MODIS_R2019.zip into ' base_dir 'build_test' DirectorySeparator 'test_dir_a (1.22 GB when decompressed).'] ...
    ['2) Download Separation_and_Angle_Arrays.n4 into ' base_dir 'build_test' DirectorySeparator 'test_dir_b' DirectorySeparator ' (390 MB).'] ...
    ['3) Download SST_Range_for_Declouding.mat into ' base_dir 'build_test' DirectorySeparator 'test_dir_b' DirectorySeparator ' (1.7 MB).'] ...
    ['4) Download weights_and_locations_from_31191.mat into ' base_dir 'build_test' DirectorySeparator 'test_dir_b' DirectorySeparator ' (763 MB).'] ...
    ['5) Download AQUA_MODIS.20100619T052031.L2.SST.nc4 into ' base_dir 'build_test' DirectorySeparator 'test_dir_c' DirectorySeparator ' (434 MB).'] ...
    'When you have populated the folders enter the following two lines at the Matlab command prompt:' ...
    '[timing problem_list] = build_and_fix_orbits(  orbits_directory, granules_directory, metadata_directory, fixit_directory, ...' ...
    '   logs_directory, output_file_directory_local, [2010 6 19 5 25 0], [2010 6 19 5 30 0 ], 1, 1, 1, 1);' ...
    'This will build and fix one orbit (about 5 minutes on my computer), which it will place in the ' ...
    [base_dir 'build_test' DirectorySeparator 'test_dir_c' DirectorySeparator 'Output' DirectorySeparator '2010' DirectorySeparator '06' DirectorySeparator ' folder.'] ...
    'To determine if it has performed correctly, in the Matlab command line type:\n compare_outputs.'};

% fprintf('\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n\n%s\n%s\n%s\n%s\n', lines{1}, lines{2}, lines{3}, lines{4}, lines{5}, lines{6}, lines{7}, lines{8}, lines{9}, lines{10}, lines{11}, lines{12}, lines{13})

fprintf('\n\n')
for iLine=1:length(lines)
    if iLine==3 | iLine==8 | iLine==9 | iLine==11 | iLine==13
        fprintf('%s\n\n', lines{iLine})
    else
        fprintf('%s\n', lines{iLine})
    end
end
