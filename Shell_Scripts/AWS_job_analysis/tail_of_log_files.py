import os

# Directory to search for files
directory = '/mnt/uri-nfs-cornillon/Logs/'  # Replace with the path to your directory
summary_file = 'tail_of_log_files.txt'

# Open the summary file for writing
with open(summary_file, 'w') as summary:
    # Traverse through all files in the directory
    for filename in os.listdir(directory):
        # Check if file starts with "08" and ends with ".txt"
        if filename.startswith('08') and filename.endswith('.txt'):
            filepath = os.path.join(directory, filename)
            # Read the last 20 lines of the file
            try:
                with open(filepath, 'r') as file:
                    lines = file.readlines()
                    last_lines = lines[-20:] if len(lines) >= 20 else lines
                
                # Write formatted output to summary file
                summary.write('\n\n********** {0} **********\n\n'.format(filename))
                summary.write(''.join(last_lines) + '\n')
            
            except Exception as e:
                # Handle any exceptions encountered while reading/writing files
                error_message = 'Error processing file {0}: {1}\n'.format(filename, str(e))
                summary.write(error_message)
                # Optionally, log the error to the console or another file for review
                
print("Summary file created:", summary_file)