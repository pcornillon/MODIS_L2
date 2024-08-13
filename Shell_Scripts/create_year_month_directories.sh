# Linux script to create year and month directories.

base_dir="/datadisk/SST"

# Create the SST directory if it doesn't exist

mkdir -p "$base_dir"

# Loop through the years 2002 to 2020

for year in {2002..2020}; do
    # Create the year directory

    mkdir -p "$base_dir/$year"
    
    # Loop through the months 01 to 12

    for month in {01..12}; do
        # Create the month directory within the year directory

        mkdir -p "$base_dir/$year/$month"
    done
done

# Set the ownership of the SST directory and its contents to user 'ubuntu'

chown -R ubuntu:ubuntu "$base_dir"
