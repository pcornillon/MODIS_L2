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
    LOCAL_MATLAB_PROJECT_DIRECTORY="/Users/petercornillon/Git_repos/MODIS_L2/"
    touch "${LOCAL_OUTPUT_DIRECTORY}/proof_of_life"
else
    LOCAL_MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"
    touch /home/ubuntu/proof_of_life
fi

# Ensure the output directory exists, if it doesn't, create it.

mkdir -p "$LOCAL_OUTPUT_DIRECTORY"
echo "Checked for the output directory, created if it did not exist." | sudo tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"

# Some output.

echo "" | sudo tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
echo "" | sudo tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
date  | sudo tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
echo "" | sudo tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
echo "Starting spot dummy job..." | sudo tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"

# Change to the git repo directory for this project and pull the latest changes as user ubuntu

if [ "$(whoami)" != "ubuntu" ] && [ "$(whoami)" != "petercornillon" ]; then
    echo "Pulling to $LOCAL_MATLAB_PROJECT_DIRECTORY as user ubuntu" | sudo tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
    sudo -u ubuntu bash -c "
        cd "$LOCAL_MATLAB_PROJECT_DIRECTORY" &&
        git pull
    "
else
    echo "Pulling to $LOCAL_MATLAB_PROJECT_DIRECTORY as user $(whoami)" | sudo tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"
    cd "$LOCAL_MATLAB_PROJECT_DIRECTORY"
    git pull
fi

echo "All done." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/local_session_log.txt"

