import re
import argparse
from datetime import datetime
import time

def extract_processing_times(input_filename, output_filename='processing_times.txt'):
    # Improved regex pattern to capture the processing time and the timestamp at the end of the line
    time_pattern = re.compile(r'Time to process and save .*\.nc4:\s*([\d.]+)\s*seconds\. Current date/time:\s*(\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2})')

    # List to store extracted times and their corresponding timestamps
    processing_times = []

    # Read the input file and extract times
    with open(input_filename, 'r') as file:
        for line in file:
            time_match = time_pattern.search(line)
            if time_match:
                # Extract the processing time and the date/time string
                processing_time = float(time_match.group(1))
                date_time_str = time_match.group(2)

                # Convert the date/time string to a Unix timestamp
                dt = datetime.strptime(date_time_str, '%d-%b-%Y %H:%M:%S')
                unix_timestamp = int(time.mktime(dt.timetuple()))

                # Add the processing time and timestamp to the list
                processing_times.append((processing_time, unix_timestamp))

    # Write the extracted times to the output file
    with open(output_filename, 'w') as output_file:
        for time_val, timestamp in processing_times:
            output_file.write('{} {}\n'.format(time_val, timestamp))

    print("Processing times and timestamps extracted and saved to:", output_filename)

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='Extract processing times and timestamps from a log file.')
    parser.add_argument('input_filename', help='Input text file name containing log data')
    parser.add_argument('-o', '--output', default='processing_times.txt', help='Output file name to save processing times (default: processing_times.txt)')
    args = parser.parse_args()

    # Call the function with the parsed arguments
    extract_processing_times(args.input_filename, args.output)
