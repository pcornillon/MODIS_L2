# get_granule_list - gets the list of all OBPG metadata granules - PCC

import os
import re
import time
from datetime import datetime

# Base directory to search for files
base_dir = '/Volumes/MODIS_L2_Original/OBPG/Combined/'

# Regular expression to match the filenames
filename_pattern = re.compile(r'AQUA_MODIS\.(\d{8}T\d{6})\.L2\.SST\.nc')

def parse_datetime_string(dt_str):
    # Convert the datetime string to a datetime object
    dt_format = "%Y%m%dT%H%M%S"
    dt_obj = datetime.strptime(dt_str, dt_format)
    # Get the number of seconds since 1/1/1970 00:00
    seconds_since_epoch = int(time.mktime(dt_obj.timetuple()))
    return seconds_since_epoch

def find_files_and_parse(base_dir):
    output = []
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            match = filename_pattern.match(file)
            if match:
                dt_str = match.group(1)
                seconds_since_epoch = parse_datetime_string(dt_str)
                full_path = os.path.join(root, file)
                output.append((full_path, seconds_since_epoch))
    return output

if __name__ == "__main__":
    result = find_files_and_parse(base_dir)
    for file_path, seconds in result:
        print(f"File: {file_path}, Seconds since epoch: {seconds}")