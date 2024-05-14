import os
import re

# Define the regular expression pattern to search for blocks of text
pattern = re.compile(r"""
    \*{64}\n     # Start with a line of 64 asterisks
    (            # Start of capture group for the block
    (\*.*\n)+    # One or more lines starting with an asterisk
    )
    \*{64}\n     # End with a line of 64 asterisks
    """, re.VERBOSE)

# Function to search for the block in a file
def search_file(file_path):
    with open(file_path, 'r') as file:
        content = file.read()
        matches = pattern.findall(content)
        if matches:
            print("Found in file: {}".format(file_path))
            for match in matches:
                print(match[0])

# Function to walk through directories and search files
def search_files_in_directory(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            try:
                search_file(file_path)
            except Exception as e:
                print("Error reading file {}: {}".format(file_path, e))

# Define the directory to search
directory_to_search = '/mnt/uri-nfs-cornillon/Logs/'

# Perform the search
search_files_in_directory(directory_to_search)
