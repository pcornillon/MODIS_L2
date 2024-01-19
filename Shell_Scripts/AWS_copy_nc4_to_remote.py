import os
import shutil
import time
import re
import sys
import subprocess
from datetime import datetime

# base_input_folder = '/Users/petercornillon/Data/temp_MODIS_L2_output_directory/output/SST/'
# base_output_folder = '/Volumes/MODIS_L2_Modified/OBPG/'

base_input_folder = '/home/ubuntu/Documents/Aqua/output/SST/'
base_output_folder = '/mnt/uri-nfs-cornillon/'

class DualLogger:
    def __init__(self, log_file_path):
        self.terminal = sys.stdout
        self.log = open(log_file_path, "a")

    def write(self, message):
        self.terminal.write(message)
        self.log.write(message)

    def flush(self):
        # This flush method is needed for python 3 compatibility.
        # This handles the flush command by doing nothing.
        # You might want to specify some extra behavior here.
        pass

def setup_logging(log_folder, dual_out):
    # Ensure the log folder exists
    os.makedirs(log_folder, exist_ok=True)

    # Generate a timestamp for the filename. Start by getting the current date and time
    now = datetime.now()

    timestamp = now.strftime("%Y%m%d_%H%M%S")
    
    #log_file_name = f"copy_nc4_{timestamp}.txt"
    log_file_name = "copy_nc4_%s.txt" % timestamp
    log_file_path = os.path.join(log_folder, log_file_name)

    # Format the date and time in a readable format
    formatted_now = now.strftime("%Y-%m-%d %H:%M:%S")
    # print(f"Diary will be written to: {log_file_path} starting at: {formatted_now}")
    print( "Diary will be written to: %s starting at: %s" % (log_file_path, formatted_now))

    # Redirect stdout to the log file
    log_file = open(log_file_path, 'a')
    
    if dual_out:
        sys.stdout = DualLogger(log_file_path)
        return sys.stdout.log
    else:
        sys.stdout = log_file
        return log_file
    
def get_year_month_from_filename(filename):
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
        # print(f"rsync successful for: {src}")
        print("rsync successful for: %s" %src)
        # Delete the original file
        os.remove(src)
        # print(f"Deleted original file: {src} at {formatted_now}.")
        print( "Deleted original file: %s at %s." %(src, formatted_now))
    else:
        # print(f"rsync failed for: {src}. Error: {result.stderr} at {formatted_now}.")
        print( "rsync failed for: %s. Error: %s at %s." %(src, result.stderr, formatted_now))

def copy_files(test_mode=False):
    # Intialize run parameters
    dual_out = 1
    print_debug = 0;

    # Minutes to sleep before searching, to pause between new search, to terminate the run if no new files found and since file was created before copying.
    initial_sleep = 15;
    pause_time = 1;
    kill_time = 8;
    time_since_creation = 4;
    
    # Set up logging
    log_folder_path = os.path.join(base_output_folder, "Logs")    
    log_file = setup_logging(log_folder_path, dual_out)
    if print_debug:
        print( "Returned from starting the output log file %s." %log_file)
    
    # Sleep for initial_sleep minutes to give the jobs time to process the first orbit.
    time.sleep(initial_sleep * 60)
    
    start_time = time.time()

    while True:
        no_new_files = True
        for root, dirs, files in os.walk(base_input_folder):
            if print_debug:
                # print(f'Made it to checkpoint #1. Root: {root}, Dirs: {dirs}, Files: {files}.')
                print( "Made it to checkpoint #1. Root: %s, Dirs: %s, Files: %s." %(root, dirs, files))
            for filename in files:
                if print_debug:
                    # print(f'Made it to checkpoint #2. Filename: {filename}.')
                    print( "Made it to checkpoint #2. Filename: %s." %filename)
                if filename.endswith('.nc4'):
                    if print_debug:
                        # print(f'Made it to checkpoint #3')
                        print( "Made it to checkpoint #3")
                    year, month = get_year_month_from_filename(filename)
                    if year and month:
                        if print_debug:
                            # print(f'Made it to checkpoint #4')
                            print( "Made it to checkpoint #4")
                        specific_input_folder = os.path.join(base_input_folder, year, month)
                        specific_output_folder = os.path.join(base_output_folder, "SST", year, month)

                        file_path = os.path.join(root, filename)
                        file_creation_time = os.path.getctime(file_path)

                        if print_debug:
                            # print(f'specific_ input_folder: {specific_input_folder}, output_folder: {specific_output_folder}, file_path: {file_path}, file_creation_time: {file_creation_time} and time.time: {time.time()}')
                            print( "specific_ input_folder: %s, output_folder: %s, file_path: %s, file_creation_time: %s and time.time: %s" %(specific_input_folder, specific_output_folder, file_path, file_creation_time, time.time())

                            tempb = time_since_creation * 60
                            # tempa = time.time() - file_creation_time
                            tempa = time.time()
                            if tempa > tempb:
                            if print_debug:
                                # print(f'Made it to checkpoint #5')
                                print(f'Made it to checkpoint #5')
                            if test_mode:
                                # print(f'[TEST MODE] Would copy and delete: {filename} to {specific_output_folder}')
                                print( "[TEST MODE] Would copy and delete: %s to %s." %(filename, specific_output_folder))
                                start_time = time.time()
                            else:
                                if print_debug:
                                    # print(f'Made it to checkpoint #6')
                                    print( "Made it to checkpoint #6")
                                rsync_copy_and_delete(file_path, specific_output_folder)
                                start_time = time.time()

                        else:
                            if print_debug:
                                # print(f'Made it to checkpoint #7')
                                print( "Made it to checkpoint #7")
                            no_new_files = False

        if no_new_files and (time.time() - start_time) > kill_time * 60:
            # Close the log file at the end of the script
            if dual_out:
                sys.stdout.log.close()
            else:
                log_file.close()
                    
            break

        # Get the current date and time
        now = datetime.now()

        # Format the date and time in a readable format
        formatted_now = now.strftime("%Y-%m-%d %H:%M:%S")

        # Print the formatted date and time
        # print(f'Pausing for {pause_time * 60} seconds at {formatted_now}.')
        print( "Pausing for %i seconds at %s." %(pause_time*60, formatted_now))
        time.sleep(pause_time * 60)

# Determine mode based on command line argument
test_mode = '--test' in sys.argv
copy_files(test_mode=test_mode)
