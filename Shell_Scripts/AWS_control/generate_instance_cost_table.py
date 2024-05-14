import json
import subprocess
from prettytable import PrettyTable

# Static on-demand pricing (example prices, update as needed)
on_demand_pricing = {
    't2.micro': '0.0116',
    't2.small': '0.023',
    't2.medium': '0.0464',
    'r7i.xlarge': '0.2646',
    't3a.large': '0.0752',
    'x2iedn.xlarge': '0.83363',
    'x2iedn.24xlarge': '20.007',
    # Add other instance types as needed
}

# Function to run AWS CLI commands and return the output
def run_aws_cli_command(command):
    result = subprocess.run(command, capture_output=True, text=True, shell=True)
    if result.returncode != 0:
        print(f"Command failed with error: {result.stderr}")
    return result.stdout.strip()

# Get instance details
instance_details_command = (
    "aws --profile iam_pcornillon ec2 describe-instances --query "
    "\"Reservations[*].Instances[*].{InstanceID:InstanceId,Name:Tags[?Key=='Name'].Value|[0],"
    "InstanceType:InstanceType,ImageID:ImageId,State:State.Name,PublicIP:PublicIpAddress,"
    "SpotInstanceRequestID:SpotInstanceRequestId,AvailabilityZone:Placement.AvailabilityZone}\" --output json"
)
instance_details_json = run_aws_cli_command(instance_details_command)

# Check if instance_details_json is empty
if not instance_details_json:
    print("No instance details returned. Exiting.")
    exit(1)

instance_data = json.loads(instance_details_json)

# Initialize the table
table = PrettyTable()
table.field_names = ["Instance ID", "Name", "Instance Type", "Image ID", "State", "Public IP", "Spot Instance Request ID", "On-Demand Price", "Spot Price"]

# Function to get the most recent spot price for an instance type in a specific availability zone
def get_spot_price(instance_type, availability_zone):
    spot_price_command = (
        f"aws --profile iam_pcornillon ec2 describe-spot-price-history --instance-types {instance_type} "
        f"--availability-zone {availability_zone} --query 'SpotPriceHistory[0].SpotPrice' --output text"
    )
    spot_price = run_aws_cli_command(spot_price_command)
    return spot_price if spot_price else 'N/A'

# Extract relevant information and fetch prices
for reservation in instance_data:
    for instance in reservation:
        instance_id = instance.get('InstanceID', 'N/A')
        name = instance.get('Name', 'N/A')
        instance_type = instance.get('InstanceType', 'N/A')
        image_id = instance.get('ImageID', 'N/A')
        state = instance.get('State', 'N/A')
        public_ip = instance.get('PublicIP', 'N/A')
        spot_instance_request_id = instance.get('SpotInstanceRequestID', 'N/A')
        availability_zone = instance.get('AvailabilityZone', 'N/A')
        
        # Get on-demand price
        on_demand_price = on_demand_pricing.get(instance_type, 'N/A')
        formatted_on_demand_price = f"${on_demand_price}" if on_demand_price != 'N/A' else 'N/A'

        # Get spot price if applicable
        spot_price = get_spot_price(instance_type, availability_zone) if spot_instance_request_id not in ['N/A', None] else 'N/A'
        formatted_spot_price = f"${spot_price}" if spot_price != 'N/A' else 'N/A'
        
        # Add a row to the table
        table.add_row([instance_id, name, instance_type, image_id, state, public_ip, spot_instance_request_id, formatted_on_demand_price, formatted_spot_price])

# Print the table
print(table)
