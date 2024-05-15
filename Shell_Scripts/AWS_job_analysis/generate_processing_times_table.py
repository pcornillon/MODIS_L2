import os
import argparse
import time
import glob

# Argument parser
parser = argparse.ArgumentParser(description='Process log files and generate processing times.')
parser.add_argument('-d', '--directory', type=str, required=True, help='The directory containing log files.')
parser.add_argument('-n', '--number', type=int, required=True, help='The batch number for the output files.')

args = parser.parse_args()

# Input directory and batch number
input_directory = args.directory
batch_number = args.number

# Output file paths
file_index_output_path = os.path.join(input_directory, f'Batch-{batch_number}_file_index.txt')
processing_times_output_path = os.path.join(input_directory, f'Batch-{batch_number}_processing_times.txt')

# Function to process log files and generate processing times
def process_log_files(directory):
    log_files = glob.glob(os.path.join(directory, '*.log'))
    file_index = []
    processing_times = []

    for log_file in log_files:
        start_time = time.time()
        # Simulate log file processing (replace with actual processing code)
        with open(log_file, 'r') as f:
            content = f.read()
        end_time = time.time()

        processing_time = end_time - start_time
        file_index.append(log_file)
        processing_times.append((log_file, processing_time))

    return file_index, processing_times

# Process log files
file_index, processing_times = process_log_files(input_directory)

# Write file index to output file
with open(file_index_output_path, 'w') as f:
    for file in file_index:
        f.write(f"{file}\n")

# Write processing times to output file
with open(processing_times_output_path, 'w') as f:
    for file, processing_time in processing_times:
        f.write(f"{file}: {processing_time} seconds\n")

print(f"File index written to: {file_index_output_path}")
print(f"Processing times written to: {processing_times_output_path}")

# Example call for Batch-5 processing: python generate_processing_times_table.py -d /mnt/uri-nfs-cornillon/Logs/ -n 5