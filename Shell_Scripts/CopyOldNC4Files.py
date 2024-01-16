import os
import shutil
import time
import re
import sys
import subprocess
from datetime import datetime

base_input_folder = '/Users/petercornillon/Data/temp_MODIS_L2_output_directory/output/SST/'
base_output_folder = '/Volumes/MODIS_L2_Modified/OBPG/SST/'

def setup_logging(log_folder):
    # Ensure the log folder exists
    os.makedirs(log_folder, exist_ok=True)

    # Generate a timestamp for the filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file_name = f"copy_nc4_{timestamp}.txt"
    log_file_path = os.path.join(log_folder, log_file_name)
    print(f"Diary will be writte to: {log_file_path}")

    # Redirect stdout to the log file
    log_file = open(log_file_path, 'a')
    print(f"Got to 1: {log_file}")
    sys.stdout = log_file
    print(f"Got to 2")

    return log_file

def get_year_month_from_filename(filename):
    # print(f'In get_year_month_from_filename {filename}.')
    match = re.search(r'_\d{6}_(\d{4})(\d{2})\d{2}T', filename)
    # print(f'And after the regular expression search: {match}.')
    if match:
        return match.group(1), match.group(2)  # year, month
    return None, None

def rsync_copy_and_delete(src, dst):

    # Ensure the destination directory exists
    os.makedirs(dst, exist_ok=True)

    # Construct the full path of the destination file
    dst_file = os.path.join(dst, os.path.basename(src))

    # Form the rsync command
    command = ["rsync", "-av", src, dst_file]

    # Execute the rsync command
    result = subprocess.run(command, capture_output=True, text=True)

    # Get the current date and time
    now = datetime.now()

    # Format the date and time in a readable format
    formatted_now = now.strftime("%Y-%m-%d %H:%M:%S")

     # Check if the rsync command was successful
    if result.returncode == 0:
        print(f"rsync successful for: {src}")
        # Delete the original file
        os.remove(src)
        print(f"Deleted original file: {src} at {formatted_now}.")
    else:
        print(f"rsync failed for: {src}. Error: {result.stderr} at {formatted_now}.")

def copy_files(test_mode=False):
    # Set up logging
    # log_folder_path = os.path.join(base_output_folder, "Logs")    
    # log_file = setup_logging(log_folder_path)
    # print(f'Returned from starting the output log file {log_file}.')

    start_time = time.time()

    while True:
        no_new_files = True
        # print(f'At location 0 {no_new_files}')
        for root, dirs, files in os.walk(base_input_folder):
            for filename in files:
                if filename.endswith('.nc4'):
                    # print(f'Got to location 3 {filename}.')
                    year, month = get_year_month_from_filename(filename)
                    # print(f'Got to location 4 {year} and {month}.')
                    if year and month:
                        # print(f'Got to location 5 {year} and {month}.')
                        specific_input_folder = os.path.join(base_input_folder, year, month)
                        specific_output_folder = os.path.join(base_output_folder, year, month)

                        file_path = os.path.join(root, filename)
                        file_creation_time = os.path.getctime(file_path)
                        if time.time() - file_creation_time > 4 * 60:
                            # print(f'Got to location 6 {filename}.')
                            if test_mode:
                                print(f'[TEST MODE] Would copy and delete: {filename} to {specific_output_folder}')
                                start_time = time.time()
                            else:
                                # os.makedirs(specific_output_folder, exist_ok=True)
                                # shutil.copy(file_path, specific_output_folder)
                                # print(f'Copied: {filename}')
                                rsync_copy_and_delete(file_path, specific_output_folder)
                                start_time = time.time()

                        else:
                            no_new_files = False

        if no_new_files and (time.time() - start_time) > 20 * 60:
            # Close the log file at the end of the script
            # log_file.close()
            break

        # Get the current date and time
        now = datetime.now()

        # Format the date and time in a readable format
        formatted_now = now.strftime("%Y-%m-%d %H:%M:%S")

        # Print the formatted date and time
        print(f'Pausing for 60 seconds at {formatted_now}.')
        time.sleep(60)

# Determine mode based on command line argument
test_mode = '--test' in sys.argv
copy_files(test_mode=test_mode)
