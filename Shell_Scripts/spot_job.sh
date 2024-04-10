#!/bin/bash
# write commands to excecute here

echo "Starting the script..."

touch /home/ubuntu/proof_of_life

# Define the Matlab Project directory.

MATLAB_PROJECT_DIRECTORY = "/home/ubuntu/Documents/MODIS_L2/"

# Define the output directory for the nohup logs to be generated from the Matlab and python commands below.

OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/nohup/"

# Ensure the output directory exists, if it doesn't, create it.

mkdir -p "$OUTPUT_DIRECTORY"
echo "Checked for the output directory, created if it did not exist."

# Make sure that we are using the most recent version of MODIS_L2

cd "$MATLAB_PROJECT_DIRECTORY"
git pull

# Start Matlab and run test script. The script it runs will exit after at least 75% (which could be changed, e.g./ to 100%) of the jobs have finished
# or after the estimated required processing time has elapsed. It estimates this time based on the time for one of the submitted batch jobs to finish.
# It estimates this time assuming 100 minutes per orbit and 11 minutes to process an orbit. These numbers are changeable depending on how fast the CPU is.
# Note that the command opens the Matlab project for MODIS_L2. From there it finds all of the functions it needs. First, construct the output filename
# then execute the command

CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="matlab_${CURRENT_TIME}.out"
echo "Current time is $CURRENT_TIME and it will write the output for the Matlab portion to $FILENAME"

nohup matlab -nodisplay -nosplash -nodesktop -r "prj=openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj'); AWS_batch_test"  > "${OUTPUT_DIRECTORY}${FILENAME}" 2>&1 &

# Submit Python job to copy .nc4 files from local storage to remote storage. Note that we first move to the folder with the copy script in it.

cd Shell_Scripts

CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="AWS_copy_${CURRENT_TIME}.out"
echo "Current time is $CURRENT_TIME and it will write the output for the Python portion to $FILENAME"

#nohup python "${MATLAB_PROJECT_DIRECTORY}Shell_Scripts/AWS_copy_nc4_to_remote.py" > "${OUTPUT_DIRECTORY}${FILENAME}" log 2>&1 &
nohup python "${MATLAB_PROJECT_DIRECTORY}Shell_Scripts/AWS_copy_nc4_to_remote.py" > "${OUTPUT_DIRECTORY}/${FILENAME}" 2>&1 &

echo "Script execution completed."
