#!/bin/bash

# The profile and JSON specification file should be configured prior to running this script
PROFILE="iam_pcornillon"
SPEC_FILE="specification.json"
EXPECTED_IP="44.235.238.218"

# Submit the spot instance request
REQUEST_ID=$(aws ec2 --profile $PROFILE request-spot-instances --instance-count 1 --type "one-time" --launch-specification file://$SPEC_FILE --query 'SpotInstanceRequests[0].SpotInstanceRequestId' --output text)

echo "Spot instance request submitted. Request ID: $REQUEST_ID"

# Function to get the public IP of the spot instance
get_spot_instance_ip() {
    aws ec2 describe-spot-instance-requests --profile $PROFILE --spot-instance-request-ids $REQUEST_ID --query 'SpotInstanceRequests[0].InstanceId' --output text | xargs -I {} aws ec2 describe-instances --profile $PROFILE --instance-ids {} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
}

sleep 30 # Wait for 30 seconds before checking for 44.235.238.218

# Poll for the spot request to be fulfilled and for the IP to be the expected one
while true; do
    PUBLIC_IP=$(get_spot_instance_ip)
    
    if [[ $PUBLIC_IP == "None" ]]; then
        echo "Spot instance not ready yet..."
    elif [[ $PUBLIC_IP == $EXPECTED_IP ]]; then
        echo "Spot instance is ready with the expected IP: $PUBLIC_IP"
        break
    else
        echo "Spot instance has a different IP: $PUBLIC_IP"
    fi

    sleep 20 # Wait for 20 seconds before checking again
done

# SSH into the instance once ready
# Note: It's better to use key-based authentication if possible
ssh -o StrictHostKeyChecking=no ubuntu@$EXPECTED_IP

# If using sshpass and password is stored in a secure location you could uncomment the following line
# sshpass -f /path/to/passwordfile ssh -o StrictHostKeyChecking=no ubuntu@$EXPECTED_IP