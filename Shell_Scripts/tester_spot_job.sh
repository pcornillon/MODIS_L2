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

echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt
echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt
date 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt
echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt
echo "Starting the script..." 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt

# Generate the output filename for this job.s

CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="tester_${CURRENT_TIME}.out"

echo "Current time is $CURRENT_TIME and it will write the output for the Matlab portion to $FILENAME" 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt
echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt
echo "Now you need to ssh to the spot instance: ssh -o StrictHostKeyChecking=no ubuntu@44.235.238.218" 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt
echo "and submit Matlab job as follows: " 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt
echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt
echo "nohup matlab -nodisplay -nosplash -nodesktop -r \"prj=openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj'); AWS_batch_tester\" > \"/mnt/uri-nfs-cornillon/Logs/nohup/$FILENAME\" 2>&1 &" 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt

echo "Script execution completed." 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt
