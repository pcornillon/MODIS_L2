import os
import re

# Directory to search for files
directory = '/mnt/uri-nfs-cornillon/Logs/'  # Replace with the path to your directory
output_file = 'orbit_processing_times.csv'

# Regex patterns to match the required lines
orbit_pattern = re.compile(r'Working on orbit #(\d+)')
time_pattern = re.compile(r'Time to process and save .*\.nc4: ([\d.]+) seconds')

# Dictionary to store orbit processing times
orbit_times = {}

# Traverse through all files in the directory
for filename in os.listdir(directory):
    if filename.startswith('08') and filename.endswith('.txt'):
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r') as file:
            orbit_number = None
            for line in file:
                # Check for the 'Working on orbit #' line
                orbit_match = orbit_pattern.search(line)
                if orbit_match:
                    orbit_number = int(orbit_match.group(1))
                
                # Check for the 'Time to process and save' line
                time_match = time_pattern.search(line)
                if time_match and orbit_number is not None:
                    time_to_process = float(time_match.group(1))
                    if orbit_number not in orbit_times:
                        orbit_times[orbit_number] = []
                    orbit_times[orbit_number].append(time_to_process)
                    orbit_number = None  # Reset orbit_number for the next match

# Write the results to the output CSV file
with open(output_file, 'w') as out:
    out.write('Orbit Number,Time to Process (seconds)\n')
    for orbit, times in sorted(orbit_times.items()):
        for time in times:
            out.write(f'{orbit},{time}\n')

print("Output file created:", output_file)