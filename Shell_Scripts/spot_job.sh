#!/bin/bash
# write commands to excecute here

# Make sure that we are using the most recent version of MODIS_L2

cd ~/Documents/MODIS_L2/
git pull

# Start Matlab and run test script. The script it runs will exit after at least 75% (which could be changed, e.g./ to 100%) of the jobs have finished
# or after the estimated required processing time has elapsed. It estimates this time based on the time for one of the submitted batch jobs to finish.
# It estimates this time assuming 100 minutes per orbit and 11 minutes to process an orbit. These numbers are changeable depending on how fast the CPU is.
# Note that the command opens the Matlab project for MODIS_L2. From there it finds all of the functions it needs.

nohup matlab -nodisplay -nosplash -nodesktop -r "prj=openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj'); MacStudio_AWS_batch_test_1" &

# Submit Python job to copy .nc4 files from local storage to remote storage. Note that we first move to the folder with the copy script in it.

cd Shell_Scripts

python AWS_copy_nc4_to_remote.py  

