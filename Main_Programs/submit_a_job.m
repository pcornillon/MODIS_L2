% submit_a_job - submit a build_and_fix_orbits job passing in start and end times - PCC
%
%

% First make sure that the MODIS_L2 project has been openend and that the
% Main_programs directory is on the path.

 addpath /home/ubuntu/Documents/MODIS_L2/Main_Programs/

 prj = openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj')
 
 YearStart = '$1';
 YearEnd = '$2';

 whos

 build_and_fix_orbits( YearStart, YearEnd)
