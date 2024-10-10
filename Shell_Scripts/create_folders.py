import os
import argparse

# This script will creat year/month folders in base_directory, which is 
# passed in as the 1st argument. The 2nd and 3rd argumens correspond to the
# first year to add and the 3rd to the last year. If the year folder already
# exists the script will not create it or the month folders under it. Here's 
# a sample (it will create the base directory if not already defined):
#
# pytho create_folders.py /Volumes/MODIS_L2_Modified/TERRA/sst_orbits
#

def create_folders(base_directory, first_year, last_year):
    # Check if base directory exists, and create it if not
    if not os.path.exists(base_directory):
        os.makedirs(base_directory)
        print(f"Base directory '{base_directory}' created.")

    # Create folders for each year
    for year in range(first_year, last_year + 1):
        year_folder = os.path.join(base_directory, str(year))

        # Only create year folder if it doesn't exist
        if not os.path.exists(year_folder):
            os.makedirs(year_folder)
            print(f"Year folder '{year_folder}' created.")

            # Create subfolders for each month within the year
            for month in range(1, 13):
                month_folder = os.path.join(year_folder, '{:02d}'.format(month))
                os.makedirs(month_folder, exist_ok=True)
        else:
            print(f"Year folder '{year_folder}' already exists. Skipping year and month creation...")

    print("Folders created successfully!")

if __name__ == "__main__":
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Create folder structure for SST data.")
    
    # Define the arguments
    parser.add_argument("base_directory", help="Base directory where folders will be created.", nargs='?', default="/datadisk/SST/")
    parser.add_argument("first_year", help="First year for which folders will be created.", type=int, nargs='?', default=2002)
    parser.add_argument("last_year", help="Last year for which folders will be created.", type=int, nargs='?', default=2023)

    # Parse arguments
    args = parser.parse_args()

    # Call the function with the provided arguments
    create_folders(args.base_directory, args.first_year, args.last_year)