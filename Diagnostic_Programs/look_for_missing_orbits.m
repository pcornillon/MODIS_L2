filelist = dir('/Volumes/MODIS_L2_Modified/OBPG/SST/2002/10/AQUA_MODIS_orbit_00*SST.nc4');
iGranule = 1;
filename = [filelist(iGranule).folder '/' filelist(iGranule).name];
nn = strfind( filename, '_orbit_');
last_orbit_no = str2num(filename(nn+7:nn+12))
for iGranule=2:length(filelist)
filename = [filelist(iGranule).folder '/' filelist(iGranule).name];
nn = strfind( filename, '_orbit_');
orbit_no = str2num(filename(nn+7:nn+12));
last_orbit_no = last_orbit_no + 1;
if last_orbit_no ~= orbit_no
fprintf('%i) last orbit was %i, this orbit is %i\n', iGranule,last_orbit_no-1, orbit_no)
last_orbit_no = orbit_no;
end
end
