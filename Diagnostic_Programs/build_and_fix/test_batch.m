% test_batch - tests apparent problem with load - PCC

check = 0;

BaseDir = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/MODIS_R2019/';
fixit_directory = [BaseDir 'metadata/'];

fixit_directory = [BaseDir 'metadata/'];

fprintf('%s. Does it exist: %i\n', [fixit_directory 'SST_Range_for_Declouding.mat'], exist([fixit_directory 'SST_Range_for_Declouding.mat']))
check = check + 1; fprintf('Made it to checkpoint %i\n', check)

load([fixit_directory 'SST_Range_for_Declouding.mat'])

check = check + 1; fprintf('Made it to checkpoint %i\n', check)
