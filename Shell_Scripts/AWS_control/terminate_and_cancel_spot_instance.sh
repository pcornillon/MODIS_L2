#!/bin/bash

# Profile name for AWS CLI
PROFILE="iam_pcornillon"

# Fetch the details of the running instance with a public IP and a SpotInstanceRequestID
instance_details=$(aws ec2 --profile $PROFILE describe-instances \
  --query 'Reservations[*].Instances[*].{InstanceID:InstanceId, PublicIP:PublicIpAddress, SpotInstanceRequestID:SpotInstanceRequestId, State:State.Name}' \
  --output text | awk '$2 != "None" && $3 != "None" && $4 == "running" {print $1, $3}')

# Check if instance details are available
if [ -z "$instance_details" ]; then
  echo "No running instances with a public IP and a spot instance request ID were found."
  exit 0
fi

# Read Instance ID and Spot Instance Request ID
read -r INSTANCE_ID SPOT_INSTANCE_REQUEST_ID <<< "$instance_details"

# Terminate instance
echo "Terminating instance with ID: $INSTANCE_ID"
aws ec2 --profile $PROFILE terminate-instances --instance-id $INSTANCE_ID

# Cancel spot instance request
echo "Cancelling spot instance request with ID: $SPOT_INSTANCE_REQUEST_ID"
aws ec2 --profile $PROFILE cancel-spot-instance-requests --spot-instance-request-ids $SPOT_INSTANCE_REQUEST_ID
