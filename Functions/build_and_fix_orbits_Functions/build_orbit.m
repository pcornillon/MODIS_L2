function [status, name_out_sst, problem_list, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, orbit_start_time] ...
    = build_orbit( problem_list, granules_directory, metadata_directory, output_file_directory, fi_metadata, start_line_index, granule_start_time, scan_line_times, ...
    num_scan_lines_in_granule)
% build_orbit - build the next unprocessed orbit from data granules - PCC
% 
% Starting with OBPG metadata file for a granule that includes the start of
% a new orbit--crosses latlim, nomally 78S as the satellite descends--build
% the file name for the orbit, check if it exists, if it does, search for
% the next granule that contains the start of an orbit, continuing until it
% finds one that has not been processed. Then populate lat, lon, SST_In,
% sstref and the flag arrays for the orbit checking along the way for the
% start of a new orbit or for a granule that is clearly beyond the end of
% the current orbit for cases where the granule with the start of the next
% orbit is missing.
%
% INPUT
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
%   granules_directory - the base directory for the input files.
%   metadata_directory - the base directory for the location of the
%   output_file_directory - directory into which the results will be written. 
%   fi_metadata - filename for granule at the start of an orbit.
%   start_line_index - the index in fi for the start of the orbit.
%   imatlab_time - the matlab_time of the granule to start with.
%   scan_line_times - a vector of matlab times for the last granule read in.
%   orbit_start_time - matlab time of first scan line in the orbit to be built.
%   num_scan_lines_in_granule - the number of scan lines in the granule
%    for which the nadir track crosses latlim.
%   orbit_info - structure with orbit information.
%
% OUTPUT
%   status  : 0 - OK
%           : 1 - couldn't find the data granule.
%           : 2 - didn't find number_of_lines global attribute.
%           : 3 - number of pixels global attribute not equal to 1354.
%           : 4 - number of scan lines global attribute not between 2020 and 2050.
%           : 5 - couldn't find the metadata file copied from OBPG data.
%           : 6 - 1st detector in data granule not 1st detector in group of 10. 
%           : 10 - missing granule.
%           : 11 - more than 2 metadata files for a given time. 
%           : 100 - No granule with the start of an orbit found in time range. 
%   name_out_sst - the fully qualified output filename.
%   problem_list - structure with data on problem granules.
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   orbit_start_time - matlab time of first scan line of the next orbit.
%   granule - structure function with information about granules that went 
%    into this orbit. Fields:
%       metadata_name - name of input granule
%       start_time - time (GMT) of start of granule.
%       end_time - time (GMT) of end of granul (actually should be very
%        close to the start time of the next orbit.
%       data_granule_name - filename for the data granule.
%       osscan - the scan number corresponding to the first scan in the
%        orbit from this granule. This may not be the first scan in the 
%        granule if this is a new orbit.
%       oescan - the scan number corresponding to the last scan in the orbit
%        from this granule. 
%       gsscan - the first scan number in this granule copied to the orbit.
%       gescan - the last scan number in this granule copied to the orbit.
%       status - the return status associated with this granule. 
%   orbit_info - updated structure wit orbit info.

global iOrbit orbit_info
global Matlab_end_time 
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global formatOutDateTime formatOutMonth formatOutYear
global print_diagnostics save_just_the_facts

% Initialize return variables.

latitude = single(nan);
longitude = single(nan);
SST_In = single(nan);
qual_sst = int8(nan);
flags_sst = int16(nan);
sstref = single(nan);

% Initialize parameters

check_attributes = 1;

acceptable_start_time = datenum(2002, 7, 1);
acceptable_end_time = datenum(2022, 12, 31);

% Formats used in building filenames.


% Build the output filename for this orbit and check that it hasn't
% already been processed. To build the filename, get the orbit number
% and the date/time when the satellite crossed latlim.

orbit_number = ncreadatt( fi_metadata,'/','orbit_number');

orbit_file_name = ['AQUA_MODIS_orbit_' return_a_string(orbit_number) '_' datestr(orbit_info(iOrbit).orbit_start_time, formatOutDateTime) '_L2_SST'];
orbit_info(iOrbit).name = orbit_file_name;

name_out_sst = [output_file_directory datestr(orbit_info(iOrbit).orbit_start_time, formatOutYear) '/' ...
    datestr(orbit_info(iOrbit).orbit_start_time, formatOutMonth) '/' orbit_file_name '.nc4'];

%% Skip this orbit if it exist already.

if exist(name_out_sst) == 2
    
    fprintf('Have already processed %s. Going to the next orbit. \n', name_out_sst)
    
    % Start by incrementing granule_start_time so that we don't just find
    % the same granule start time as for the previous orbit. 
    
    granule_start_time = granule_start_time + 5 /(24 * 60);
    
    % Now search for the start of a new orbit.
    
    [status, fi_metadata, start_line_index, granule_start_time, orbit_scan_line_times, orbit_start_time, num_scan_lines_in_granule] ...
        = find_start_of_orbit( metadata_directory, granule_start_time);
    
    if status ~= 0
        fprintf('*** Problem with metadata file %s at date/time %s or no start of an orbit in the specified range %s to %s. Aborting.\n', ...
            fi_metadata, datestr(granule_start_time), datestr(Matlab_start_time), datestr(Matlab_end_time))
        return
    end
    
    % Load the scan line times for the first granule on this orbit.
    
    scan_line_times = orbit_scan_line_times(end,1:num_scan_lines_in_granule);
    
    % See comment re use of num_scan_lines_in_granule above in 1st call
    % to find_start_of_orbit.
    
    status = 200;
    
    return
    
end

%% Now build this orbit from its granules; a granule has been found with the start of this orbit.

fprintf('Working on orbit #%i: %s.\n', iOrbit, name_out_sst)

start_time_to_build_this_orbit = tic;

iGranule = 1;

clear granule

orbit_info(iOrbit).granule_info(1).metadata_name = fi_metadata;
orbit_info(iOrbit).granule_info(1).metadata_global_attrib = ncinfo(fi_metadata);

orbit_info(iOrbit).granule_info(1).start_time = scan_line_times(1) * secs_per_day;

% Add the time for 10 scan lines to the time of the last scan line. That's
% because we want the time at the end of the last scan and, since the come
% in groups of 10, the time of each of the last 10 scans will be the same
% corresponding to the start of the mirror rotation for this group of 10;
% we want the time when the next group of 10 starts.

orbit_info(iOrbit).granule_info(1).end_time = scan_line_times(end) * secs_per_day + secs_per_scan_line * 10;

% Initialize orbit arrays.

latitude = single(nan(1354,40271));
longitude = single(nan(1354,40271));
SST_In = single(nan(1354,40271));
qual_sst = int8(nan(1354,40271));
flags_sst = int16(nan(1354,40271));
sstref = single(nan(1354,40271));

granule_start_time_save = granule_start_time;

% Orbit start and end numbers; i.e., the orbit variables will be
% populated from osscan through oescan.

orbit_info(iOrbit).granule_info(1).osscan = 1;
orbit_info(iOrbit).granule_info(1).oescan = num_scan_lines_in_granule - start_line_index + 1;

% Granule start and end numbers; i.e., the input arrays will be read
% from gsscan through gescan.

orbit_info(iOrbit).granule_info(1).gsscan = start_line_index;
orbit_info(iOrbit).granule_info(1).gescan = num_scan_lines_in_granule;

% Read the data for the first granule in this orbit.

[status, orbit_info(iOrbit).granule_info(1).data_granule_name, problem_list, latitude, longitude, SST_In, qual_sst, flags_sst, sstref] ...
    = get_granule_data( fi_metadata, granules_directory, problem_list, check_attributes, [orbit_info(iOrbit).granule_info(1).osscan orbit_info(iOrbit).granule_info(1).oescan], ...
    [orbit_info(iOrbit).granule_info(1).gsscan orbit_info(iOrbit).granule_info(1).gescan], latitude, longitude, SST_In, qual_sst, flags_sst, sstref);

orbit_info(iOrbit).granule_info(1).status = status;

% Increment the granule start date/time by 5 minutes and begin looping over
% granules to populate the next orbit.

granule_start_time = granule_start_time + 5 / (24 * 60);

%% Loop over granules in the orbit.

while granule_start_time <= Matlab_end_time
    
    % Get metadata information for the next granule.
    
    [status, fi_metadata, start_line_index, scan_line_times, missing_granule, num_scan_lines_in_granule, granule_start_time] ...
        = build_metadata_filename( 1, metadata_directory, granule_start_time);
    
    orbit_start_time = scan_line_times(start_line_index);
    
    if status ~= 0
        fprintf('Problem for granule on orbit #%i at time %s; status returned as %i. Going to next granule.\n', iOrbit, datestr(iMatlab_time), status)
    else
        
        iGranule = iGranule + 1;
        orbit_info(iOrbit).granule_info(iGranule).metadata_name = fi_metadata;
        orbit_info(iOrbit).granule_info(iGranule).metadata_global_attrib = ncinfo(fi_metadata);
        
        orbit_info(iOrbit).granule_info(iGranule).start_time = scan_line_times(1) * secs_per_day;
        orbit_info(iOrbit).granule_info(iGranule).end_time = scan_line_times(end) * secs_per_day + secs_per_scan_line * 10;
        
        % Get lines to skip for missing granules. Will, hopefully, be 0
        % if no granules skipped.
        
        lines_to_skip = floor( abs((orbit_info(iOrbit).granule_info(iGranule).start_time - orbit_info(iOrbit).granule_info(end-1).end_time) + 0.05) / secs_per_scan_line);
        
        % Check that the number of lines to skip is a multiple of 10. If not, force it to be.
        
        if mod(lines_to_skip, 10) ~= 0
            fprintf('The number of lines to skip, %i, is not a multiple of 10 for granule %s. Forcing it to 10.\n', lines_to_skip, fi_metadata)
            lines_to_skip = round(lines_to_skip / 10) * 10;
        end
        
        orbit_info(iOrbit).granule_info(iGranule).osscan = orbit_info(iOrbit).granule_info(iGranule-1).oescan + 1 + lines_to_skip;
        
        orbit_info(iOrbit).granule_info(iGranule).gsscan = 1;
                 
        pirate_from_next_granule = 0;
       
        if isempty(start_line_index)

            % Didn't find the start of a new orbit but the granule for
            % the start of the next orbit may be missing so, check the
            % to see if the end was skipped. If so, break out of this while
            % loop over granules for this orbit, i.e., assume that the orbit
            % has ended and process what we have for this orbit. Do not use 
            % the scan lines in this granule. When done processing, the 
            % script will start a new orbit, estimating the number of scan 
            % lines into that orbit that correspond to this granule.
            
            if orbit_info(iOrbit).granule_info(iGranule).start_time > (orbit_info(iOrbit).granule_info(1).start_time + secs_per_orbit + 300)
                break
            end
            
            orbit_info(iOrbit).granule_info(iGranule).oescan = orbit_info(iOrbit).granule_info(iGranule).osscan + num_scan_lines_in_granule - 1;
            
            % Make sure that this granule does not add more scan lines than
            % the maximum allowed, orbit_length. This should not happen
            % since this granule does not have the start of an orbit in it.

            if orbit_info(iOrbit).granule_info(iGranule).oescan > orbit_length
                status = 110;
                return
            end
            
            orbit_info(iOrbit).granule_info(iGranule).gescan = num_scan_lines_in_granule;
            
        else
            
            % Save the start time for the next orbit. This will be passed
            % back to the main program.
            
            orbit_start_time = scan_line_times(start_line_index);

            % Determine how many scan lines are needed to bring the length
            % of this orbit to orbit_length, nominally 40271 scan lines.
            % This should result in about 100 lines of overlap with the
            % next orbit--it varies from orbit to orbit because some orbits
            % (latlim to latlim) are 40,160 and some are 40,170. Plus we
            % want 1 extra scan line at the end to allow for the bow-tie
            % correction. If the number of scan lines remaining to be
            % filled exceed the number of scan lines in this granule, 
            % default to reading the entire granule and set a flag to tell 
            % the function to get the remaining lines to complete the orbit
            % from the next granule.
            
            orbit_info(iOrbit).granule_info(iGranule).oescan = orbit_info(iOrbit).granule_info(iGranule).osscan + start_line_index + 100 - 2;
            
            if (orbit_length + 1 - orbit_info(iOrbit).granule_info(iGranule).osscan) > num_scan_lines_in_granule
                orbit_info(iOrbit).granule_info(iGranule).oescan = orbit_info(iOrbit).granule_info(iGranule).osscan + num_scan_lines_in_granule - 1;
                
                orbit_info(iOrbit).granule_info(iGranule).gescan = num_scan_lines_in_granule;
                
                pirate_from_next_granule = 1;
            else
                orbit_info(iOrbit).granule_info(iGranule).oescan = orbit_length;
                
                orbit_info(iOrbit).granule_info(iGranule).gescan = orbit_info(iOrbit).granule_info(iGranule).oescan - orbit_info(iOrbit).granule_info(iGranule).osscan + 1;
            end
        end
        
        % Read the data for the first granule in this orbit.
        
        [status, orbit_info(iOrbit).granule_info(iGranule).data_granule_name, problem_list, latitude, longitude, SST_In, qual_sst, flags_sst, sstref] ...
            = get_granule_data( fi_metadata, granules_directory, problem_list, check_attributes, ...
            [orbit_info(iOrbit).granule_info(iGranule).osscan    orbit_info(iOrbit).granule_info(iGranule).oescan], ...
            [orbit_info(iOrbit).granule_info(iGranule).gsscan    orbit_info(iOrbit).granule_info(iGranule).gescan], ...
            latitude, longitude, SST_In, qual_sst, flags_sst, sstref);
        
        orbit_info(iOrbit).granule_info(iGranule).status = status;
        
        % If need more scans to complete this orbit, get them from the next
        % granule. Be careful not to clobber the variables from this
        % granule as they will be needed to start the next orbit.
        
        if pirate_from_next_granule
            
            [statusT, fi_metadataT, start_line_indexT, scan_line_timesT, missing_granuleT, num_scan_lines_in_granuleT, granule_start_timeT] ...
                = build_metadata_filename( 1, metadata_directory, iMatlab_time + 5 / (24 * 60));
            
            iGranule = iGranule + 1;
            
            orbit_info(iOrbit).granule_info(iGranule).metadata_name = fi_metadata;
            
            orbit_info(iOrbit).granule_info(iGranule).start_time = scan_line_timesT(1) * secs_per_day;
            orbit_info(iOrbit).granule_info(iGranule).end_time = scan_line_timesT(end) * secs_per_day + secs_per_scan_line * 10;

            lines_to_skip = floor( abs((granule_start_timeT * secs_per_day - orbit_info(iOrbit).granule_info(iGranule).end_time) + 0.05) / secs_per_scan_line);
            
            % Done building this orbit if the next granule is missing, go to
            % processing. Otherwise read data from next granule into this orbit.
            
            if (lines_to_skip > 11) | statusT~=0
                break
            else
                orbit_info(iOrbit).granule_info(iGranule).osscan = orbit_info(iOrbit).granule_info(iGranule-1).oescan + 1;
                orbit_info(iOrbit).granule_info(iGranule).oescan = orbit_length;
                
                orbit_info(iOrbit).granule_info(iGranule).gsscan = 1;
                orbit_info(iOrbit).granule_info(iGranule).gescan = orbit_info(iOrbit).granule_info(iGranule).oescan - orbit_info(iOrbit).granule_info(iGranule).osscan + 1;
                
                [status, ~, ~, latitude, longitude, SST_In, qual_sst, flags_sst, sstref] ...
                    = get_granule_data( fi_metadataT, granules_directory, problem_list, check_attributes, ...
                    [orbit_info(iOrbit).granule_info(iGranule).oescan+1    orbit_length], ...
                    [1    orbit_length+1-orbit_info(iOrbit).granule_info(iGranule).oescan], ...
                    latitude, longitude, SST_In, qual_sst, flags_sst, sstref);
                break
            end
        end
        
        % If this granule corresponds to the start of a new orbit break out
        % of this while loop and process this orbit.
        
        if ~isempty(start_line_index)
            break
        end
        
        % Increment start time.
        
        granule_start_time = granule_start_time + 5 / (24 * 60);
    end
end

orbit_info(iOrbit).time_to_build_orbit = toc(start_time_to_build_this_orbit);

if print_diagnostics
    disp(['Time to build this orbit: ' num2str( orbit_info(iOrbit).time_to_build_orbit, 5) ' seconds.'])
end


