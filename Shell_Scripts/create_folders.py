import os

def create_folders():
    base_directory = "/home/ubuntu/temp"

    # Create folders for each year
    for year in range(2000, 2024):
        year_folder = os.path.join(base_directory, str(year))
        os.makedirs(year_folder)

        # Create subfolders for each month within the year
        for month in range(1, 13):
            month_folder = os.path.join(year_folder, '{:02d}'.format(month))
            os.makedirs(month_folder)

    print("Folders created successfully!")

if __name__ == "__main__":
    create_folders()
