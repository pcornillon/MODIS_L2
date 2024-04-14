#!/bin/bash

# Associate fixed IP address, needed to mount uri disk but also makes things
# easier since the requested spot instance will always have the same IP 
# address: ubuntu@44.235.238.218

MYID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

su ubuntu -c "/usr/local/bin/aws --profile iam_pcornillon ec2 associate-address --allocation-id eipalloc-095c69c402b90902b --instance-id ${MYID}"

while true; do
    myip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
    if [[ "$myip" == "44.235.238.218" ]]; then
        break
    else
        sleep 2
    fi
done

umount /mnt/uri-nfs-cornillon
mount /mnt/uri-nfs-cornillon

# Start the session log.

echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
date 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
echo "Starting the script..." 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt

echo "I am $(whoami) and proud of it" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt

touch /home/ubuntu/proof_of_life

# Define the Matlab Project directory.

MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"

# Define the output directory for the nohup logs to be generated from the Matlab and python commands below.

OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/nohup/"

# Ensure the output directory exists, if it doesn't, create it.

mkdir -p "$OUTPUT_DIRECTORY"
echo "Checked for the output directory, created if it did not exist." 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt

# Make sure that we are using the most recent version of MODIS_L2

cd "$MATLAB_PROJECT_DIRECTORY"
echo "Pulling to $MATLAB_PROJECT_DIRECTORY" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
su ubuntu -c 'git pull' 

# Generate the output filename for this job.

CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="matlab_${CURRENT_TIME}.out"

echo "Current time is $CURRENT_TIME and it will write the output for the Matlab portion to $FILENAME" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
echo "Now you need to ssh to the spot instance: ssh -o StrictHostKeyChecking=no ubuntu@44.235.238.218" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
echo "and submit Matlab job as follows: "
echo "nohup matlab -nodisplay -nosplash -nodesktop -r "prj=openProject('/home/ubuntu/Documents/MODIS_L2MODIS_L2.prj'); AWS_batch_test"  > "/mnt/uri-nfs-cornillon/Logs/nohup/$FILENAME" 2>&1 &'

# Submit Python job to copy .nc4 files from local storage to remote storage. Note that we first move to the folder with the copy script in it.

cd Shell_Scripts

CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="AWS_copy_${CURRENT_TIME}.out"
echo "Current time is $CURRENT_TIME and it will write the output for the Python portion to $FILENAME"

nohup python "${MATLAB_PROJECT_DIRECTORY}Shell_Scripts/AWS_copy_nc4_to_remote.py" > "${OUTPUT_DIRECTORY}/${FILENAME}" 2>&1 &

echo "Script execution completed."
