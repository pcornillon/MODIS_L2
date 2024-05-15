import os

def find_last_orbit_line(directory):
    # List to store results
    results = []
    
    # Check all files in the specified directory
    for filename in os.listdir(directory):
        filepath = os.path.join(directory, filename)
        if os.path.isfile(filepath):
            last_orbit_line = None
            with open(filepath, 'r') as file:
                for line in file:
                    if line.startswith('Working on orbit #'):
                        last_orbit_line = line.strip()
            if last_orbit_line:
                results.append('{}: {}'.format(filename, last_orbit_line))
    
    return results

# Directory containing the files
directory_path = '/mnt/uri-nfs-cornillon/Logs/'

# Call the function and print results
orbit_lines = find_last_orbit_line(directory_path)
for line in orbit_lines:
    print(line)