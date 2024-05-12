import re
import os
import argparse
from datetime import datetime
import calendar
import pytz

def extract_processing_times(directory, data_output_filename='processing_times.txt', index_output_filename='file_index.txt'):
    # Improved regex pattern to capture the processing time and the timestamp at the end of the line
    time_pattern = re.compile(r'Time to process and save .*\.nc4:\s*([\d.]+)\s*seconds\. Current date/time:\s*(\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2})')

    # List to store extracted times and their corresponding timestamps
    processing_data = []
    file_index = []

    # Time zone for the logs (assumed to be local time zone; adjust if needed)
    local_tz = pytz.timezone('America/New_York')

    # Step through all files in the directory matching the pattern
    files = [f for f in os.listdir(directory) if re.match(r'.*May.*\.txt$', f)]
    
    for file_number, filename in enumerate(files, start=1):
        filepath = os.path.join(directory, filename)
        file_index.append((file_number, filename))
        
        with open(filepath, 'r') as file:
            orbit_number = 0
            for line in file:
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
                    print("Original time: {0}, Local time: {1}, UTC time: {2}, Unix timestamp: {3}".format(
                        date_time_str, dt_local, dt_utc, unix_timestamp))

                    # Add the data to the list
                    processing_data.append((file_number, orbit_number, unix_timestamp, processing_time))

    # Write the extracted times to the data output file
    with open(data_output_filename, 'w') as data_output_file:
        for data in processing_data:
            data_output_file.write('{} {} {} {}\n'.format(*data))

    print("Processing times and timestamps extracted and saved to:", data_output_filename)

    # Write the file index to the index output file
    with open(index_output_filename, 'w') as index_output_file:
        for index in file_index:
            index_output_file.write('{} {}\n'.format(*index))

    print("File index saved to:", index_output_filename)

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='Extract processing times and timestamps from log files.')
    parser.add_argument('-d', '--directory', default='/mnt/uri-nfs-cornillon/Logs/', help='Directory containing log files (default: /mnt/uri-nfs-cornillon/Logs/)')
    parser.add_argument('-o', '--data_output', default='processing_times.txt', help='Output file name to save processing times (default: processing_times.txt)')
    parser.add_argument('-i', '--index_output', default='file_index.txt', help='Output file name to save file index (default: file_index.txt)')
    args = parser.parse_args()

    # Call the function with the parsed arguments
    extract_processing_times(args.directory, args.data_output, args.index_output)
