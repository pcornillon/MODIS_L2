function [orbit_info problem_list] = build_and_fix_orbits( granules_directory, metadata_directory, fixit_directory, logs_directory, output_file_directory, ...
    start_date_time, end_date_time, fix_mask, fix_bowtie, get_gradients, use_OBPG, save_core, print_diag)
% build_and_fix_orbits - read in all granules for each orbit in the time range and fix the mask and bowtie - PCC
%
% This function will read all of the
%
% INPUT
%   granules_directory - the base directory for the input files.
%   metadata_directory - the base directory for the location of the
%    metadata files copied from the OBPG files.
%   fixit_directory - the directory for files required by this script to
%    correct the cloud mask and the bow-tie effect.
%   output_file_directory - the base directory for the output files. Note
%    that this must be the full directory name,netCDF doesn't like ~/.
%   start_date_time - build orbits with the first orbit to be built
%    including this time specified as: [YYYY, MM, DD, HH, Min, 00].
%   end_date_time - last orbit to be built includes this time.
%   fix_mask - if 1 fixes the mask. If absent, will set to 1.
%   fix_bowtie - if 1 fixes the bow-tie problem, otherwise bow-tie effect
%    not fixed.
%   get_gradients - 1 to calculate eastward and northward gradients, 0
%    otherwise.
%   use_OBPG - use metadata copied from the OBPG file.
%   save_core - 1 to save only the core values, regridded lon, lat, SST,
%    refined mask and nadir info, 0 otherwise.
%   print_diagnostics - 1 to print timing diagnostics, 0 otherwise.
%
% OUTPUT
% % %   timing - a structure with the times to process different elements of
% % %    the orbits processed.
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
%   granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';
%   metadata_directory = 'Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
%   fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/';   % Test run.
%   logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';
%   output_file_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/';  % Test run.
%   [orbit_info problem_list] = build_and_fix_orbits(  granules_directory, metadata_directory, fixit_directory, ...
%    logs_directory, output_file_directory, [2010 1 1 0 0 0], [2010 12 31 23 59 59], 1, 1, 1, 1);
%
%  To do just the test orbit, specify the start time somewhere in that orbit and
%  the end time about 5 minutes after the start time; e.g.,
%  [orbit_info problem_list] = build_and_fix_orbits( granules_directory, metadata_directory, fixit_directory, ...
%   logs_directory, output_file_directory, [2010 6 19 5 25 0], [2010 6 19 5 30 0 ], 1, 1, 1, 1);
%
% To do a test run, capture the lines in 'if test_values' group and execute
% them at the Matlab command line prompt.

global print_diagnostics save_just_the_facts

% Initialize return variables.

if ~exist('metadata_directory')
    metadata_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';  % Test run.
    granules_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/combined/';  % Test run.
    fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/';   % Test run.
    logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';  % Test run.
    output_file_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/';  % Test run.
    start_date_time = [2010 6 19 5 10 0]; % Test run.
    end_date_time = [2010 6 20 7 0 0 ];  % Test run.
    fix_mask = 0;  % Test run.
    fix_bowtie = 1;  % Test run.
    get_gradients = 0;  % Test run.
    use_OBPG = 0;  % Test run.
    save_core = 0;  % Test run.
    print_diagnostics = 1;  % Test run.
    
    %     [orbit_info problem_list] = build_and_fix_orbits( granules_directory, metadata_directory, fixit_directory, logs_directory, output_file_directory, [2010 6 19 4 0 0], [2010 6 19 7 0 0 ], 0, 0, 0, 1);
end

save_just_the_facts = 1;
if exist('save_core') ~= 0
    if save_core == 0
        save_just_the_facts = 0;
    end
end

if exist('print_diag') ~= 0
    if print_diag == 1
        print_diagnostics = 1;
    end
end

if exist('use_OBPG') == 0
    use_OBPG = 1;
    fprintf('\n\nWill use OBPG metadata for this run.\n')
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
    fprintf('\n\n%s\n\n\n', 'This is an Amazon S3 run; will read data from s3 storage.')
    amazon_s3_run = 1;
    
    % If an S3 run will have to use OBPG metadata regardless of the value passed in.
    
    use_OBPG = 1;
else
    fprintf('\n\n%s\n\n\n', 'This is not an Amazon S3 run; will read data from local disks.')
end

%% Initialize some variables.

global iOrbit orbit_info

iOrbit = 0;

global npixels

npixels = 1354;

global latlim secs_per_day secs_per_orbit secs_per_scan_line orbit_length

latlim = -78;

secs_per_day = 86400;
secs_per_orbit = 5933.56;
secs_per_scan_line = 0.1477112;

orbit_length = 40271;

problem_list.filename{1} = '';
problem_list.problem_code(1) = nan;

acceptable_start_time = datenum(2002, 7, 1);
acceptable_end_time = datenum(2022, 12, 31);

% Formats used in building filenames.

global formatOutDateTime formatOutMonth formatOutYear

formatOutDateTime = 'yyyymmddTHHMMSS';
formatOutMonth = 'mm';
formatOutYear = 'yyyy';

%% Check input parameters to make sure they are OK.

if (length(start_date_time) ~= 6) | (length(end_date_time) ~= 6)
    disp(['Input start and end time vectors must be 6 elements long. start_date_time: ' num2str(start_date_time) ' to ' num2str(end_date_time)])
    return
end

global Matlab_end_time

Matlab_start_time = datenum(start_date_time);
Matlab_end_time = datenum(end_date_time);

if (Matlab_start_time < acceptable_start_time) | (Matlab_start_time > acceptable_end_time)
    disp(['Specified start time ' datestr(Matlab_start_time) ' not between ' datestr(Matlab_start_time) ' and ' datestr(Matlab_end_time)])
    return
end

if (Matlab_end_time < acceptable_start_time) | (Matlab_end_time > acceptable_end_time)
    disp(['Specified start time ' datestr(Matlab_end_time) ' not between ' datestr(Matlab_start_time) ' and ' datestr(Matlab_end_time)])
    return
end

if strcmp(output_file_directory(1:2), '~/')
    disp(['The output base directory must be fully specified; cannot start with ~/. Won''t work with netCDF. You entered: ' output_file_directory])
    return
end

%% Passed checks on input parameters. Open a diary file for this run.

Diary_File = [logs_directory 'build_and_fix_orbits_' strrep(num2str(now), '.', '_') '.txt'];
diary(Diary_File)

tic_build_start = tic;

%% Initialize parameters

% Start with global variables.

% med_op is the 2 element vector specifying the number of pixels to use in
% the median filtering operation. Usually it is [3 3] but for test work,
% set it to [1 1]; i.e., do not median filter.

global med_op
med_op = [1 1];

% Get the range matrices to use for the reference temperature test.

global sst_range sst_range_grid_size

sst_range_grid_size = 2;

% % % load ~/Dropbox/ComputerPrograms/Satellite_Model_SST_Processing/AI-SST/Data/SST_Ranges/SST_Range_for_Declouding.mat
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

%% Read in the arrays for fast regridding (first) and those used to calculate gradients (second).

% Fast regridding arrays.

if fix_bowtie
    %     load Orbit_Weights_and_Locations_11501.mat
    %     clear fi_orbits fi_weights
    load([fixit_directory 'weights_and_locations_from_31191.mat'])
end

% Gradient stuff

if get_gradients
    gradient_filename = [fixit_directory 'Separation_and_Angle_Arrays.n4'];
    
    track_angle = ncread( gradient_filename, 'track_angle');
    cos_track_angle = cosd(track_angle);
    sin_track_angle = sin(track_angle);
    clear track_angle
    
    along_scan_seps_array = ncread(gradient_filename, 'along_scan_seps_array');
    along_track_seps_array = ncread(gradient_filename, 'along_track_seps_array');
end

%______________________________________________________________________________________________
%______________________________________________________________________________________________
%______________________________________________________________________________________________

%% Find first granule in time range.

% temp_granule_start_time is the time a dummy variable for the approximate
% start time of a granule. It will be incremented by 5 minutes/granule as
% this script loops through granules. Need to find the first granule in the
% range. Since there has to be a metadata granule corresponding to the
% first data granule, search for the first metadata granule. Note that
% build_metadata_filename will upgrade temp_granule_start_time to the
% actual time of the 1st scan when called with 1 for the 1st argument. This
% effectively syncs the start times to avoid any drifts.

temp_granule_start_time = Matlab_start_time;

while temp_granule_start_time <= Matlab_end_time
    
    [status, fi_metadata, start_line_index, scan_line_times, missing_granules_temp, num_scan_lines_in_granule, temp_granule_start_time] ...
        = build_metadata_filename( 1, metadata_directory, temp_granule_start_time);
    
    if isempty(missing_granules_temp)
        fprintf('Found a granule in the specified range (%s, %s) is: %s\n', datestr(Matlab_start_time), datestr(Matlab_end_time), fi_metadata)
        break
    end
    
    % Add 5 minutes to the previous value of time to get the time of the next granule.
    
    temp_granule_start_time = temp_granule_start_time + 5 / (24 * 60);
    
end

if temp_granule_start_time > Matlab_end_time
    fprintf('****** Could not find a granule in the specified range (%s, %s) is: %s\n', datestr(Matlab_start_time), datestr(Matlab_end_time), fi_metadata)
    return
end

% If the first granule does NOT contain the start of an orbit--defined as
% the point at which the descending satellite crosses latlim, nominally
% 78 S--increment temp_granule_start_time so that find_start_of_orbit
% doesn't reread this granule--that would be a waster of time but OK
% otherwise--and then search for a granule that contains the start of an
% orbit.

if isempty(start_line_index)
    
    % Not a new orbit granule; add 5 minutes to the previous value of
    % time to get the time of the next granule and continue searching.
    
    temp_granule_start_time = temp_granule_start_time + 5 / (24 * 60);
    
    % Next, find the ganule at the beginning of the first complete orbit
    % defined as starting at descending latlim, nominally 78 S. Not processing
    % granules up to this point.
    
    [status, fi_metadata, start_line_index, temp_granule_start_time, orbit_scan_line_times, orbit_start_time, num_scan_lines_in_granule] ...
        = find_start_of_orbit( metadata_directory, temp_granule_start_time);
    
    % Abort this run if a major problem occurs at this point.
    
    if status ~= 0
        fprintf('*** Major problem with metadata file %s at date/time %s or no start of an orbit in the specified range %s to %s. Aborting.\n', ...
            fi_metadata, datestr(temp_granule_start_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
        return
    end
    
    % Load the scan line times for the last granule found, the first
    % granule in a new orbit.
    
    scan_line_times = orbit_scan_line_times(end,1:num_scan_lines_in_granule);
    
    % Note that we used num_scan_lines_in_granule in the above since there
    % could be nans for the last scan lines since the orbit_scan_line_times
    % array was inialized with nans for the longest expected granule, 2050 scan
    % lines; actually never expect more than 2040 but, just in case...
else
    
    % Found the start of the next orbit, save the start time.
    
    orbit_start_time = scan_line_times(start_line_index);
end

%% Loop over the remainder of the time range processing all complete orbits that have not already been processed.


while temp_granule_start_time <= Matlab_end_time
    
    %% Build the orbit.
    
    time_to_process_this_orbit = tic;
    
    iOrbit = iOrbit + 1;
    
    orbit_info(iOrbit).orbit_start_time = orbit_start_time;
    orbit_info(iOrbit).granule_info(1).metadata_global_attrib = ncinfo(fi_metadata);
    
    this_orbit_start_time = orbit_start_time;
    
    [status, name_out_sst, problem_list, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, orbit_start_time] ...
        = build_orbit( problem_list, granules_directory, metadata_directory, output_file_directory, fi_metadata, start_line_index, temp_granule_start_time, scan_line_times, ...
        num_scan_lines_in_granule);
    
    if status == 110
        fprintf('*****\n*****\nMajor problem. Status %i. Terminating the run.\n\n', status)
        return
    end
    
    if status > 0
        if status == 200
            fprintf('Orbit already processed, skipping to the next orbit starting at %s\n', datestr(orbit_start_time))
        else
            fprintf('*****\nStatus \i for orbit %s. Do not process this orbit.\n\n', status, orbit_info(iOrbit).name)
        end
        
        % Decrement the orbit counter since we have already startd an orbit
        % but will not be processing it; it has already been processed or
        % there is a problem with it.
        
        iOrbit = iOrbit - 1;
    else
        
        %% Next fix the mask if requested.
        
        SST_In_Masked = SST_In;
        
        if fix_mask
            start_time_to_fix_mask = tic;
            % % %             [Final_Mask, Test_Counts, FracArea, nnReduced] = fix_MODIS_mask_full_orbit( orbit_file_name, longitude, latitude, SST_In, qual_sst, flags_sst, sstref, str2num(months));
            [Final_Mask] = fix_MODIS_mask_full_orbit( orbit_file_name, longitude, latitude, SST_In, qual_sst, flags_sst, sstref, str2num(months));
            
            orbit_info(iOrbit).time_to_fix_mask = toc(start_time_to_fix_mask);
            
            if print_diagnostics
                disp(['*** Time to fix the mask for this orbit: ' num2str( orbit_info(iOrbit).time_to_fix_mask, 5) ' seconds.'])
            end
        else
            Final_Mask = zeros(size(SST_In));
            Final_Mask(qual_sst>=2) = 1;  % Need this for bow-tie fix.
            
            orbit_info(iOrbit).time_to_fix_mask = 0;
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
            start_address_bowtie = tic;
            
            % ******************************************************************************************
            % Need to add augmented_weights, augmented_locations as the first
            % two arugments of the call to regrid... if you want to use fast
            % regridding.
            % ******************************************************************************************
            
            % % %             [regridded_longitude, regridded_latitude, regridded_sst, regridded_flags_sst, regridded_qual, regridded_sstref, ...
            % % %                 region_start, region_end, easting, northing, new_easting, new_northing] = ...
            % % %                 regrid_MODIS_orbits( augmented_weights, augmented_locations, longitude, latitude, SST_In_Masked, flags_sst, qual_sst, sstref);
            [regridded_longitude, regridded_latitude, regridded_sst, region_start, region_end, easting, northing, new_easting, new_northing] = ...
                regrid_MODIS_orbits( augmented_weights, augmented_locations, longitude, latitude, SST_In_Masked);
            
            orbit_info(iOrbit).time_to_address_bowtie = toc(start_address_bowtie);
            
            if print_diagnostics
                disp(['*** Time to address bowtie for this orbit: ' num2str( orbit_info(iOrbit).time_to_address_bowtie, 5) ' seconds.'])
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
            
            orbit_info(iOrbit).time_to_address_bowtie = 0;
        end
        
        %% Finally calculate the eastward and northward gradients from the regridded SSTs if requested.
        
        % Note that if the bow-tie problem has not been fixed, the
        % regridded_sst field is actually the input SST field masked wither
        % with the qual_sst mask if the mask has not been fixed or the
        % fixed mixed mask if it has been fixed. Since some orbits are
        % shorter than the separation and angle arrays, only use the first
        % part; all orbits should start at about the same location.
        
        if get_gradients
            start_time_to_determine_gradient = tic;
            
            [grad_at_per_km, grad_as_per_km, grad_mag_per_km] = sobel_gradient_degrees_per_kilometer( regridded_sst, along_track_seps_array(:,1:size(regridded_sst,2)), along_scan_seps_array(:,1:size(regridded_sst,2)));
            
            eastward_gradient = grad_at_per_km .* cos_track_angle(:,1:size(regridded_sst,2)) - grad_as_per_km .* sin_track_angle(:,1:size(regridded_sst,2));
            northward_gradient = grad_at_per_km .* sin_track_angle(:,1:size(regridded_sst,2)) + grad_as_per_km .* cos_track_angle(:,1:size(regridded_sst,2));
            
            orbit_info(iOrbit).time_to_determine_gradient = toc(start_time_to_determine_gradient);
            
            if print_diagnostics
                disp(['*** Time to determine the gradient for this orbit: ' num2str( orbit_info(iOrbit).time_to_determine_gradient, 5) ' seconds.'])
            end
        else
            grad_at_per_km = nan;
            grad_as_per_km = nan;
            
            eastward_gradient = nan;
            northward_gradient = nan;
            
            orbit_info(iOrbit).time_to_determine_gradient = 0;
        end
        
        %% Wrap-up for this orbit.
        
        orbit_info(iOrbit).time_to_process_this_orbit = toc(time_to_process_this_orbit);
        
        % % %         Write_SST_File( name_out_sst, longitude, latitude, SST_In, qual_sst, SST_In_Masked, Final_Mask, regridded_longitude, regridded_latitude, ...
        % % %             regridded_sst, easting, northing, new_easting, new_northing, grad_as_per_km, grad_at_per_km, eastward_gradient, northward_gradient, 3, time_coverage_start, GlobalAttributes, ...
        % % %             region_start, region_end, fix_mask, fix_bowtie, get_gradients);
        Write_SST_File( name_out_sst, longitude, latitude, SST_In, qual_sst, SST_In_Masked, Final_Mask, regridded_longitude, regridded_latitude, ...
            regridded_sst, easting, northing, new_easting, new_northing, grad_as_per_km, grad_at_per_km, eastward_gradient, northward_gradient, 1, ...
            datestr(orbit_start_time,formatOutDateTime), region_start, region_end, fix_mask, fix_bowtie, get_gradients);
        
        if print_diagnostics
            disp(['*** Time to process and save ' name_out_sst ': ', num2str( orbit_info(iOrbit).time_to_process_this_orbit, 5) ' seconds.'])
        end
        
        % Add 5 minutes to the previous value of time to get the time of the
        % next granule and continue searching.
        
        iMatlab_time = iMatlab_time + 5 / (24 * 60);
    end
end

fprintf('*** Time for this run: %8.1f seconds or, in minutes, %5.1f\n', toc(tic_build_start), toc(tic_build_start/60))

