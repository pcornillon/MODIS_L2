function [timing problem_list] = build_and_fix_orbits( orbits_directory, granules_directory, metadata_directory, fixit_directory, logs_directory, output_file_directory, ...
    start_date_time, end_date_time, fix_mask, fix_bowtie, get_gradients, use_OBPG, save_core, print_diag)
% build_and_fix_orbits - read in all granules for each orbit in the time range and fix the mask and bowtie - PCC
%
% This function will read all of the
%
% INPUT
%   orbits_directory - the base directory for the .mat files with the
%    orbit info, specifically, the names of granules contributing to each
%    orbit. 
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
%   granules_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/';  % Test run.
%   orbits_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/Orbits/';  % Test run.
%   metadata_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';  % Test run.
%   fixit_directory = '/Users/petercornillon/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/';   % Test run.
%   logs_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Logs/';
%   output_file_directory = '/Users/petercornillon/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/SST/';  % Test run.
%   [timing problem_list] = build_and_fix_orbits(  orbits_directory, granules_directory, metadata_directory, fixit_directory, ...
%    logs_directory, output_file_directory, [2010 1 1 0 0 0], [2010 12 31 23 59 59], 1, 1, 1, 1);
%
%  To do just the test orbit, specify the start time somewhere in that orbit and
%  the end time about 5 minutes after the start time; e.g.,
%  [timing problem_list] = build_and_fix_orbits(  orbits_directory, granules_directory, metadata_directory, fixit_directory, ...
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
June_19_2010_run = 0;

if length(granules_directory) > 5
    if strcmp( granules_directory(1:2), 's3') == 1
        fprintf('\n\n%s\n\n\n', 'This is an Amazon S3 run; will read data from s3 storage.')
        amazon_s3_run = 1;
    else
        fprintf('\n\n%s\n\n\n', 'This is a GSO run; will read data from Aqua-1.')
    end
else
    fprintf('\n\n%s\n\n\n', 'This is a 19 June 2010 run; will read data from Matlab Project.')
    June_19_2010_run = 1;
end


%% Initialize some variables.

problem_list.filename{1} = '';
problem_list.problem_code{1} = nan;

acceptable_start_time = datenum(2002, 7, 1);
acceptable_end_time = datenum(2022, 12, 31);

%% Check input parameters to make sure they are OK.

if (length(start_date_time) ~= 6) | (length(end_date_time) ~= 6)
    disp(['Input start and end time vectors must be 6 elements long. start_date_time: ' num2str(start_date_time) ' to ' num2str(end_date_time)])
    return
end

matlab_start_time = datenum(start_date_time);
matlab_end_time = datenum(end_date_time);

if (matlab_start_time < acceptable_start_time) | (matlab_start_time > acceptable_end_time)
    disp(['Specified start time ' datestr(matlab_start_time) ' not between ' datestr(matlab_start_time) ' and ' datestr(matlab_end_time)])
    return
end

if (matlab_end_time < acceptable_start_time) | (matlab_end_time > acceptable_end_time)
    disp(['Specified start time ' datestr(matlab_end_time) ' not between ' datestr(matlab_start_time) ' and ' datestr(matlab_end_time)])
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

%% Get the nadir track information for the specified period

orbit_info.matlab_times = [];
orbit_info.matlab_timee = [];
orbit_info.scan_line_start = [];
orbit_info.scan_line_end = [];
filenames = [];
filename_index = [];
scan_line_in_file = [];

kmonth = 0;
current_time = matlab_start_time;
while current_time < matlab_end_time
    
    [iyear imonth iday] = datevec(current_time);
    
    %     eval(['xx = load(''/Volumes/Aqua-1/MODIS_R2019/Orbits/nadir_info_' return_a_string(iyear) '_' return_a_string(imonth) '.mat'', ''filenames'', ''filename_index'', ''orbit_info'', ''scan_line_in_file'');'])
    eval(['xx = load(''' orbits_directory 'nadir_info_' return_a_string(iyear) '_' return_a_string(imonth) '.mat'', ''filenames'', ''filename_index'', ''orbit_info'', ''scan_line_in_file'');'])
    
    filenames = [filenames xx.filenames];
    filename_index = [filename_index; xx.filename_index];
    scan_line_in_file = [scan_line_in_file xx.scan_line_in_file];
    
    orbit_info.matlab_times = [orbit_info.matlab_times; xx.orbit_info.matlab_times];
    orbit_info.matlab_timee = [orbit_info.matlab_timee; xx.orbit_info.matlab_timee];
    orbit_info.scan_line_start = [orbit_info.scan_line_start xx.orbit_info.scan_line_start];
    orbit_info.scan_line_end = [orbit_info.scan_line_end xx.orbit_info.scan_line_end];
    
    kmonth = kmonth + 1;
    current_time = datenum(start_date_time(1), start_date_time(2)+kmonth, 1);
end
clear xx

%% Get the first and last orbits to process

start_orbit_no = find( (matlab_start_time >= orbit_info.matlab_times) & (matlab_start_time <= orbit_info.matlab_timee) );
end_orbit_no = find( (matlab_end_time >= orbit_info.matlab_times) & (matlab_end_time <= orbit_info.matlab_timee) );

if (length(start_orbit_no) ~= 1) & (length(end_orbit_no) ~= 1)
    disp(['There is not one starting orbit at time ' datestr(matlab_start_time) ' and one ending orbit at time ' datestr(matlab_end_time)])
    keyboard
end

if start_orbit_no > end_orbit_no
    disp(['The first orbit number ' num2str(start_orbit_no) ' is after the second orbit number ' num2str(end_orbit_no)])
end

disp(['Will process from orbit #s ' num2str(start_orbit_no) ' (' datestr(matlab_start_time) ') to ' num2str(end_orbit_no) ' (' datestr(matlab_end_time) ')'])

iProblemFile = 0;

for iOrbit=start_orbit_no:end_orbit_no
    
    start_time_to_process_this_orbit = tic;
    
    file_list = filenames(filename_index(orbit_info.scan_line_start(iOrbit)):filename_index(orbit_info.scan_line_end(iOrbit)));
    
    % Build the output filename for this file and check to see if it
    % exists. If so, go to the next orbit.
    
    formatOut = 'yyyymmddTHHMMSS';
    orbit_file_name = ['AQUA_MODIS.' datestr(orbit_info.matlab_times(iOrbit), formatOut) '.L2.SST'];
    
    timing.orbit_file_name{iOrbit} = orbit_file_name;
    
    formatOut = 'yyyy';
    years = datestr(orbit_info.matlab_times(iOrbit), formatOut);
    
    formatOut = 'mm';
    months = datestr(orbit_info.matlab_times(iOrbit), formatOut);
    
    name_out_sst = [output_file_directory years '/' months '/' orbit_file_name '.nc4'];
    
    if exist(name_out_sst) ~= 2
        
        disp(['Working on orbit # ' num2str(iOrbit) '. Output will be written to: ' orbit_file_name ])
        
        start_time_to_build_this_orbit = tic;
        
        %% Now build this orbit from its granules.
        
        latitude = [];
        longitude = [];
        SST_In = [];
        qual_sst = [];
        flags_sst = [];
        sstref = [];
        
        for ifilename=1:length(file_list)
            
            process_this_one = 1;
            
            filename = file_list{ifilename};
            
            % Build the names of the files to read. This depends on whether
            % the data are from s3 or OBPG. Also, the seconds for the
            % metadata file may not agree with the file on the  list in
            % that one may have been drawn from a 'day' file and the other
            % from a 'night' file, for reasons beyond me these are often
            % off by one second. In addition to replacing the directory
            % name for the files on the list with the base directory passed
            % in, the filenames from OBPG differ from those in s3, so this
            % must be fixed as well.
            %
            % Names in file list: '/Volumes/Aqua-1/MODIS_R2019/night/2010/AQUA_MODIS.20100618T222507.L2.SST.nc'
            % s3 names: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100620235508-JPL-L2P_GHRSST-SSTskin-MODIS_A-N-v02.0-fv01.0.nc
            % OBPG metadata names: AQUA_MODIS_20100619T053008_L2_SST_OBPG_extras.nc4
            %
            % Start by building the complete file name to use for the SST
            % data. First, need to get the year, month, day, hour and minute.
            
            nn = strfind( filename, 'AQUA_MODIS.');
            
            name_in_date = filename(nn+11:nn+18);
            name_in_hr_min = filename(nn+20:nn+23);
            
            ss = strfind(filename, '/');
            
            if amazon_s3_run
                % % %                 fi = [granules_directory name_in_date name_in_hr_min '07' filename(ss(end)+15:end)];
                % % %                 if exist(fi) ~= 2
                % % %                     fi = [granules_directory name_in_date name_in_hr_min '08' filename(ss(end)+15:end)];
                % % %                     if exist(fi) ~= 2
                % % %                         iProblemFile = iProblemFile + 1;
                % % %                         problem_list.filename{iProblemFile} = filename;
                % % %                         problem_list.problem_code{iProblemFile} = 1;
                % % %
                % % %                         process_this_one = 1;
                % % %                     end
                % % %                 end
                for iMeta=[7 8 0 1 2 3 4 5 6 9]
                    fi_meta = [metadata_directory filename(ss(end)+1:dd-2) '0' num2str(iMeta) filename(ss(end)+15:end)];
                    if exist(fi) == 2
                        found_meta = 1;
                        break
                    end
                end
                
                if found_meta == 0
                    iProblemFile = iProblemFile + 1;
                    problem_list.filename{iProblemFile} = filename;
                    problem_list.problem_code{iProblemFile} = 1;
                    
                    process_this_one = 0;
                    
                    fprintf('\n******************************\nSkipping %s; could not find input file.\n******************************\n', fi_meta)
                end
            else
                fi = [granules_directory filename(ss(end-2)+1:end)];
            end
            
            % Now build the metadata filename.
            
            dd = strfind( filename, '.L2.');
            filename = strrep( filename, '.', '_');
            
            if use_OBPG
                found_meta = 0;
                for iMeta=[7 8 0 1 2 3 4 5 6 9]
                    fi_meta = [metadata_directory filename(ss(end)+1:dd-3) '0' num2str(iMeta) '_L2_SST_OBPG_extras.nc4'];
                    if exist(fi_meta) == 2
                        found_meta = 1;
                        break
                    end
                end
                
                if found_meta == 0
                    iProblemFile = iProblemFile + 1;
                    problem_list.filename{iProblemFile} = filename;
                    problem_list.problem_code{iProblemFile} = 2;
                    
                    process_this_one = 0;
                    
                    fprintf('\n******************************\nSkipping %s; could not find its metadata file.\n******************************\n', fi_meta)
                end
            else
                fi_meta = [granules_directory filename(ss(end)+1:end)];
            end
            
            if process_this_one
                
                % Get the scans to read for this granule.
                
                info = ncinfo(fi);
                if strcmp(info.Dimensions(1).Name, 'number_of_lines') ~= 1
                    disp(['Wrong dimension: ' info.Dimensions(1).Name])
                    keyboard
                end
                nscans = info.Dimensions(1).Length;
                npixels = info.Dimensions(2).Length;
                
                % Get the start and end times for this granule.
                 
                xx = info.Attributes(29).Value;
                datetime_start = datenum( str2num(xx(1:4)), str2num(xx(6:7)), str2num(xx(9:10)), str2num(xx(12:13)), str2num(xx(15:16)), str2num(xx(18:23)));

                yy = info.Attributes(30).Value;
                datetime_end = datenum( str2num(yy(1:4)), str2num(yy(6:7)), str2num(yy(9:10)), str2num(yy(12:13)), str2num(yy(15:16)), str2num(yy(18:23)));

                % Get the time separating scans. Actually, this isn't quite
                % right since scans are done in groups of ten so the times
                % for the start of each of the 10 scan lines is the same
                % but, for the purposes of this script, we will assume that
                % the scans are sequential in time separated by the time
                % below. 
                
                time_separating_scans = (datetime_end-datetime_start) * 24 * 60 * 60 / nscans;
                
                if ifilename == 1
                    sscan = scan_line_in_file(orbit_info.scan_line_start(iOrbit));
                    lscan = nscans - sscan + 1;
                    
                    % Get the start time for this orbit. This is the start
                    % time of this granule plus the time to get to the
                    % first scan line used for the orbit. 
                    
                    GlobalAttributes = ncinfo(fi);
                    time_coverage_start = ncreadatt(fi, '/', 'time_coverage_start');
                    
                    time_orbit_start = datetime_start + sscan * time_separating_scans;
                    
                elseif ifilename == length(file_list)
                    sscan = 1;
                    % Add one more line to facilitate bowtie fix.
                    %         lscan = scan_line_in_file(new_start_orbit_no(2)) + 1;
                    lscan = scan_line_in_file(orbit_info.scan_line_end(iOrbit)) + 1;
                else
                    sscan = 1;
                    lscan = nscans;
                end
                
                % OK, now read Lat, Lon, SST,...
                
                latitude = [latitude, single(ncread(fi, '/navigation_data/latitude', [1 sscan], [npixels lscan]))];
                longitude = [longitude, single(ncread(fi, '/navigation_data/longitude', [1 sscan], [npixels lscan]))];
                
                SST_In = [SST_In, single(ncread(fi, '/geophysical_data/sst', [1 sscan], [npixels lscan]))];
                qual_sst = [qual_sst, int8(ncread(fi, '/geophysical_data/qual_sst', [1 sscan], [npixels lscan]))];
                flags_sst = [flags_sst, int16(ncread(fi_meta, '/geophysical_data/flags_sst', [1 sscan], [npixels lscan]))];
                sstref = [sstref, single(ncread(fi_meta, '/geophysical_data/sstref', [1 sscan], [npixels lscan]))];
                
            end
        end
        
        % %         % Found at least one orbit with a scan of 10 detectors missing.
        % %         % They were set to nan, which griddata does not like. Sooo.... set
        % %         % latitudes and longitudes with nans to -9999.
        % %
        % %         nn = find(isnan(latitude) == 1);
        % %         latitude(nn) = -9999;
        % %         longitude(nn) = -9999;
        
        timing.time_to_build_orbit(iOrbit) = toc(start_time_to_build_this_orbit);
        
        if print_diagnostics
            disp(['*** Time to build this orbit: ' num2str( timing.time_to_build_orbit(iOrbit), 5) ' seconds.'])
        end
        
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
        
        timing.time_to_process_this_orbit(iOrbit) = toc(start_time_to_process_this_orbit);
        
        if print_diagnostics
            disp(['*** Time to process and save ' name_out_sst ': ', num2str( timing.time_to_process_this_orbit(iOrbit), 5) ' seconds.'])
        end
    else
        disp(['PC''s orbit # ' num2str(iOrbit) ' has already been processed. The output is in ' name_out_sst '. Going to the next orbit.'])
    end
end

disp(['*** Time for this run: ', num2str(toc(tic_build_start),5) ' seconds.'])

