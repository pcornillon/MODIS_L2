import re
import os
import argparse
from datetime import datetime
import calendar
import pytz

def extract_processing_times(single_file_path, data_output_filename='processing_times.txt'):
    # Regular expression pattern to capture the processing time and the timestamp
    time_pattern = re.compile(r'Time to process and save .*\.nc4:\s*([\d.]+)\s*seconds\. Current date/time:\s*(\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2})')

    # List to store extracted times and their corresponding timestamps
    processing_data = []

    # Time zone for the logs (assumed to be local time zone; adjust if needed)
    local_tz = pytz.timezone('America/New_York')

    # Initialize variables to keep track of the current file and orbit
    file_number = 1  # Since we are processing one file, the file number is static
    filename = os.path.basename(single_file_path)
    orbit_number = 0
    line_count = 0

    print(f"Processing file {file_number}: {filename}")
    
    with open(single_file_path, 'r') as file:
        for line in file:
            line_count += 1
            orbit_match = re.match(r'Working on orbit #(\d+)', line)
            if orbit_match:
                orbit_number = int(orbit_match.group(1))
            
            time_match = time_pattern.search(line)
            if time_match:
                # Extract the processing time and the date/time string
                processing_time = float(time_match.group(1))
                date_time_str = time_match.group(2)

                # Convert the date/time string to a Unix timestamp in local time
                dt = datetime.strptime(date_time_str, '%d-%b-%Y %H:%M:%S')
                dt_local = local_tz.localize(dt)
                dt_utc = dt_local.astimezone(pytz.utc)
                unix_timestamp = calendar.timegm(dt_utc.timetuple())

                # Debug: Print the original and converted timestamps for verification
                print(f"Original time: {date_time_str}, Local time: {dt_local}, UTC time: {dt_utc}, Unix timestamp: {unix_timestamp}")

                # Add the data to the list
                processing_data.append((file_number, orbit_number, unix_timestamp, processing_time))
        
        # Debug: Print the number of lines processed for the file
        print(f"Processed {line_count} lines in file {file_number}: {filename}")

    # Write the extracted times to the data output file
    with open(data_output_filename, 'w') as data_output_file:
        for data in processing_data:
            data_output_file.write('{} {} {} {}\n'.format(*data))

    print("Processing times and timestamps extracted and saved to:", data_output_filename)

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='Extract processing times and timestamps from a single log file.')
    parser.add_argument('-f', '--file', required=True, help='Single log file to process')
    parser.add_argument('-o', '--data_output', default='processing_times.txt', help='Output file name to save processing times (default: processing_times.txt)')
    args = parser.parse_args()

    # Call the function with the parsed arguments
    extract_processing_times(args.file, args.data_output)
