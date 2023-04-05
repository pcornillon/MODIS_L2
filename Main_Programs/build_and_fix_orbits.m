function [oinfo problem_list] = build_and_fix_orbits( start_date_time, end_date_time, fix_mask, fix_bowtie, regrid_sst, get_gradients, save_core, print_diag)
% build_and_fix_orbits - read in all granules for each orbit in the time range and fix the mask and bowtie - PCC
%
% This function will read all of the
%
% INPUT
%   start_date_time - build orbits with the first orbit to be built
%    including this time specified as: [YYYY, MM, DD, HH, Min, 00].
%   end_date_time - last orbit to be built includes this time.
%   fix_mask - if 1 fixes the mask. If absent, will set to 1.
%   fix_bowtie - if 1 fixes the bow-tie problem, otherwise bow-tie effect
%    not fixed.
%   regrid_sst - 1 to regrid SST after bowtie effect has been addressed.
%   get_gradients - 1 to calculate eastward and northward gradients, 0
%    otherwise.
%   save_core - 1 to save only the core values, regridded lon, lat, SST,
%    refined mask and nadir info, 0 otherwise.
%   print_diagnostics - 1 to print timing diagnostics, 0 otherwise.
%
% OUTPUT
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
%   granules_directory - the base directory for the input files.
%   metadata_directory - the base directory for the location of the
%    metadata files copied from the OBPG files.
%   fixit_directory - the directory for files required by this script to
%    correct the cloud mask and the bow-tie effect.
%   output_file_directory - the base directory for the output files. Note
%    that this must be the full directory name,netCDF doesn't like ~/.
%
%   granules_directory = '/Volumes/Aqua-1/MODIS_R2019/combined/';
%   metadata_directory = 'Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';
%   fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/';   % Test run.
%   logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';
%   output_file_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/';  % Test run.
%   [oinfo problem_list] = build_and_fix_orbits(  granules_directory, metadata_directory, fixit_directory, ...
%    logs_directory, output_file_directory, [2010 1 1 0 0 0], [2010 12 31 23 59 59], 1, 1, 1, 1, 1, 1);
%
%  To do just the test orbit, specify the start time somewhere in that orbit and
%  the end time about 5 minutes after the start time; e.g.,
%  [oinfo problem_list] = build_and_fix_orbits( granules_directory, metadata_directory, fixit_directory, ...
%   logs_directory, output_file_directory, [2010 6 19 5 25 0], [2010 6 19 5 30 0 ], 1, 1, 1, 1, 1, 1);
%
% To do a test run, capture the lines in 'if test_values' group and execute
% them at the Matlab command line prompt.

% Make sure that there are no global variables in the workspace.

clear global


global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length time_of_NASA_orbit_change
global print_diagnostics save_just_the_facts debug
global formatOut
global latlim secs_per_day secs_per_orbit secs_per_scan_line orbit_length npixels
global Matlab_start_time Matlab_end_time
global sst_range sst_range_grid_size
global med_op
global amazon_s3_run

% Structure of oinfo
%
% oinfo.
%   name
%   start_time
%   end_time
%   orbit_number
%   data_global_attrib ?
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
oinfo.data_global_attrib = [];

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

if isempty(metadata_directory)
    metadata_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';  % Test run.
    granules_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/combined/';  % Test run.
    fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/';   % Test run.
    logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';  % Test run.
    output_file_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/';  % Test run.
    start_date_time = [2010 6 19 5 0 0]; % Test run.
    end_date_time = [2010 6 19 11 15 0 ];  % Test run.
    fix_mask = 0;  % Test run.
    fix_bowtie = 1;  % Test run.
    regrid_sst = 0;  % Test run.
    get_gradients = 0;  % Test run.
    save_core = 1;  % Test run.
    print_diagnostics = 1;  % Test run.
    
    debug = 1;
    
    % Remove the previous version of this file.
    
%     ! rm /Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/2010/06/AQUA_MODIS_orbit_43222_20100619T065429_L2_SST.nc4
    
    %     [oinfo problem_list] = build_and_fix_orbits( granules_directory, metadata_directory, fixit_directory, logs_directory, output_file_directory, [2010 6 19 4 0 0], [2010 6 19 7 0 0 ], 0, 0, 0, 1);
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
    fprintf('\n%s\n\n\n', 'This is an Amazon S3 run; will read data from s3 storage.')
    amazon_s3_run = 1;
else
    fprintf('\n%s\n\n\n', 'This is not an Amazon S3 run; will read data from local disks.')
end

%% Initialize some variables.

npixels = 1354;

latlim = -78;

secs_per_day = 86400;
secs_per_orbit = 5933.56;
secs_per_scan_line = 0.1477112;

time_of_NASA_orbit_change = 30000;

orbit_length = 40271;

iProblem = 0;
% % % problem_list.filename{1} = '';
% % % problem_list.code(1) = nan;

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

%% Check input parameters to make sure they are OK.

acceptable_start_time = datenum(2002, 7, 1);
acceptable_end_time = datenum(2022, 12, 31);

if (length(start_date_time) ~= 6) | (length(end_date_time) ~= 6)
    fprintf('Input start and end time vectors must be 6 elements long. start_date_time: %s to %s.\n', num2str(start_date_time), num2str(end_date_time))
    return
end

Matlab_start_time = datenum(start_date_time);
Matlab_end_time = datenum(end_date_time);

if (Matlab_start_time < acceptable_start_time) | (Matlab_start_time > acceptable_end_time)
    fprintf('Specified start time %s not between %s and %s\n', datestr(Matlab_start_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
    return
end

if (Matlab_end_time < acceptable_start_time) | (Matlab_end_time > acceptable_end_time)
    fprintf('Specified end time %s not between %s and %s\n', datestr(Matlab_start_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
    return
end

if strcmp(output_file_directory(1:2), '~/')
    fprintf('The output base directory must be fully specified; cannot start with ~/. Won''t work with netCDF. You entered: %s.\n', output_file_directory)
    return
end

%% Passed checks on input parameters. Open a diary file for this run.

Diary_File = [logs_directory 'build_and_fix_orbits_' strrep(num2str(now), '.', '_') '.txt'];
diary(Diary_File)

tic_build_start = tic;

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

% Start by looking for the first granule after Matlab_start_time with a 
% descending nadir track crossing latlim, nominally 73 S.

iOrbit = 1;
iGranule = 0;

[status, metadata_file_list, data_file_list, indices, granule_start_time_guess] = get_start_of_first_full_orbit;

iOrbit = iOrbit + 1;

% If end of run, return; not a very productive run.

if status > 900
    return
end

%% Loop over the remainder of the time range processing all complete orbits that have not already been processed.

while granule_start_time_guess <= Matlab_end_time
    
    %% Build the orbit.
    
    time_to_process_this_orbit = tic;
    
    [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start, granule_start_time_guess] ...
        = build_orbit( granule_start_time_guess);
    
    if status > 0
        if print_diagnostics
            fprintf('Just returned from build_orbit with status #%i. Hopefull either 251 or > 900.\n', status)
        end
    
        if status > 900
            fprintf('End of run.\n')
            return
        end
        
        if (status == 251) & print_diagnostics
            fprintf('Orbit already processed, skipping to the next orbit starting at %s\n', datestr(oinfo(iOrbit).start_time))
        end
        
        if (status == 201) & print_diagnostics
            fprintf('Not sure what this error is for. Sort it out if it comes up %s\n', datestr(oinfo(iOrbit).start_time))
            
            if debug
                keyboard
            end
        end
    else
        
        %% Next fix the mask if requested.
        
        SST_In_Masked = SST_In;
        
        if fix_mask
            start_time_to_fix_mask = tic;
            
            [Final_Mask] = fix_MODIS_mask_full_orbit( oinfo(iOrbit).name, longitude, latitude, SST_In, qual_sst, flags_sst, sstref, str2num(months));
            
            oinfo(iOrbit).time_to_fix_mask = toc(start_time_to_fix_mask);
            
            if print_diagnostics
                fprintf('   Time to fix the mask for this orbit: %6.1f seconds.\n', oinfo(iOrbit).time_to_fix_mask)
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
            start_address_bowtie = tic;
            
            % ******************************************************************************************
            % Need to add augmented_weights, augmented_locations as the first
            % two arugments of the call to regrid... if you want to use fast
            % regridding.
            % ******************************************************************************************
            
            [status, regridded_longitude, regridded_latitude, regridded_sst, region_start, region_end, easting, northing, new_easting, new_northing] = ...
                regrid_MODIS_orbits( regrid_sst, augmented_weights, augmented_locations, longitude, latitude, SST_In_Masked);
            
            if status ~= 0
                fprintf('*** Problem with %s. Status for regrid_MODIS_orbits = %i.\n', oinfo.name, status)
            end
            
            oinfo(iOrbit).time_to_address_bowtie = toc(start_address_bowtie);
            
            if print_diagnostics
                fprintf('   Time to address bowtie for this orbit: %6.1f seconds.\n',  oinfo(iOrbit).time_to_address_bowtie)
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
            start_time_to_determine_gradient = tic;
            
            [grad_at_per_km, grad_as_per_km, grad_mag_per_km] = sobel_gradient_degrees_per_kilometer( ...
                regridded_sst, ...
                along_track_seps_array(:,1:size(regridded_sst,2)), ...
                along_scan_seps_array(:,1:size(regridded_sst,2)));
            
            eastward_gradient = grad_at_per_km .* cos_track_angle(:,1:size(regridded_sst,2)) - grad_as_per_km .* sin_track_angle(:,1:size(regridded_sst,2));
            northward_gradient = grad_at_per_km .* sin_track_angle(:,1:size(regridded_sst,2)) + grad_as_per_km .* cos_track_angle(:,1:size(regridded_sst,2));
            
            oinfo(iOrbit).time_to_determine_gradient = toc(start_time_to_determine_gradient);
            
            if print_diagnostics
                fprintf('   Time to determine the gradient for this orbit: %6.1f seconds.\n', oinfo(iOrbit).time_to_determine_gradient, 5)
            end
        else
            grad_at_per_km = nan;
            grad_as_per_km = nan;
            
            eastward_gradient = nan;
            northward_gradient = nan;
            
            oinfo(iOrbit).time_to_determine_gradient = 0;
        end
        
        %% Wrap-up for this orbit.
                
        Write_SST_File( longitude, latitude, SST_In, qual_sst, SST_In_Masked, Final_Mask, scan_seconds_from_start, regridded_longitude, regridded_latitude, ...
            regridded_sst, easting, northing, new_easting, new_northing, grad_as_per_km, grad_at_per_km, eastward_gradient, northward_gradient, 1, ...
            region_start, region_end, fix_mask, fix_bowtie, regrid_sst, get_gradients);
        
        oinfo(iOrbit).time_to_process_this_orbit = toc(time_to_process_this_orbit);

        if print_diagnostics
            fprintf('   Time to process and save %s: %6.1f seconds.\n', oinfo(iOrbit).name, oinfo(iOrbit).time_to_process_this_orbit)
        end
    end
    
    % Increment orbit counter and reset granule counter to 1.
    
    iOrbit = iOrbit + 1;
end

fprintf('   Time for this run: %8.1f seconds or, in minutes, %5.1f\n', toc(tic_build_start), toc(tic_build_start/60))

