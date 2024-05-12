import argparse
import os
import pytz
from datetime import datetime
from collections import defaultdict

def extract_processing_times(directory, output_file, index_file):
    logs_data = defaultdict(list)
    log_files = [f for f in os.listdir(directory) if f.endswith(".txt") and "May" in f]
    log_files.sort()
    
    file_index = {}
    for idx, file in enumerate(log_files, start=1):
        file_index[file] = idx
        orbit_num = 0

        with open(os.path.join(directory, file), "r") as log:
            for line in log:
                if "Time to process and save" in line:
                    orbit_num += 1

                    # Extract the processing time and original date/time
                    processing_time_str = line.split(":")[-2].strip()
                    original_time_str = line.split("Current date/time:")[-1].strip()
                    
                    # Parse the date/time string and convert to Unix timestamp
                    dt = datetime.strptime(original_time_str, "%d-%b-%Y %H:%M:%S")
                    dt_utc = dt.replace(tzinfo=pytz.timezone("UTC"))
                    unix_timestamp = int((dt_utc - datetime(1970, 1, 1, tzinfo=pytz.UTC)).total_seconds())

                    # Append the results to the logs_data list
                    logs_data[idx].append((idx, orbit_num, unix_timestamp, float(processing_time_str)))

    # Write results to output file
    with open(output_file, "w") as out:
        for file_idx, data_list in logs_data.items():
            for data in data_list:
                out.write("%d %d %d %.1f\n" % (data[0], data[1], data[2], data[3]))

    # Write file index to index file
    with open(index_file, "w") as index_out:
        for file_name, idx in file_index.items():
            index_out.write("%d %s\n" % (idx, file_name))

# Argument parsing
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract processing times from log files.")
    parser.add_argument("-d", "--directory", required=True, help="Directory containing log files")
    parser.add_argument("-o", "--data_output", required=True, help="Output file for processing times data")
    parser.add_argument("-i", "--index_output", required=True, help="Output file for file index")
    args = parser.parse_args()

    extract_processing_times(args.directory, args.data_output, args.index_output)
