% compare_orbits - reads specified field from pairs of orbits and differences them - PCC
%
% Specify the directories with the data to be compared. The script will
% then do a dir on those directories for files beginning with AQ and then
% step through the list, plotting the the fields and printing out the min
% and max of each field excluding nans.

var_to_read = 'SST_In';

base_dir_1 = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test1/2010/06/';
base_dir_2 = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test3/2010/06/';

ddlist_1 = dir([base_dir_1 'AQ*']);
ddlist_2 = dir([base_dir_2 'AQ*']);

for i=1:5
    fi_1 = [ddlist_1(i).folder '/' ddlist_1(i).name]
    fi_2 = [ddlist_2(i).folder '/' ddlist_2(i).name]
    sst_in_1  = ncread(fi_1, var_to_read);
    sst_in_2  = ncread(fi_2, var_to_read);
    figure(1)
    imagesc(sst_in_1')
    figure(2)
    imagesc(sst_in_2')
    [min(sst_in_1 - sst_in_2, [], 'all', 'omitnan') max(sst_in_1 - sst_in_2, [], 'all', 'omitnan') ]
    well = input('next');
end