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
echo "Checked for the output directory, created if it did not exist." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"

# Some output.

echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"
echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"
date  | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"
echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"
echo "Starting the script..." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"
echo "I am $(whoami) and proud of it" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"

# Change to the git repo directory for this project and pull the latest changes as user ubuntu

if [ "$(whoami)" != "ubuntu" ] && [ "$(whoami)" != "petercornillon" ]; then
    echo "Pulling to $LOCAL_MATLAB_PROJECT_DIRECTORY as user ubuntu" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"
    sudo -u ubuntu bash -c "
        cd "$LOCAL_MATLAB_PROJECT_DIRECTORY" &&
        git pull
    "
else
    echo "Pulling to $LOCAL_MATLAB_PROJECT_DIRECTORY as user $(whoami)" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"
    cd "$LOCAL_MATLAB_PROJECT_DIRECTORY"
    git pull
fi

# Start Matlab and submit the jobs to submit batch jobs for processing. 

echo "I am about to fire up Matlab." 2>&1 | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"

sudo -u ubuntu bash -c '
  export REMOTE_OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
  export REMOTE_MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"
  export REMOTE_OUTPUT_DIRECTORY_NOHUP="/mnt/uri-nfs-cornillon/Logs/nohup/"
  echo "Am running in sudo submitted version of script." | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log_rmf.txt"
  cd "$REMOTE_MATLAB_PROJECT_DIRECTORY"
  echo "Pulling to $REMOTE_MATLAB_PROJECT_DIRECTORY as user $(whoami)" | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log_rmf.txt"
  git pull
  FILENAME="matlab_rmf_$(date +'%Y-%m-%d_%H-%M-%S').out"
  echo "Starting Matlab as user $(whoami)" | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log_rmf.txt"
  nohup matlab -batch "prj=openProject('\''$REMOTE_MATLAB_PROJECT_DIRECTORY/MODIS_L2.prj'\''); remove_missing_data_filenames_from_granuleList;" > "$REMOTE_OUTPUT_DIRECTORY/$FILENAME" 2>&1 &
  echo "Just started Matlab."  | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log_rmf.txt" '

echo "I just started Matlab. Am still $(whoami). It should be running in the background. This script is finished." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log_rmf.txt"

