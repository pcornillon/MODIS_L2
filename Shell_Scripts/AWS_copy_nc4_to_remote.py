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
    try:
        os.makedirs(log_folder)
    except OSError as e:
        if e.errno != os.errno.EEXIST:
            raise  # Re-raises the error if it's not the "Directory exists" error

    # Generate a timestamp for the filename. Start by getting the current date and time
    now = datetime.now()

    timestamp = now.strftime("%Y%m%d_%H%M%S")
    
    log_file_name = "copy_nc4_%s.txt" % timestamp
    log_file_path = os.path.join(log_folder, log_file_name)

    # Format the date and time in a readable format
    formatted_now = now.strftime("%Y-%m-%d %H:%M:%S")
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
    if match:
        return match.group(1), match.group(2)  # year, month
    return None, None

def rsync_copy_and_delete(src, dst):

    # Ensure the destination directory exists
    try:
        os.makedirs(dst)
    except OSError as e:
        if e.errno != os.errno.EEXIST:
            raise  # Re-raises the error if it's not the "Directory exists" error

    # Construct the full path of the destination file
    dst_file = os.path.join(dst, os.path.basename(src))

    # Form the rsync command
    command = ["rsync", "-av", src, dst_file]
    
    # Execute the rsync command
    result = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = result.communicate()

    if result.returncode != 0:
        print("Error executing rsync:", error)
    else:
        print("rsync output:", output)

    # Get the current date and time
    now = datetime.now()

    # Format the date and time in a readable format
    formatted_now = now.strftime("%Y-%m-%d %H:%M:%S")

     # Check if the rsync command was successful
    if result.returncode == 0:
        print("rsync successful for: %s" %src)

        # Delete the original file
        os.remove(src)
        print( "Deleted original file: %s at %s." %(src, formatted_now))
    else:
        print( "rsync failed for: %s. Error: %s at %s." %(src, result.stderr, formatted_now))

def copy_files(test_mode=False):
    # Intialize run parameters
    dual_out = 1

    # Minutes to pause between new search and time since file was created before copying.
    pause_time = 1
    time_since_creation = 4
    
    # Initially set kill_time, the time to terminate this script since the last .nc4 file was found (if any) to 30 minutes.
    # This is more than needed but avoids this script stopping before the first orbit has been processed.
    # kill_time will be reset to 12 minutes after the first orbit has been copied. This is hopefully longer than the time to process an orbit. 
    kill_time = 30
    reset_kill_time = 12
    
    # Set up logging
    log_folder_path = os.path.join(base_output_folder, "Logs/copy_AWS_to_mnt-uri_logs")    
    log_file = setup_logging(log_folder_path, dual_out)
    
    # Sleep for initial_sleep minutes to give the jobs time to process the first orbit.
    # time.sleep(initial_sleep * 60) -- removed this because of the way the kill times are set, initially 30 minutes and then 8. The starting kill_time, 30 minutes, takes care of the initial sleep period. 
    
    start_time = time.time()

    while True:
        no_new_files = True

        for root, dirs, files in os.walk(base_input_folder):

            for filename in files:

                if filename.endswith('.nc4'):
                    year, month = get_year_month_from_filename(filename)

                    if year and month:
                        specific_input_folder = os.path.join(base_input_folder, year, month)
                        specific_output_folder = os.path.join(base_output_folder, "SST", year, month)

                        file_path = os.path.join(root, filename)
                        file_creation_time = os.path.getctime(file_path)

                        if (time.time() - file_creation_time) > (time_since_creation * 60):
                            if test_mode:
                                print( "[TEST MODE] Would copy and delete: %s to %s." %(filename, specific_output_folder))
                                start_time = time.time()
                            else:
                                rsync_copy_and_delete(file_path, specific_output_folder)
                                start_time = time.time()

                                # Reset the kill time to 7 minutes--if no files created in 7 minutes it is likely that the matlab jobs have ended.
                                kill_time = reset_kill_time


                        else:
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
        print( "Pausing for %i seconds at %s." %(pause_time*60, formatted_now))
        time.sleep(pause_time * 60)

# Determine mode based on command line argument
test_mode = '--test' in sys.argv
copy_files(test_mode=test_mode)
