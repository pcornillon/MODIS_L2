#!/bin/bash

# Associate fixed IP address if on spot instance

# If the current user is not 'ubuntu' or 'petercornillon', then it is likely root, which 
# means that we are probably running a spot instance so need to attach the uri-nfs-cornillon
# disk.

if [ "$(whoami)" != "ubuntu" ] && [ "$(whoami)" != "petercornillon" ]; then
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
else
    echo "Running as user: $(whoami)"
fi

# Now define the output directory for the log file for the local linux session.

if [ "$(whoami)" = "petercornillon" ]; then
    LOCAL_OUTPUT_DIRECTORY="/Users/petercornillon/Logs/"
    LOCAL_MATLAB_PROJECT_DIRECTORY="/Users/petercornillon/Git_repos/MODIS_L2/"

    LOCAL_OUTPUT_DIRECTORY_NOHUP=$LOCAL_OUTPUT_DIRECTORY

    touch "${LOCAL_OUTPUT_DIRECTORY}/proof_of_life"
else
    LOCAL_OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
    LOCAL_MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"

    LOCAL_OUTPUT_DIRECTORY_NOHUP="/mnt/uri-nfs-cornillon/Logs/nohup/"

    touch /home/ubuntu/proof_of_life
fi

# Ensure the output directory exists, if it doesn't, create it.

mkdir -p "$LOCAL_OUTPUT_DIRECTORY"
echo "Checked for the output directory, created if it did not exist." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"

# Some output.

echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"
echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"
date  | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"
echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"
echo "Starting the script..." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"
echo "I am $(whoami) and proud of it" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"

# Change to the git repo directory for this project and pull the latest changes as user ubuntu

if [ "$(whoami)" != "ubuntu" ] && [ "$(whoami)" != "petercornillon" ]; then
    echo "Pulling to $LOCAL_MATLAB_PROJECT_DIRECTORY as user ubuntu" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"
    sudo -u ubuntu bash -c "
        cd "$LOCAL_MATLAB_PROJECT_DIRECTORY" &&
        git pull
    "
else
    echo "Pulling to $LOCAL_MATLAB_PROJECT_DIRECTORY as user $(whoami)" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"
    cd "$LOCAL_MATLAB_PROJECT_DIRECTORY"
    git pull
fi

# Create the temporary output folders on /datadisk. Start by defining the base directory.

base_dir="/datadisk/SST"

# Create the SST directory if it doesn't exist

# mkdir -p "$base_dir"

# Loop through the years 2002 to 2020

# for year in {2002..2020}; do
    # Create the year directory

#     mkdir -p "$base_dir/$year"
    
    # Loop through the months 01 to 12

#     for month in {01..12}; do
        # Create the month directory within the year directory

#         mkdir -p "$base_dir/$year/$month"
#     done
# done

# Set the ownership of the SST directory and its contents to user 'ubuntu'

# chown -R ubuntu:ubuntu "$base_dir"

# Output success message

# echo "Directory structure created for temporary storage of orbit output files and ownership set to ubuntu." 2>&1 | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"

# Submit Python job to copy .nc4 files from local storage to remote storage. Note that we first move to the folder with the copy script in it.

if [ "$(whoami)" != "petercornillon" ]; then

    cd Shell_Scripts

    LOCAL_CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
    LOCAL_FILENAME="AWS_copy_${LOCAL_CURRENT_TIME}.out"
    echo "Current time is $LOCAL_CURRENT_TIME and it will write the output for the Python portion to $LOCAL_FILENAME"

    nohup python "${LOCAL_MATLAB_PROJECT_DIRECTORY}Shell_Scripts/AWS_copy_nc4_to_remote.py" > "${LOCAL_OUTPUT_DIRECTORY}/${LOCAL_FILENAME}" 2>&1 &
fi

# Start Matlab and submit the jobs to submit batch jobs for processing. 

echo "I am about to fire up Matlab." 2>&1 | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"

sudo -u ubuntu bash -c '
  export REMOTE_OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
  export REMOTE_MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"
  export REMOTE_OUTPUT_DIRECTORY_NOHUP="/mnt/uri-nfs-cornillon/Logs/nohup/"
  echo "Am running in sudo submitted version of script." | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log_44_235_238_218.txt"
  cd "$REMOTE_MATLAB_PROJECT_DIRECTORY"
  echo "Pulling to $REMOTE_MATLAB_PROJECT_DIRECTORY as user $(whoami)" | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log_44_235_238_218.txt"
  git pull
  FILENAME="matlab_$(date +'%Y-%m-%d_%H-%M-%S').out"
  echo "Starting Matlab as user $(whoami)" | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log_44_235_238_218.txt"
  nohup matlab -batch "prj=openProject('\''$REMOTE_MATLAB_PROJECT_DIRECTORY/MODIS_L2.prj'\''); AWS_batch_44_235_238_218;" > "$REMOTE_OUTPUT_DIRECTORY/$FILENAME" 2>&1 &
  echo "Just started Matlab."  | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log_44_235_238_218.txt" '

echo "I just started Matlab. Am still $(whoami). It should be running in the background. This script is finished." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_44_235_238_218.txt"

