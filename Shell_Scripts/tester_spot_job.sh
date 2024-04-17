#!/bin/bash

# If LOCAL equals 0 then, associate fixed IP address, needed to mount uri disk 
# but also makes things easier since the requested spot instance will always 
# have the same IP  address: ubuntu@44.235.238.218. Will set directories for
# AWS
#
# Otherwise will set directories for my laptop.

OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
MATLAB_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"

LOCAL=2

if [ $LOCAL -eq 0 ]
then
    echo "Not local, OUTPUT_DIRECTORY is $OUTPUT_DIRECTORY"
    
    # Commands to execute if the condition is true
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
    OUTPUT_DIRECTORY="/Users/petercornillon/Logs/"
    MATLAB_DIRECTORY="/Users/petercornillon/Git_repos/MODIS_L2/" 

    echo "Local, OUTPUT_DIRECTORY is $OUTPUT_DIRECTORY"
fi 

OUTPUT_DIRECTORY_NOHUP="${OUTPUT_DIRECTORY}nohup/"

# Start the session log.

echo "" 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
echo "" 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
date 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
echo "" 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
echo "Starting the script..." 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt

# Generate the output filename for this job.s

CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="tester_${CURRENT_TIME}.out"

echo "Current time is $CURRENT_TIME and it will write the output for the Matlab portion to $FILENAME" 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
echo "" 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
echo "Now you need to ssh to the spot instance: ssh -o StrictHostKeyChecking=no ubuntu@xx.xx.xx.xx" 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
echo "and submit Matlab job as follows: " 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
echo "" 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
echo "nohup matlab -nodisplay -nosplash -nodesktop -r \"prj=openProject('${MATLAB_DIRECTORY}MODIS_L2.prj'), AWS_batch_tester, exit\" > \"${OUTPUT_DIRECTORY_NOHUP}$FILENAME\" 2>&1 &" 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
echo "" 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt
echo "Script execution completed." 2>&1 | tee -a ${OUTPUT_DIRECTORY}tester_session_log.txt

# nohup matlab -nodisplay -nosplash -nodesktop -r "prj=openProject('${MATLAB_DIRECTORY}MODIS_L2.prj'), AWS_batch_tester, exit" > "${OUTPUT_DIRECTORY_NOHUP}${FILENAME}" 2>&1 & tee -a "${OUTPUT_DIRECTORY}tester_session_log.txt"