import os

def get_last_file_in_folders(base_path, year):
    last_files = {}
    full_path = os.path.join(base_path, str(year))
    
    # Traverse the directory structure
    for root, dirs, files in os.walk(full_path):
        if files:
            # Sort files by modification time
            files.sort(key=lambda f: os.path.getmtime(os.path.join(root, f)))
            # Get the last file
            last_file = files[-1]
            last_files[root] = last_file
    return last_files

# Base path to the folders
base_path = '/mnt/uri-nfs-cornillon/SST/'

# Year to be passed in
year = 2011

# Get the last file in each folder for the specified year
last_files = get_last_file_in_folders(base_path, year)

# Print the results
for folder, file in last_files.items():
    print("Folder: {}, Last file: {}".format(folder, file))
