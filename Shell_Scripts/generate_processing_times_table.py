import re
import os
import argparse
from datetime import datetime
import calendar
import pytz

def extract_processing_times(directory, data_output_filename='processing_times.txt', index_output_filename='file_index.txt'):
    time_pattern = re.compile(r'Time to process and save .*\.nc4:\s*([\d.]+)\s*seconds\. Current date/time:\s*(\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2})')
    local_tz = pytz.timezone('America/New_York')
    processing_data = []
    file_index = []
    file_number = 0

    log_files = [f for f in os.listdir(directory) if f.endswith('.txt') and 'May' in f]

    for log_file in log_files:
        file_number += 1
        file_index.append((file_number, log_file))
        orbit_number = 0
        line_count = 0

        file_path = os.path.join(directory, log_file)
        print("Processing file {}: {}".format(file_number, log_file))

        with open(file_path, 'r') as file:
            for line in file:
                line_count += 1
                orbit_match = re.match(r'Working on orbit #(\d+)', line)
                if orbit_match:
                    orbit_number = int(orbit_match.group(1))
                
                time_match = time_pattern.search(line)
                if time_match:
                    processing_time = float(time_match.group(1))
                    date_time_str = time_match.group(2)

                    dt = datetime.strptime(date_time_str, '%d-%b-%Y %H:%M:%S')
                    dt_local = local_tz.localize(dt)
                    dt_utc = dt_local.astimezone(pytz.utc)
                    unix_timestamp = calendar.timegm(dt_utc.timetuple())

                    print("Original time: {}, Local time: {}, UTC time: {}, Unix timestamp: {}".format(date_time_str, dt_local, dt_utc, unix_timestamp))

                    processing_data.append((file_number, orbit_number, unix_timestamp, processing_time))

            print("Processed {} lines in file {}: {}".format(line_count, file_number, log_file))

    with open(data_output_filename, 'w') as data_output_file:
        for data in processing_data:
            data_output_file.write('{} {} {} {}\n'.format(*data))

    with open(index_output_filename, 'w') as index_output_file:
        for index in file_index:
            index_output_file.write('{} {}\n'.format(*index))

    print("Processing times extracted and saved to:", data_output_filename)
    print("File index saved to:", index_output_filename)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Extract processing times and timestamps from log files in a directory.')
    parser.add_argument('-d', '--directory', required=True, help='Directory containing log files')
    parser.add_argument('-o', '--data_output', default='processing_times.txt', help='Output file name to save processing times (default: processing_times.txt)')
    parser.add_argument('-i', '--index_output', default='file_index.txt', help='Output file name to save file indices (default: file_index.txt)')
    args = parser.parse_args()

    extract_processing_times(args.directory, args.data_output, args.index_output)
