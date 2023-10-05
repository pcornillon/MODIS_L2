#!/bin/tcsh

# Now run process_orbits

# To run it. From the command line type:
#
# ./process_orbits BaseDir StartTime EndTime
#
# where start and end times are of the form: [yyyy mm dd hh mi ss], mi is minutes
#
# e.g. ./process_orbits [2010 4 19 0 0 0] [2010 4 19 23 59 59]
#

PATH=/Applications/MATLAB_R2011a.app/bin:$PATH
unsetenv DISPLAY
/Applications/MATLAB_R2011a.app/bin/matlab <<EOF

 addpath /home/ubuntu/Documents/MODIS_L2/Main_Programs/
 
! eval(['diary(''$1SupportingFiles/LogFiles/PathFinderFrontStatsByPixel-' '$2' '-' '$3' '.log'')'])

 YearStart = '$1';
 YearEnd = '$2';

 whos

 build_and_fix_orbits( YearStart, YearEnd)
EOF
