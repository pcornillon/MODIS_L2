function [timing problem_list] = build_and_fix_orbits( granules_directory, metadata_directory, fixit_directory, logs_directory, output_file_directory, ...
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
%   print_diag - 1 to print timing diagnostics, 0 otherwise.
%
% OUTPUT
%   timing - a structure with the times to process different elements of
%    the orbits processed.
%   problem_list - structure with list of filenames for skipped file and
%    the reason for it being skipped:
%    problem_code: 1 - couldn't find the file in s3.
%                : 2 - couldn't find the metadata file copied from OBPG data.
%
% EXAMPLE
% % %   granules_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/';  % Test run.
% % %   orbits_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/Orbits/';  % Test run.
% % %   metadata_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';  % Test run.
% % %   fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/';   % Test run.
% % %   logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';
% % %   output_file_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/';  % Test run.
% % %   [timing problem_list] = build_and_fix_orbits(  orbits_directory, granules_directory, metadata_directory, fixit_directory, ...
% % %    logs_directory, output_file_directory, [2010 1 1 0 0 0], [2010 12 31 23 59 59], 1, 1, 1, 1);
%   granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';
%   metadata_directory = 'Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
%   fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/';   % Test run.
%   logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';
%   output_file_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/';  % Test run.
%   [timing problem_list] = build_and_fix_orbits(  granules_directory, metadata_directory, fixit_directory, ...
%    logs_directory, output_file_directory, [2010 1 1 0 0 0], [2010 12 31 23 59 59], 1, 1, 1, 1);
%
%  To do just the test orbit, specify the start time somewhere in that orbit and
%  the end time about 5 minutes after the start time; e.g.,
%  [timing problem_list] = build_and_fix_orbits( granules_directory, metadata_directory, fixit_directory, ...
%   logs_directory, output_file_directory, [2010 6 19 5 25 0], [2010 6 19 5 30 0 ], 1, 1, 1, 1);
%

global print_diagnostics save_just_the_facts

save_just_the_facts = 1;
if exist('save_core') ~= 0
    if save_core == 0
        save_just_the_facts = 0;
    end
end

print_diagnostics = 0;
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

latlim = -78;

secs_per_day = 86400;

secs_per_orbit = 5933.56;

secs_per_scan_line = 0.1477112;

problem_list.filename{1} = '';
problem_list.problem_code(1) = [];

acceptable_start_time = datenum(2002, 7, 1);
acceptable_end_time = datenum(2022, 12, 31);

% Formats used in building filenames.

formatOut = 'yyyymmddTHHMMSS';
formatOutMnth = 'mm';
formatOutYear = 'yyyy';

%% Check input parameters to make sure they are OK.

if (length(start_date_time) ~= 6) | (length(end_date_time) ~= 6)
    disp(['Input start and end time vectors must be 6 elements long. start_date_time: ' num2str(start_date_time) ' to ' num2str(end_date_time)])
    return
end

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
        = build_metadata_filename( 0, nan, metadata_directory, temp_granule_start_time);
    
    if isempty(missing_granules_temp) == 0
        fprintf('First granule in the specified range (%s, %s) is: %s\n', datestr(Matlab_start_time), datestr(Matlab_end_time), fi_metadata)
        break
    end
    
    % Add 5 minutes to the previous value of time to get the time of the next granule.
    
    temp_granule_start_time = temp_granule_start_time + 5 / (24 * 60);
    
end

if temp_granule_start_time > Matlab_end_time
    fprintf('****** Could not find a granule in the specified range (%s, %s) is: %s\n', datestr(Matlab_start_time), datestr(Matlab_end_time), fi_metadata)
    return
end

%% Find start of first orbit.

% Next, find the ganule at the beginning of the first complete orbit
% defined as starting at descending latlim, nominally 78 S. Not processing
% granules up to this point.

[status, fi_metadata, start_line_index, temp_granule_start_time, orbit_scan_line_times, orbit_start_timeT, num_scan_lines_in_granule] ...
    = find_start_of_orbit( latlim, metadata_directory, temp_granule_start_time, Matlab_end_time);

% Abort this run if a major problem occurs at this point.

if status ~= 0
    fprintf('*** Major problem with metadata file %s at date/time %s or no start of an orbit in the specified range %s to %s. Aborting.\n', ...
        fi_metadata, datestr(temp_granule_start_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
    return
end

% Load the scan line times for the first granule on this orbit.

scan_line_times = orbit_scan_line_times(end,1:num_scan_lines_in_granule);

% Note that we used num_scan_lines_in_granule in the above since there
% could be nans for the last scan lines since the orbit_scan_line_times
% array was inialized with nans for the longest expected granule, 2050 scan
% lines; actually never expect more than 2040 but, just in case...

%% Loop over the remainder of the time range processing all complete orbits that have not already been processed.


while temp_granule_start_time <= Matlab_end_time
    
    % Build the output filename for this orbit and check that it hasn't
    % already been processed. To build the filename, get the orbit number
    % and the date/time when the satellite crossed latlim.
    
    orbit_number = ncreadatt( fi_metadata,'/','orbit_number');
    
    orbit_file_name = ['AQUA_MODIS_orbit_' return_a_string(orbit_number) '_' datestr(orbit_start_time, formatOut) '_L2_SST'];
    
    name_out_sst = [output_file_directory datestr(orbit_start_time, formatOutYear) '/' ...
        datestr(orbit_start_time, formatOutMonth) '/' orbit_file_name '.nc4'];
    
    %% Skip this orbit if it exist already.
    
    if exist(name_out_sst) == 2
        fprintf('Have already processed %s. Going to the next orbit. \n', name_out_sst)
        
        [status, fi_metadata, start_line_index, temp_granule_start_time, orbit_scan_line_times, orbit_start_timeT, num_scan_lines_in_granule] ...
            = find_start_of_orbit( latlim, metadata_directory, temp_granule_start_time, Matlab_end_time);
        
        if status ~= 0
            fprintf('*** Problem with metadata file %s at date/time %s or no start of an orbit in the specified range %s to %s. Aborting.\n', ...
                fi_metadata, datestr(temp_granule_start_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
            return
        end
        
        % Load the scan line times for the first granule on this orbit.
        
        scan_line_times = orbit_scan_line_times(end,1:num_scan_lines_in_granule);
        
        % See comment re use of num_scan_lines_in_granule above in 1st call
        % to find_start_of_orbit.
        
    end
    
    %% Now build this orbit from its granules; a granule has been found with the start of this orbit.
    
    fprintf('Working on %s.\n', name_out_sst)
    
    start_time_to_build_this_orbit = tic;
    
    iGranule = 1;
    
    clear granule
    
    granule(1).metadata_name = fi_metadata;
    
    granule(1).start_time = scan_line_times(1) * secs_per_day;
    granule(1).end_time = scan_line_times(end) * secs_per_day + secs_per_scan_line * 10;
    
    % The next flag is set to 1 if we missed the end of an orbit.
    
    process_this_orbit = 0;
    
    % Initialize orbit arrays.
    
    latitude = single(nan(1354,40271));
    longitude = single(nan(1354,40271));
    SST_In = single(nan(1354,40271));
    qual_sst = int8(nan(1354,40271));
    flags_sst = int16(nan(1354,40271));
    sstref = single(nan(1354,40271));
    
    num_scans_this_orbit = 0;
    
    bad_metadata_file = 0;
    
    temp_granule_start_time_save = temp_granule_start_time;
    
    % Orbit start and end numbers; i.e., the orbit variables will be
    % populated from osscan through oescan.
    
    %     osscan = 1;
    %     oescan = num_scan_lines_in_granule - start_line_index + 1;
    granule(1).osscan = 1;
    granule(1).oescan = num_scan_lines_in_granule - start_line_index + 1;
    
    % Granule start and end numbers; i.e., the input arrays will be read
    % from gsscan through gescan.
    
    %     gsscan = start_line_index;
    %     gescan = num_scan_lines_in_granule;
    granule(1).gsscan = start_line_index;
    granule(1).gescan = num_scan_lines_in_granule;
    
    % Read the data for the first granule in this orbit.
    
    [status, granule(1).data_granule_name, problem_list, global_attrib, latitude, longitude, SST_In, qual_sst, flags_sst, sstref] ...
        = get_granule_data( fi_metadata, granules_directory, problem_list, check_attributes, [granule(1).osscan granule(1).oescan], ...
        [granule(1).gsscan granule(1).gescan], latitude, longitude, SST_In, qual_sst, flags_sst, sstref);
    
    granule(1).status = status;
    
    %% Loop over granules in the orbit.
    
    while temp_granule_start_time <= Matlab_end_time
        
        % Get metadata information for the next granule.
        
        [status, fi_metadata, start_line_index, scan_line_times, missing_granule, num_scan_lines_in_granule, temp_granule_start_time] ...
            = build_metadata_filename( 1, latlim, metadata_directory, iMatlab_time);
        
        if status ~= 0
            fprintf('Problem for granule on orbit #%i at time %s; status returned as %i. Going to next granule.\n', iOrbit, datestr(iMatlab_time), status)
        else
            
            iGranule = iGranule + 1;
            granule(iGranule).metadata_name = fi_metadata;
            
            granule(iGranule).start_time = scan_line_times(1) * secs_per_day;
            granule(iGranule).end_time = scan_line_times(end) * secs_per_day + secs_per_scan_line * 10;
            
            % Get lines to skip for missing granules. Will, hopefully, be 0
            % if no granules skipped.
            
            lines_to_skip = floor( abs((scan_line_times(1)*secs_per_day - granule(end-1).end_time) + 0.05) / secs_per_scan_line);
            
            % Check that the number of lines to skip is a multiple
            % of 10. If not, force it to be.
            
            if mod(lines_to_skip, 10) ~= 0
                fprintf('The number of lines to skip, %i, is not a multiple of 10 for granule %s. Forcing it to 10.\n', lines_to_skip, fi_metadata)
                lines_to_skip = round(lines_to_skip / 10) * 10;
            end
            
            granule(iGranule).osscan = granule(iGranule-1).oescan + 1 + lines_to_skip;
            
            granule(iGranule).gsscan = 1;
            
            if isempty(start_line_index)
                
                % Didn't find the start of a new orbit but the granule for
                % the start of the next orbit may be missing so, check the
                % to see if the end was skipped. If so, process what we
                % have for this orbit. Do not use the scan lines in this
                % granule. When done processing, start a new orbit,
                % estimating the number of scan lines into that orbit.
                
                if scan_line_times(1)*secs_per_day > (granule(1).start_time + secs_per_orbit + 300)
                    process_this_orbit = 1;
                    break
                end
                
                granule(iGranule).oescan = granule(iGranule).osscan + num_scan_lines_in_granule - 1;
                
                granule(iGranule).gescan = num_scan_lines_in_granule;
                
            else
                granule(iGranule).oescan = granule(iGranule).osscan + start_line_index - 2;
                
                granule(iGranule).gescan = start_line_index - 1;
            end
            
            % Read the data for the first granule in this orbit.
            
            [status, granule(1).data_granule_name, problem_list, global_attrib, latitude, longitude, SST_In, qual_sst, flags_sst, sstref] ...
                = get_granule_data( fi_metadata, granules_directory, problem_list, check_attributes, [granule(iGranule).osscan granule(iGranule).oescan], ...
                [granule(iGranule).gsscan granule(iGranule).gescan], latitude, longitude, SST_In, qual_sst, flags_sst, sstref);
            
            granule(iGranule).status = status;
            
            if ~isempty(start_line_index)
                break
            end
        end
        
        timing.time_to_build_orbit(iOrbit) = toc(start_time_to_build_this_orbit);
        
        if print_diagnostics
            disp(['*** Time to build this orbit: ' num2str( timing.time_to_build_orbit(iOrbit), 5) ' seconds.'])
        end
    end
    
    %********************************************************************************
    %********************************************************************************
    %********************************************************************************
    
    
    %% Next fix the mask if requested.
    
    SST_In_Masked = SST_In;
    
    if fix_mask
        start_time_to_fix_mask = tic;
        % % %             [Final_Mask, Test_Counts, FracArea, nnReduced] = fix_MODIS_mask_full_orbit( orbit_file_name, longitude, latitude, SST_In, qual_sst, flags_sst, sstref, str2num(months));
        [Final_Mask] = fix_MODIS_mask_full_orbit( orbit_file_name, longitude, latitude, SST_In, qual_sst, flags_sst, sstref, str2num(months));
        
        timing.time_to_fix_mask(iOrbit) = toc(start_time_to_fix_mask);
        
        if print_diagnostics
            disp(['*** Time to fix the mask for this orbit: ' num2str( timing.time_to_fix_mask(iOrbit), 5) ' seconds.'])
        end
    else
        Final_Mask = zeros(size(SST_In));
        Final_Mask(qual_sst>=2) = 1;  % Need this for bow-tie fix.
        
        timing.time_to_fix_mask(iOrbit) = 0;
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
        
        timing.time_to_address_bowtie(iOrbit) = toc(start_address_bowtie);
        
        if print_diagnostics
            disp(['*** Time to address bowtie for this orbit: ' num2str( timing.time_to_address_bowtie(iOrbit), 5) ' seconds.'])
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
        
        timing.time_to_address_bowtie(iOrbit) = 0;
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
        
        timing.time_to_determine_gradient(iOrbit) = toc(start_time_to_determine_gradient);
        
        if print_diagnostics
            disp(['*** Time to determine the gradient for this orbit: ' num2str( timing.time_to_determine_gradient(iOrbit), 5) ' seconds.'])
        end
    else
        grad_at_per_km = nan;
        grad_as_per_km = nan;
        
        eastward_gradient = nan;
        northward_gradient = nan;
        
        timing.time_to_determine_gradient(iOrbit) = 0;
    end
    
    %% Wrap-up for this orbit.
    
    % % %         Write_SST_File( name_out_sst, longitude, latitude, SST_In, qual_sst, SST_In_Masked, Final_Mask, regridded_longitude, regridded_latitude, ...
    % % %             regridded_sst, easting, northing, new_easting, new_northing, grad_as_per_km, grad_at_per_km, eastward_gradient, northward_gradient, 3, time_coverage_start, GlobalAttributes, ...
    % % %             region_start, region_end, fix_mask, fix_bowtie, get_gradients);
    Write_SST_File( name_out_sst, longitude, latitude, SST_In, qual_sst, SST_In_Masked, Final_Mask, regridded_longitude, regridded_latitude, ...
        regridded_sst, easting, northing, new_easting, new_northing, grad_as_per_km, grad_at_per_km, eastward_gradient, northward_gradient, 1, time_orbit_start, GlobalAttributes, ...
        region_start, region_end, fix_mask, fix_bowtie, get_gradients);
    
    timing.time_to_process_this_orbit(iOrbit) = toc();
    
    if print_diagnostics
        disp(['*** Time to process and save ' name_out_sst ': ', num2str( timing.time_to_process_this_orbit(iOrbit), 5) ' seconds.'])
    end
    
    % Add 5 minutes to the previous value of time to get the time of the
    % next granule and continue searching.
    
    iMatlab_time = iMatlab_time + 5 / (24 * 60);
end

disp(['*** Time for this run: ', num2str(toc(tic_build_start),5) ' seconds.'])

