import re
import argparse

def extract_processing_times(input_filename, output_filename='processing_times.txt'):
    # Regex pattern to match the required lines and extract the time
    time_pattern = re.compile(r'Time to process and save .*\.nc4: ([\d.]+) seconds')

    # List to store extracted times
    processing_times = []

    # Read the input file and extract times
    with open(input_filename, 'r') as file:
        for line in file:
            # Debug: Print each line being processed
            print("Processing line:", line.strip())
            time_match = time_pattern.search(line)
            if time_match:
                processing_time = float(time_match.group(1))
                # Debug: Print the extracted time
                print("Extracted time:", processing_time)
                processing_times.append(processing_time)

    # Write the extracted times to the output file
    with open(output_filename, 'w') as output_file:
        for time in processing_times:
            output_file.write('{}\n'.format(time))

    print("Processing times extracted and saved to:", output_filename)

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='Extract processing times from a log file.')
    parser.add_argument('input_filename', help='Input text file name containing log data')
    parser.add_argument('-o', '--output', default='processing_times.txt', help='Output file name to save processing times (default: processing_times.txt)')
    args = parser.parse_args()

    # Call the function with the parsed arguments
    extract_processing_times(args.input_filename, args.output)
