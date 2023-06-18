% show_fix_bowtie - demo plots of impact of bow-tie and fixed version.
%
% Read sst input masked, fast regridded version and griddata version for an
% obit. Determine the gradient magnitudes of these, then plot them and
% histogram the differences.
%

fi = '~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/test4/2005/09/AQUA_MODIS_orbit_17970_20050919T054735_L2_SST.nc4';
ncdisp(fi)
sst_in = ncread( fi, 'SST_In');
dbquit
sst_in = ncread( fi, 'SST_In_Masked');
sst_fast = ncread( fi, 'regridded_sst');
sst_griddata = ncread( fi, 'regridded_sst_alternate');
dd_in_fast = sst_in - sst_fast;
dd_fast_griddata = sst_fast - sst_griddata;
imagesc(dd_in_fast')
set(gca,fontsize=24)
title('In - Fast', fontsize=30)
figure
imagesc(dd_fast_griddata')
set(gca,fontsize=24)
title('Fast- Griddata', fontsize=30)
axis([1000 1354 6870 7000])
caxis([-.1 .1])
[min(dd_fast_griddata(:))]
[min(dd_fast_griddata(:)) max(dd_fast_griddata(:))]
axis tight
caxis([-.1 .1])
colorbar
figure(1)
caxis([-.1 .1])
colorbar
map_axis_range('a', 2, 1)
figure
histogram(dd_in_fast)
ylim([])
dbquit
ylim([0 10000])
ylim([0 100000])
hh = histogram(dd_in_fast,[-1:0.01:1]);
hold on
hh2 = histogram(dd_fast_griddata,[-1:0.01:1]);
ylim([0 100000])
sst_griddata_med = medfilt2(sst_griddata);
figure
dd_fast_griddata_med = sst_fast - sst_griddata_med;
imagesc(dd_fast_griddata_med')
set(gca,fontsize=24)
title('Fast - Griddata_med', fontsize=30)
map_axis_range('a', 2, 4)
set(gca,fontsize=24)
map_axis_range('c', 2, 4)
colorbar
figure(3)
hh3 = histogram(dd_fast_griddata_med,[-1:0.01:1]);
whos *med*
clear *med*
hh3
hh3.Visible='off';
std(dd_in_fast)
std(dd_in_fast(:),'omitnan')
std(dd_fast_griddata(:),'omitnan')
1.62/0.1061
doc sobel
[~, ~, gm_in] = Sobel( sst_in, 1);
[~, ~, gm_fast] = Sobel( sst_fast, 1);
[~, ~, gm_griddata] = Sobel( sst_griddata, 1);
figure
imagesc(gm_in')
colorbar
caxis([0 .1])
caxis([0 1])
set(gca,fontsize=24)
title('Gradient Magnitude sst\_in', fontsize=30)
figure
imagesc(gm_griddata')
imagesc(gm_fast')
set(gca,fontsize=24)
title('Gradient Magnitude sst\_fast', fontsize=30)
caxis([0 1])
figure
imagesc(gm_griddata')
set(gca,fontsize=24)
title('Gradient Magnitude sst\_griddata', fontsize=30)
caxis([0 1])
map_axis_range('c', 2, 6)
map_axis_range('a', 2, 6)
caxis([0 1])
colorbar
caxis([0 0.5])
map_axis_range('a', 2, 5)
map_axis_range('a', 2, 4)
map_axis_range('a', 6, 4)
map_axis_range('a', 6, 5)
colorbar
caxis([0 0.5])
axis([800 1354 8801 9000])
map_axis_range('a', 4, 5)
map_axis_range('a', 4, 6)
axis([800 1354 8861 8940])
figure(4)
axis([800 1354 8861 8940])
figure(6)
axis([800 1354 8861 8940])
axis([800 1354 8901 8930])
figure(4)
axis([800 1354 8901 8930])
figure(4)
axis([1250 1354 8901 8930])
figure(4)
axis([1220 1354 8901 8930])
figure(5)
axis([1220 1354 8901 8930])
figure(6)
axis([1220 1354 8901 8930])
xx1 = gm_in(1221:1354, 8901:8930);
figure
imagesc(xx1)
figure(7)
imagesc(xx1')
caxis([0 0.5])
figure(7)
xx_in = gm_in(1221:1354, 8901:8930);
clear xx1
xx_fast = gm_fast(1221:1354, 8901:8930);
xx_griddata = gm_griddata(1221:1354, 8901:8930);
dd = xx_in - xx_fast;
dd_gm_in_fast = xx_in - xx_fast;
dd_gm_fast_griddata = xx_fast - xx_griddata;
figure
hhgm1 = histogram(dd_gm_in_fast)
hhgm1 = histogram(dd_gm_in_fast,[-.34:0.05:.5])
hhgm1 = histogram(dd_gm_in_fast,[-.34:0.02:.5])
hold on
hhgm2 = histogram(dd_gm_fast_griddata,[-.34:0.02:.5])
[std(dd_gm_in_fast(:),'omitnan') std(dd_gm_fast_griddata(:),'omitnan')]
0.62/0.0771