#!/bin/bash

# Associate fixed IP address if on spot instance

# Check if the current user is not 'ubuntu'

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

# Now define the output directory

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

# write commands to excecute here

echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
date  | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
echo "Starting the script..." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
echo "I am $(whoami) and proud of it" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"

# Ensure the output directory exists, if it doesn't, create it.

mkdir -p "$LOCAL_OUTPUT_DIRECTORY"
echo "Checked for the output directory, created if it did not exist." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"

# Change to the directory and pull the latest changes as user ubuntu

if [ "$(whoami)" != "ubuntu" ] && [ "$(whoami)" != "petercornillon" ]; then
    echo "Pulling to $LOCAL_MATLAB_PROJECT_DIRECTORY as user ubuntu" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
    sudo -u ubuntu bash -c "
        cd "$LOCAL_MATLAB_PROJECT_DIRECTORY" &&
        git pull
    "
else
    echo "Pulling to $LOCAL_MATLAB_PROJECT_DIRECTORY as user $(whoami)" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
    cd "$LOCAL_MATLAB_PROJECT_DIRECTORY"
    git pull
fi

# Sanity check to make sure that it pulled properly.
 
sed -n '51p' "${LOCAL_MATLAB_PROJECT_DIRECTORY}batch_jobs/AWS_batch_test.m" 2>&1 | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"

# Submit Python job to copy .nc4 files from local storage to remote storage. Note that we first move to the folder with the copy script in it.

if [ "$(whoami)" != "petercornillon" ]; then

    cd Shell_Scripts

    CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
    FILENAME="AWS_copy_${CURRENT_TIME}.out"
    echo "Current time is $CURRENT_TIME and it will write the output for the Python portion to $FILENAME"

    nohup python "${LOCAL_MATLAB_PROJECT_DIRECTORY}Shell_Scripts/AWS_copy_nc4_to_remote.py" > "${LOCAL_OUTPUT_DIRECTORY}/${FILENAME}" 2>&1 &
fi

# Start Matlab and run test script. 

echo "I am about to fire up Matlab." 2>&1 | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"

# sudo -u ubuntu -i bash -c 'nohup matlab -batch "prj=openProject('${LOCAL_MATLAB_PROJECT_DIRECTORY}MODIS_L2.prj'); AWS_batch_test;" > "${LOCAL_OUTPUT_DIRECTORY}/${FILENAME}" 2>&1 | tee -a "${LOCAL_OUTPUT_DIRECTORY}/tester_session_log.txt" &'


sudo -u ubuntu bash -c '
  export REMOTE_OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
  export REMOTE_MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"
  export REMOTE_OUTPUT_DIRECTORY_NOHUP="/mnt/uri-nfs-cornillon/Logs/nohup/"
  echo "Am running in sudo submitted version of script." | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log.txt"
  cd "$REMOTE_MATLAB_PROJECT_DIRECTORY"
  echo "Pulling to $REMOTE_MATLAB_PROJECT_DIRECTORY as user $(whoami)" | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log.txt"
  git pull
  FILENAME="matlab_$(date +'%Y-%m-%d_%H-%M-%S').out"
  echo "Starting Matlab as user $(whoami)" | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log.txt"
  nohup matlab -batch "prj=openProject('\''$REMOTE_MATLAB_PROJECT_DIRECTORY/MODIS_L2.prj'\''); AWS_batch_test;" > "$REMOTE_OUTPUT_DIRECTORY/$FILENAME" 2>&1 &
  echo "Just started Matlab."  | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remote_session_log.txt" '

echo "I just started Matlab. Am still $(whoami). It should be running in the background." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"

echo "Script execution completed."

