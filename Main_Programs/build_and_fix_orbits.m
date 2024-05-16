function build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, regrid_to_AMSRE, get_gradients, save_core, print_diag, save_orbits, base_diary_filename)
% build_and_fix_orbits - read in all granules for each orbit in the time range and fix the mask and bowtie - PCC
%
% This function will read all of the
%
% INPUT
%   start_date_time - build orbits with the first orbit to be built
%    including this time specified as: [YYYY, MM, DD, HH, Min, 00].
%   end_date_time - last orbit to be built includes this time.
%   fix_mask - if 1 fixes the mask. If absent, will set to 1.
%   fix_bowtie - if 1 fixes lzthe bow-tie problem, otherwise bow-tie effect
%    not fixed.
%   regrid_sst - 1 to regrid SST after bowtie effect has been addressed.
%   regrid_to_AMSRE - if 1 will read the corresponding AMSR-E orbit and
%    regrid to AMSR-E native AMSR-E and regrid both AMSR-E and MODIS to a
%    geogrid. In all cases will use regridded MODIS data.
%   get_gradients - 1 to calculate eastward and northward gradients, 0
%    otherwise.
%   save_core - 1 to save only the core values, regridded lon, lat, SST,
%    refined mask and nadir info, 0 otherwise.
%   print_diagnostics - 1 to print timing diagnostics, 0 otherwise.
%   save_orbits - 1 to write netCDF file for each orbit, 0 to skip saving.
%   base_diary_filename - the name for the output log files.
%
% OUTPUT
%   none
%
% IMPORTANT VARIABLES.
%
%   orbit_into - structure with information about each orbit.
%   problem_list - structure with list of filenames for skipped file and
%    the reason for it being skipped (same codes as status):
%    problem_code: 0 - OK
%                : 1 - couldn't find the data granule.
%                : 2 - didn't find number_of_lines global attribute.
%                : 3 - number of pixels global attribute not equal to 1354.
%                : 4 - number of scan lines global attribute not between 2020 and 2050.
%                : 5 - couldn't find the metadata file copied from OBPG data.
%                : 6 - 1st detector in data granule not 1st detector in group of 10.
%                : 10 - missing granule.
%                : 11 - more than 2 metadata files for a given time.
%                : 100 - No granule with the start of an orbit found in time range.
%
% EXAMPLE
%
% First, some variables that need to be defined. These will be defined as
% global variables prior to calling this function.
%
%   granules_directory - the base directory for the input files.
%   metadata_directory - the base directory for the location of the
%    metadata files copied from the OBPG files.
%   fixit_directory - the directory for files required by this script to
%    correct the cloud mask and the bow-tie effect.
%   output_file_directory_local - the base directory for the output files.
%    Note that this must be the full directory name, netCDF doesn't like ~/.
%
% Build orbits for 25 February through to 1 April  2010 and fix the bow-tie
% but nothing else.
%
%   global granules_directory metadata_directory fixit_directory logs_directory output_file_directory_local output_file_directory_remote oinfo problem_list
%   granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';
%   metadata_directory = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
%   fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/';
%   logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';
%   output_file_directory_local = '/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/';
%
%   build_and_fix_orbits( [2010 2 25 0 0 0], [2010 4 1 0 0 0], 0, 1, 0, 1, 0, 1, 1);
%   build_and_fix_orbits( [2010 6 19 0 0 0], [2010 6 24 0 0 0], 1, 1, 1, 0, 1, 1, 1);
%
%  For test runs, the function will define the location of the various
%  directories as well as parameters needed for the run. Nothing is passed
%  into the function.
%
%  CHANGE LOG
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/6/2024 - Initial version - PCC
%   1.0.1 - 5/6/2024 - Added check for trailing slash on remote output
%           directory name - PCC
%   1.0.2 - 5/7/2024 - Fixed print out of version number and test for
%           empty output_file_directory_remote. Also added code to address
%           the problem of large number of missing granules. - PCC
%   1.0.3 - 5/7/2024 - Removed commented out code - PCC
%   1.0.4 - 5/8/2024 - Added text to  be written when job ends. Also will
%           save the oinfo file at that point. 
%           Also will exit if latitude is one element and nan. - PCC
%   1.0.5 - 5/9/2024 - Removed commented out code. - PCC
%   1.1.0 - 5/12/2024 - Test to see if failure to get NASA se credentials
%           end the run if this is the case with status=921. Also test
%           status for 921 for functions that may have called
%           loadAWSCredentials and end run. 
%   1.1.1 - 5/13/2024 - Modified code in regrid_MODIS_orbits to address
%           longitudes >360 or <-360 before call to ll2ps. Also addressed a
%           problem in fix_lon_steps_and_constrain. Added -URI_24-1 to the
%           end of the orbit filename for version URI_24-1. Removed some
%           commented out lines of code as well. Added build_and_fix_orbits
%           version number as a global attribute to the output file written
%           by Write_SST_File - PCC 
%   1.1.2 - 5/13/2024 - Fixed test for orbit already processed if
%           output_file_directory_remote exist in build_orbit. Was not
%           being done when a new orbit name was first found. Also changed
%           the valid range of longitudes in Write_SST_File from -360 to
%           360 to -720 to 720 - PCC
%   1.1.3 - 5/14/2024 - Very minor mods to build_orbit  - PCC
%   1.1.4 - 5/14/2024 - Problem with the check for longitude values outside
%           of -360 to 360 in fix_lon_steps... Hopefully fixed now - PCC
%   1.1.5 - 5/16/2024 - Removed 273.15 from NASA SST read in from AWS in
%           add_granule_data...

global version_struct
version_struct.build_and_fix_orbits = '1.1.5';

% Start with a clean state for globals with the exception of directories.
% This is necessary when running build_and_fix... from one of the
% process... batch submission programs but in the local mode since the
% program will run build_and_fix... for one time range and then again for
% another time range.

clear global mem_count mem_orbit_count mem_print print_dbStack mem_struct diary_filename ...
    determine_fn_size print_diagnostics print_times debug regridded_debug ...
    npixels save_just_the_facts amazon_s3_run formatOut secs_per_day ...
    secs_per_orbit secs_per_scan_line ...
    index_of_NASA_orbit_change possible_num_scan_lines_skip sltimes_avg ...
    nlat_orbit nlat_avg orbit_length latlim sst_range sst_range_grid_size ...
    oinfo iOrbit iGranule iProblem problem_list scan_line_times ...
    start_line_index num_scan_lines_in_granule nlat_t Matlab_start_time ...
    Matlab_end_time s3_expiration_time med_op secs_per_granule ...
    orbit_duration


% Control for memory stats

global mem_count mem_orbit_count mem_print print_dbStack mem_struct diary_filename

mem_count = 1;
mem_print = 0;
print_dbStack = 0;

global determine_fn_size

determine_fn_size = 1;

if determine_fn_size; get_job_and_var_mem; end

% globals for the run as a whole.

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory_local output_file_directory_remote AMSR_E_baseDir
global print_diagnostics print_times debug regridded_debug
global npixels

% globals for build_orbit part.

global save_just_the_facts amazon_s3_run
global formatOut
global secs_per_day secs_per_orbit secs_per_scan_line secs_per_granule orbit_duration
global index_of_NASA_orbit_change possible_num_scan_lines_skip
global sltimes_avg nlat_orbit nlat_avg orbit_length
global latlim
global sst_range sst_range_grid_size

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t
global Matlab_start_time Matlab_end_time

global s3_expiration_time

% globals used in the other major functions of build_and_fix_orbits.

global med_op
global pixStartm pixEndm pixStartp pixEndp

lofs_of_astericks = '****************************************************************';

% Open diary for this run.

rng('shuffle')  % This to make it start with a different random number.

diary_filename = [logs_directory base_diary_filename '.txt'];
diary(diary_filename)

fprintf('Processing from %s to %s.\n', datestr(start_date_time), datestr(end_date_time))

fprintf('\nVersion %s of build_and_fix_orbits.\n\n', version_struct.build_and_fix_orbits)

if determine_fn_size; get_job_and_var_mem; end

% Structure of oinfo
%
% oinfo.
%   name
%   start_time  -- This is the time of the first cscan on this orbit
%   end_time -- This is the time of the last scan on this orbit. Note, it
%    includes the 100 extra scan lines following the last ascending
%    crossing of latlim. This means that the start_time of the next orbit
%    should be 99 scan line times before this end_time: 100 scan line times
%    for the extra 100 scans minus one since the last scan before the
%    previous ascending crossing of latlim is one scan time before the
%    first scan on the next orbit.
%   orbit_number
%
% oinfo.ginfo.
%       metadata_name
%       data_name
%       NASA_orbit_number
%       start_time
%       end_time
%       metadata_global_attrib
%       scans_in_this_granule
%       osscan_diff - difference in # of scan lines for the location of the start of this granule in the orbit from two different ways of estimating it.
%       osscan
%       oescan
%       gsscan
%       gescan
%       pirate_osscan
%       pirate_oescan
%       pirate_gsscan
%       pirate_gescan

% Initial oinfo structure. Need to do this to be able to check for the
% existence of a field. Specifically, if the field has not been created and
% isempty is done on it, it will fail.

oinfo.name = [];
oinfo.start_time = [];
oinfo.end_time = [];
oinfo.orbit_number = [];

oinfo.ginfo.metadata_name = [];
oinfo.ginfo.data_name = [];
oinfo.ginfo.NASA_orbit_number = [];
oinfo.ginfo.start_time = [];
oinfo.ginfo.end_time = [];
oinfo.ginfo.metadata_global_attrib = [];
oinfo.ginfo.scans_in_this_granule = [];

oinfo.ginfo.osscan_diff = [];

oinfo.ginfo.osscan = [];
oinfo.ginfo.oescan = [];
oinfo.ginfo.gsscan = [];
oinfo.ginfo.gescan = [];

oinfo.ginfo.pirate_osscan = [];
oinfo.ginfo.pirate_oescan = [];
oinfo.ginfo.pirate_gsscan = [];
oinfo.ginfo.pirate_gescan = [];

% Initialize return variables.

regridded_debug = 0;  % To determine and write alternate SST fields based on griddata.

save_just_the_facts = 1;
if exist('save_core') ~= 0
    if save_core == 0
        save_just_the_facts = 0;
    end
end

print_times = 1;

print_diagnostics = 0;
if exist('print_diag') ~= 0
    if print_diag == 1
        print_diagnostics = 1;
    end
end

if exist('get_gradients') == 0
    get_gradients = 1;
    fprintf('\n\nWill calculate gradients for this run.\n')
end

if exist('fix_mask') == 0
    fix_mask = 1;
    fprintf('Will fix masks for this run.\n')
end

amazon_s3_run = 0;

if strcmp( granules_directory(1:2), 's3') == 1
    fprintf('\n%s\n', 'This is an Amazon S3 run; will read data from s3 storage.')
    amazon_s3_run = 1;

% % %     % Set the time to wait for credentials from AWS.
% % %     
% % %     setCredentialsTimeout( 20);

    % Get the credentials, will need them shortly.
    
    [status, s3Credentials] = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', 'eiMTJr6yeuD6');
    
    if status == 921
        return
    end
else
    fprintf('\n%s\n', 'This is not an Amazon S3 run; will read data from local disks.')
end

%% Initialize some variables.

npixels = 1354;

latlim = -79;

orbit_length = 40271;

secs_per_day = 86400;

orbit_duration = 99.1389 * 60;  % Time from ascending crossiong of 79 S to 100 pixels past the next ascending crossing.

% secs_per_scan_line is determined from the script scan_line_timing_info in Main_Programs

% secs_per_scan_line = 0.1477112; % From earlier work before scan_line_timing_info
secs_per_scan_line = 0.14772;

% secs_per_orbit = 5933.56;  % Was hardwired in from earlier but will calculate it now.
secs_per_orbit = secs_per_scan_line * (orbit_length - 100 - 1);

secs_per_granule = 299.8532;  % First guess. Will update after reading each granule. Old value 298.3760 assumes 2030 scan lines.

index_of_NASA_orbit_change = 9226; % Changed for ascending crossing of 79 S.

iProblem = 0;

% Formats used in building filenames.

formatOut.dd = 'dd';
formatOut.mm = 'mm';
formatOut.yyyy = 'yyyy';

formatOut.HH = 'HH';
formatOut.MM = 'MM';
formatOut.SS = 'SS';

formatOut.yyyymmdd = 'yyyymmdd';
formatOut.HHMMSS = 'HHMMSS';

formatOut.yyyymmddThhmmss = 'yyyymmddTHHMMSS';
formatOut.yyyymmddThhmm = 'yyyymmddTHHMM';
formatOut.yyyymmddThh = 'yyyymmddTHH';

formatOut.yyyymmddhhmmss = 'yyyymmddHHMMSS';
formatOut.yyyymmddhhmm = 'yyyymmddHHMM';
formatOut.yyyymmddhh = 'yyyymmddHH';

% Get the possible number of scan lines to skip. Must be either 0, or some
% combination of an integer multiple of 2030 and of 2040.

j = 0;
for aa=0:20
    for bb=0:20
        j = j + 1;
        possible_num_scan_lines_skip(1,j) = aa;
        possible_num_scan_lines_skip(2,j) = bb;
        possible_num_scan_lines_skip(3,j) = aa * 2030 + bb * 2040;
    end
end

%% Check input parameters to make sure they are OK.

acceptable_start_time = datenum(2002, 7, 1);
acceptable_end_time = datenum(2022, 12, 31);

if (length(start_date_time) ~= 6) | (length(end_date_time) ~= 6)
    fprintf('\n\n\n%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
    fprintf('*    Input start and end time vectors must be 6 elements long. start_date_time: %s to %s.\n*\n', num2str(start_date_time), num2str(end_date_time))
    fprintf('%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
    return
end

Matlab_start_time = datenum(start_date_time);
Matlab_end_time = datenum(end_date_time);

if (Matlab_start_time < acceptable_start_time) | (Matlab_start_time > acceptable_end_time)
    fprintf('\n\n\n%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
    fprintf('*    Specified start time %s not between %s and %s.\n*\n', datestr(Matlab_start_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
    fprintf('%s\n%s\n', lofs_of_astericks, lofs_of_astericks)    
    return
end

if (Matlab_end_time < acceptable_start_time) | (Matlab_end_time > acceptable_end_time)
    fprintf('\n\n\n%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
    fprintf('*    Specified end time %s not between %s and %s\n*\n', datestr(Matlab_start_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
    fprintf('%s\n%s\n', lofs_of_astericks, lofs_of_astericks)
    return
end

if strcmp(output_file_directory_local(1:2), '~/')
    fprintf('\n\n\n%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
    fprintf('*    The remote output base directory must be fully specified; cannot start with ~/. Won''t work with netCDF. You entered: %s.\n*\n', output_file_directory_local)
    fprintf('%s\n%s\n', lofs_of_astericks, lofs_of_astericks)
    return
end

if ~isempty(output_file_directory_remote)
    if strcmp(output_file_directory_remote(1:2), '~/')
        fprintf('\n\n\n%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
        fprintf('*    The remote output base directory must be fully specified; cannot start with ~/. Won''t work with netCDF. You entered: %s.\n*\n', output_file_directory_remote)
        fprintf('%s\n%s\n', lofs_of_astericks, lofs_of_astericks)
        return
    end
end

%% Initialize parameters

% med_op is the 2 element vector specifying the number of pixels to use in
% the median filtering operation. Usually it is [3 3] but for test work,
% set it to [1 1]; i.e., do not median filter.

med_op = [1 1];

% Get the range matrices to use for the reference temperature test.

sst_range_grid_size = 2;

load([fixit_directory 'SST_Range_for_Declouding.mat'])

sst_range = gridded_sst_range(1:90,1:180,:);

for i_range_image=1:12
    xx = squeeze(sst_range(:,:,i_range_image));
    nn = find(xx == -1);
    mask = logical(zeros(size(xx)));
    mask(nn) = 1;
    yy = inpaintCoherent( xx, mask);
    xx(nn) = yy(nn);
    sst_range(:,:,i_range_image) = xx;
end

% Load the element locations to use when calculating averages for the new L2eqa grid.

load([fixit_directory 'L2eqa_elements.mat'])

% Load the separations and angles used to calculate gradients.

if get_gradients
    gradient_filename = [fixit_directory 'abbreviated_Separation_and_Angle_Arrays.mat'];

    load(gradient_filename)
    cos_track_angle = cosd(track_angle);
    sin_track_angle = sind(track_angle);
    clear track_angle
end

%% Get the relative scan line start times and latitudes.

load([fixit_directory 'avg_scan_line_start_times.mat'])

%______________________________________________________________________________________________
%______________________________________________________________________________________________
%______________________________________________________________________________________________
%
% Here to process orbits.
%______________________________________________________________________________________________
%______________________________________________________________________________________________
%______________________________________________________________________________________________

if determine_fn_size; get_job_and_var_mem; end

tic_build_start = tic;

% Start by looking for the first granule after Matlab_start_time with a
% ascending nadir track crossing latlim, nominally 73 S.

iOrbit = 1;

search_start_time = Matlab_start_time;
[status, granule_start_time_guess] = get_start_of_first_full_orbit(search_start_time);

% Either no granules with a 79 crossing or coding problem.

if (status == 201) | (status == 231) | (status > 900)
    fprintf('\n\n\n%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
    fprintf('*    Problem building this orbit or end of run.\n*\n')
    fprintf('*    Processed %i orbits\n*\n', iOrbit)
    fprintf('*    Saving oinfo file to: %s\n*\n', strrep(diary_filename, '.txt', '.mat'))
    fprintf('*    Time for this run: %8.1f seconds or, in minutes, %5.1f or, in hours, %5.1f \n*\n', toc(tic_build_start), toc(tic_build_start)/60, toc(tic_build_start)/3600)
    fprintf('%s\n%s\n', lofs_of_astericks, lofs_of_astericks)

    save(strrep(diary_filename, '.txt', '.mat'), 'oinfo', 'mem_struct', 'problem_list', 'version_struct')

    return
end

%% Loop over the remainder of the time range processing all complete orbits that have not already been processed.

while granule_start_time_guess <= Matlab_end_time

    mem_count = mem_count + 1;

    %% Build the orbit

    % Make sure that we are at the start of an orbit. If the the last
    % granule of the previous orbit was missing, there would be no start
    % for this orbit so we need to search for the start of the next orbit.

    if length(oinfo) ~= iOrbit
        iGranule = 0;

        oinfo(iOrbit).start_time = oinfo(iOrbit-1).end_time + 1 * secs_per_scan_line / secs_per_day;
        oinfo(iOrbit).end_time = oinfo(iOrbit).start_time + secs_per_orbit / secs_per_day;
        oinfo(iOrbit).orbit_number = oinfo(iOrbit-1).orbit_number + 1;

        orbit_file_name = ['AQUA_MODIS_orbit_' return_a_string( 6, oinfo(iOrbit).orbit_number) ...
            '_' datestr( oinfo(iOrbit).start_time, formatOut.yyyymmddThhmmss) '_L2_SST-URI_24-1'];

        oinfo(iOrbit).name = [output_file_directory_local datestr(oinfo(iOrbit).start_time, formatOut.yyyy) '/' ...
            datestr(oinfo(iOrbit).start_time, formatOut.mm) '/' orbit_file_name '.nc4'];

        [status, granule_start_time_guess] = find_next_granule_with_data( granule_start_time_guess);

        % Return if end of run.

        if (status == 201) | (status == 231) | (status > 900)
            fprintf('\n\n\n%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
            fprintf('*    Problem building this orbit or end of run.\n*\n')
            fprintf('*    Processed %i orbits\n*\n', iOrbit)
            fprintf('*    Saving oinfo file to: %s\n*\n', strrep(diary_filename, '.txt', '.mat'))
            fprintf('*    Time for this run: %8.1f seconds or, in minutes, %5.1f or, in hours, %5.1f \n*\n', toc(tic_build_start), toc(tic_build_start)/60, toc(tic_build_start)/3600)
            fprintf('%s\n%s\n', lofs_of_astericks, lofs_of_astericks)

            save(strrep(diary_filename, '.txt', '.mat'), 'oinfo', 'mem_struct', 'problem_list', 'version_struct')

            return
        end
    end


    if determine_fn_size; get_job_and_var_mem; end

    time_to_process_this_orbit = tic;

    [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start, granule_start_time_guess] ...
        = build_orbit( granule_start_time_guess);

    % No remaining granules with a 79 crossing.

    if status > 900
        fprintf('\n\n\n%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
        fprintf('*    Have reached the end of this run.  \n*\n')
        fprintf('*    Processed %i orbits\n*\n', iOrbit)
        fprintf('*    Saving oinfo file to: %s\n*\n', strrep(diary_filename, '.txt', '.mat'))
        fprintf('*    Time for this run: %8.1f seconds or, in minutes, %5.1f or, in hours, %5.1f \n*\n', toc(tic_build_start), toc(tic_build_start)/60, toc(tic_build_start)/3600)
        fprintf('%s\n%s\n', lofs_of_astericks, lofs_of_astericks)

        save(strrep(diary_filename, '.txt', '.mat'), 'oinfo', 'mem_struct', 'problem_list', 'version_struct')

        return
    end

    if status == 231
        fprintf('\n*** Should never get here. Problem building this orbit, skipping to the next one.\n\n')

        % Find the next granule with a ascending 79 S crossing.

        iGranule = 0;
        [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start, granule_start_time_guess] ...
            = build_orbit( granule_start_time_guess);

    else

        if length(latitude)==1

            status = populate_problem_list( 178, ['*** Bad latitude. Exiting this run.'], granule_start_time_guess);

            fprintf('\n\n\n%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
            fprintf('*    Bad latitude somewhere before %s\n*\n',  datestr(granule_start_time_guess))
            fprintf('*    Processed %i orbits\n*\n', iOrbit)
            fprintf('*    Saving oinfo file to: %s\n*\n', strrep(diary_filename, '.txt', '.mat'))
            fprintf('*    Time for this run: %8.1f seconds or, in minutes, %5.1f or, in hours, %5.1f \n*\n', toc(tic_build_start), toc(tic_build_start)/60, toc(tic_build_start)/3600)
            fprintf('%s\n%s\n', lofs_of_astericks, lofs_of_astericks)

            save(strrep(diary_filename, '.txt', '.mat'), 'oinfo', 'mem_struct', 'problem_list', 'version_struct')

            return
        else

            % latitude will be empty where there are missing granules. Fill them in
            % with the canonical orbit.

            nlat_orbit = latitude(677,:);

            nn = find(isnan(nlat_orbit) == 1);

            if ~isempty(nn)
                nlat_orbit(nn) = nlat_avg(nn);
            end

            %% Next fix the mask if requested.

            SST_In_Masked = SST_In;

            if fix_mask
                start_time_to_fix_mask = tic;

                [~, Month, ~, ~, ~, ~] = datevec(oinfo(iOrbit).start_time);
                [Final_Mask] = fix_MODIS_mask_full_orbit( oinfo(iOrbit).name, longitude, latitude, SST_In, qual_sst, flags_sst, sstref, Month);

                oinfo(iOrbit).time_to_fix_mask = toc(start_time_to_fix_mask);

                if print_times
                    fprintf('   Time to fix the mask for this orbit: %6.1f seconds. Current date/time: %s\n', oinfo(iOrbit).time_to_fix_mask, datestr(now))
                end
            else
                Final_Mask = zeros(size(SST_In));
                Final_Mask(qual_sst>=2) = 1;  % Need this for bow-tie fix.

                oinfo(iOrbit).time_to_fix_mask = 0;
            end

            SST_In_Masked(Final_Mask==1) = nan;

            % At this point,
            %   if the mask has been fixed, final_mask will have values of 0
            %    where the SST value is 'good' and 1 where it is 'bad'.
            %   if the mask has NOT been fixed, final_mask is set 0 if
            %    qual_sst<2, the value is 'good' according to the input mask
            %    and it will be set to 1 otherwise, the pixel is 'bad'.
            % AND
            %   if the mask has been fixed, SST_In_Masked is the input SST
            %    field, SST_In, with values for which final_mask is 1 set to
            %    nan; i.e., the corrected mask.
            %   if the mask has NOT been fixed, SST_In_Masked is the input SST
            %    field, SST_In,again with values for which final_mask is 1 set
            %    to nan but in this case using qual_sst values.

            %% Fix the bowtie problem, again if requested.

            if fix_bowtie
                if determine_fn_size; get_job_and_var_mem; end

                start_address_bowtie = tic;

                [status, regridded_longitude, regridded_latitude, regridded_sst, region_start, region_end, ...
                    easting, northing, new_easting, new_northing, ...
                    L2eqaLon, L2eqaLat, L2eqa_MODIS_SST, L2eqa_MODIS_std_SST, L2eqa_MODIS_num_SST, L2eqa_AMSR_E_SST, ...
                    AMSR_E_lon, AMSR_E_lat, AMSR_E_sst, MODIS_SST_on_AMSR_E_grid] = ...
                    regrid_MODIS_orbits( regrid_to_AMSRE, longitude, latitude, SST_In_Masked);

                if (status ~= 0) & (status ~= 1001)
                    fprintf('*** Problem with %s. Status for regrid_MODIS_orbits = %i.\n', oinfo(iOrbit).name, status)
                end

                oinfo(iOrbit).time_to_address_bowtie = toc(start_address_bowtie);

                if print_times
                    fprintf('   Time to address bowtie for this orbit: %6.1f seconds. Current date/time: %s\n',  oinfo(iOrbit).time_to_address_bowtie, datestr(now))
                end
            else
                regridded_sst = SST_In_Masked; % Need this for gradients.

                regridded_longitude = nan;
                regridded_latitude = nan;
                regridded_flags_sst = nan;
                regridded_qual = nan;
                regridded_sstref = nan;
                region_start = nan;
                region_end = nan;
                easting = nan;
                northing = nan;
                new_easting = nan;
                new_northing = nan;

                oinfo(iOrbit).time_to_address_bowtie = 0;
            end

            %% Finally calculate the eastward and northward gradients from the regridded SSTs if requested.

            % Note that if the bow-tie problem has not been fixed, the
            % regridded_sst field is actually the input SST field masked wither
            % with the qual_sst mask if the mask has not been fixed or the
            % fixed mixed mask if it has been fixed. Since some orbits are
            % shorter than the separation and angle arrays, only use the first
            % part; all orbits should start at about the same location.

            if get_gradients
                if determine_fn_size; get_job_and_var_mem; end

                start_time_to_determine_gradient = tic;

                medfilt2_sst = 1;
                if medfilt2_sst
                    sstp = medfilt2(regridded_sst);
                else
                    sstp = regridded_sst;
                end

                [grad_at_per_km, grad_as_per_km, ~] = sobel_gradient_degrees_per_kilometer( ...
                    sstp, ...
                    along_track_seps_array(:,1:size(regridded_sst,2)), ...
                    along_scan_seps_array(:,1:size(regridded_sst,2)));
                clear sstp

                eastward_gradient = grad_at_per_km .* cos_track_angle(:,1:size(regridded_sst,2)) - grad_as_per_km .* sin_track_angle(:,1:size(regridded_sst,2));
                northward_gradient = grad_at_per_km .* sin_track_angle(:,1:size(regridded_sst,2)) + grad_as_per_km .* cos_track_angle(:,1:size(regridded_sst,2));

                oinfo(iOrbit).time_to_determine_gradient = toc(start_time_to_determine_gradient);

                if print_times
                    fprintf('   Time to determine the gradient for this orbit: %6.1f seconds. Current date/time: %s\n', oinfo(iOrbit).time_to_determine_gradient, datestr(now))
                end
            else
                grad_at_per_km = nan;
                grad_as_per_km = nan;

                eastward_gradient = nan;
                northward_gradient = nan;

                oinfo(iOrbit).time_to_determine_gradient = 0;
            end

            %% Wrap-up for this orbit.

            if determine_fn_size; get_job_and_var_mem; end

            time_to_save_orbit = tic;

            if save_orbits
                Write_SST_File( longitude, latitude, SST_In, qual_sst, SST_In_Masked, Final_Mask, scan_seconds_from_start, ...
                    regridded_longitude, regridded_latitude, regridded_sst, ...
                    easting, northing, new_easting, new_northing, ...
                    grad_as_per_km, grad_at_per_km, eastward_gradient, northward_gradient, 1, ...
                    region_start, region_end, fix_mask, fix_bowtie, regrid_sst, get_gradients, ...
                    L2eqaLon, L2eqaLat, L2eqa_MODIS_SST, L2eqa_MODIS_std_SST, L2eqa_MODIS_num_SST, L2eqa_AMSR_E_SST, ...
                    AMSR_E_lon, AMSR_E_lat, AMSR_E_sst, MODIS_SST_on_AMSR_E_grid);

                oinfo(iOrbit).time_to_save_orbit = toc(time_to_save_orbit);

                oinfo(iOrbit).time_to_save_orbit = toc(time_to_save_orbit);

                oinfo(iOrbit).time_to_process_this_orbit = toc(time_to_process_this_orbit);

                if print_times
                    fprintf('   Time to save %s: %6.1f seconds. Current date/time: %s\n', oinfo(iOrbit).name, oinfo(iOrbit).time_to_save_orbit, datestr(now))

                    fprintf('   Time to process and save %s: %6.1f seconds. Current date/time: %s\n', oinfo(iOrbit).name, oinfo(iOrbit).time_to_process_this_orbit, datestr(now))
                end

            else
                oinfo(iOrbit).time_to_process_this_orbit = toc(time_to_process_this_orbit);

                if print_times
                    fprintf('   Time to process %s (results not saved to netCDF): %6.1f seconds. Current date/time: %s\n', oinfo(iOrbit).name, oinfo(iOrbit).time_to_process_this_orbit, datestr(now))
                end
            end
        end
    end

    % Save oinfo and memory structure files for this run.

    save(strrep(diary_filename, '.txt', '.mat'), 'oinfo', 'mem_struct', 'problem_list', 'version_struct')

    % Save the diary to this point

    diary off
    diary(diary_filename)

    % Increment orbit counter and reset granule counter to 1.

    iOrbit = iOrbit + 1;
end

fprintf('\n\n\n%s\n%s\n*\n', lofs_of_astericks, lofs_of_astericks)
fprintf('*    No remaining granules with an ascending 79 S crossing. \n*\n')
fprintf('*    Time for this run: %8.1f seconds or, in minutes, %5.1f or, in hours, %5.1f \n*\n', toc(tic_build_start), toc(tic_build_start)/60, toc(tic_build_start)/3600)
fprintf('%s\n%s\n', lofs_of_astericks, lofs_of_astericks)

