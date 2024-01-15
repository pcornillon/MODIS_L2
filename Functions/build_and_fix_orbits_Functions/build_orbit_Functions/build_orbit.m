function [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start, granule_start_time_guess] = build_orbit( granule_start_time_guess)
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
%   granule_start_time_guess - estimated start time for the next granule.
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
%   latitude - the array for the latitudes in this orbit.
%   longitude - the array for the longitude in this orbit.
%   SST_In - the array for the input SST values in this orbit.
%   qual_sst - the array for the SST quality fields in this orbit.
%   flags_sst - the array for the SST flags in this orbit.
%   sstref - the array for the reference SST field in this orbit.
%   start_time - matlab time of first scan line of the next orbit.
%   scan_seconds_from_start - seconds since start of orbit to this granule.
%   granule_start_time_guess - estimated start time for the next granule.
%

% globals for the run as a whole.

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory_local output_file_directory_remote
global print_diagnostics print_times debug
global npixels

% globals for build_orbit part.

global save_just_the_facts amazon_s3_run
global formatOut
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length secs_per_granule_minus_10 orbit_duration
global index_of_NASA_orbit_change possible_num_scan_lines_skip
global sltimes_avg nlat_orbit nlat_avg orbit_length
global latlim
global sst_range sst_range_grid_size

global oinfo iOrbit iGranule iProblem problem_list 
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t
global Matlab_start_time Matlab_end_time 

% globals used in the other major functions of build_and_fix_orbits.

global med_op

global mem_count mem_orbit_count mem_print print_dbStack mem_struct

global determine_fn_size

if determine_fn_size; get_job_and_var_mem; end

status = 0;

% Initialize return variables to simple nans; will return to calling
% program when the start of the next orbit is found.

latitude = single(nan);
longitude = single(nan);
SST_In = single(nan);
qual_sst = int8(nan);
flags_sst = int16(nan);
sstref = single(nan);

scan_seconds_from_start = 0;% Initialize parameters

iGranule = 1;

% Are we starting an orbit without having read a metadata granule for it?
% If so, read the next metadata granule and begin populating this orbit. 
% This could happen if the previous orbit ended with an empty granule; i.e., 
% the loop over the orbit ended because the granule start time exceeded the
% end time of the orbit determined when the orbit first started.

if length(oinfo) < iOrbit

    if print_diagnostics
        fprintf('*** Don''t think that we should ever get here: [iOrbit, iGranule]=[%i, %i]. Granule: %s. Time: %s.\n', iOrbit, iGranule, oinfo(iOrbit).name, datestr(granule_start_time_guess))
    end

    status = populate_problem_list( 261, ['*** Don''t think that we should ever get here: [iOrbit, iGranule]=[' num2str(iOrbit) ', ' num2str(iGranule) ']. Orbit name: ' oinfo(iOrbit).name '.'], granule_start_time_guess);

    iGranule = 0;
    
    [status, ~, granule_start_time_guess] = find_next_granule_with_data( granule_start_time_guess);
    
    % Return if end of run.
    
    if (status == 201) | (status == 231) | (status > 900)
        fprintf('End of run.\n')
        return
    end
end

% Is there an orbit name for this orbit. If not, very bad, quit.

if isempty(oinfo(iOrbit).name)
    if print_diagnostics
        fprintf('No orbit name for iOrbit = %i.\n', iOrbit)
    end
    
    status = populate_problem_list( 241, ['No orbit name for orbit ' num2str(iOrbit)], granule_start_time_guess);
    return
end

%% Skip this orbit if it exist already.

% Is there an orbit name for this orbit. If not, very bad, quit. Note that
% the extension .nc4 is stripped off the name so that if either a .nc4 or
% .dummy file exists we're good.

already_processed = 0;

if (exist(oinfo(iOrbit).name) == 2) | (exist(strrep(oinfo(iOrbit).name, '.nc4', '.dummy')) == 2)
    
    already_processed = 1;
    
    fprintf('--- Have already processed %s. Going to the next orbit. \n', strrep(oinfo(iOrbit).name, '.nc4', ''))

    % Skip the next 85 minutes of granules to save time; don't have to read them.
    
    granule_start_time_guess = granule_start_time_guess + 85 / (60 * 24);

    % Keep skipping orbits until a missing one is found. 
    
    found_one = 1;
    while found_one

        % When probing for the next orbit, need to be careful that the
        % year and/or the month has not changed since the previous orbit.

        [status, temp_time] = extract_datetime_from_filename(oinfo(iOrbit).name);
        [YR, MN, DY, ~, ~, ~] = datevec(temp_time + orbit_duration / secs_per_day);

        exist_list = dir( [output_file_directory_local return_a_string( 4, YR) '/' return_a_string( 2, MN) '/' ...
            'AQUA_MODIS_orbit_' return_a_string( 6, oinfo(iOrbit).orbit_number + 1) '*']);
        
        if ~isempty(exist_list)

            % If this orbit is present, reset all of the oinfo values that
            % we can extract from the title of the next orbit. Then skip
            % the duration of a typical orbit. The difference between
            % skipping 85 minutes for the first processed orbit found and
            % this one is that for the first one we had to make sure that
            % the granule was not near the end of an orbit. Here we are
            % adding the typical duration to this time; i.e., we have
            % already taken this slop into acount with the first orbit
            % skipped. If the orbits are being copied to a remote location
            % after writing locally, the name found may end in .dummy.
            % Replace this with .nc4 just in case.
            
            oinfo(iOrbit).name = strrep( [exist_list(1).folder '/' exist_list(1).name], '.dummy', '.nc4');
            [status, oinfo(iOrbit).start_time] = extract_datetime_from_filename(oinfo(iOrbit).name);

            oinfo(iOrbit).end_time = oinfo(iOrbit).start_time + orbit_duration / secs_per_day;
            oinfo(iOrbit).orbit_number = oinfo(iOrbit).orbit_number + 1;

            granule_start_time_guess = granule_start_time_guess + orbit_duration / secs_per_day;

            if granule_start_time_guess > Matlab_end_time
                if print_diagnostics
                    fprintf('*** Have reached the end of run (%s).\n', datestr(Matlab_end_time))
                end

                status = populate_problem_list( 902, ['*** Have reached the end of the run: ' datestr(Matlab_end_time)], granule_start_time_guess);

                return
            end

            fprintf('--- Have already processed %s. Going to the next orbit. \n', strrep(oinfo(iOrbit).name, '.nc4', ''))
        else
            % % % % Step back 5 minutes from the end of the last run and search for next crossing.
            % % % 
            % % % granule_start_time_guess = oinfo(iOrbit).end_time - 5 * 60 / secs_per_day;
            
            % Set granule_start_time_guess to the nearest multiple of 5
            % minutes preceeding oinfo(iOrbit).end_time. Remember that the
            % end of the previous orbit is 100 scan lines past the nadir
            % descending crossing of the satellie.  

            date_vec = datevec(oinfo(iOrbit).end_time - 100 * secs_per_scan_line);
            date_vec(5) = date_vec(5) - rem(date_vec(5),5);
            date_vec(6) = 0;
            granule_start_time_guess = datenum(date_vec);

            iGranule = 0;
            
            found_one = 0;
        end
    end        
    
    start_line_index = [];

    while granule_start_time_guess <= (oinfo(iOrbit).end_time + 60 / secs_per_day)
        
        [status, granule_start_time_guess] = find_next_granule_with_data( granule_start_time_guess);
        
        % Return if end of run.
        
        if (status == 201) | (status == 231) | (status > 900)
            fprintf('Problem building this orbit, return to builds_and_fix_orbit.\n')
            return
        end
        
        if ~isempty(start_line_index)
            % If we get here, the search has found an orbit with a
            % descending 78S crossing. But this was an orbit that was
            % already processed so we need to decrement iOrbit, replacing
            % the current values of oinfo(iOrbit) with those of
            % oinfo(iOrbit+1), which was created in the above search. Note
            % that we also have to save the metadata from the last granule
            % of the current orbit, which will be the first granule on the
            % next orbit and put it in that place.

            metadata = oinfo(iOrbit).ginfo(end).metadata_global_attrib;

            oinfo(iOrbit) = oinfo(iOrbit+1);
            oinfo(iOrbit).ginfo(1).metadata_global_attrib = metadata;

            oinfo(iOrbit+1) = [];
            iGranule = 1;

            break
        end
    end
end

%% Now build this orbit from its granules; a granule has been found with the start of this orbit.

fprintf('__________________________________________________\n\nWorking on orbit #%i: %s.\n\n', iOrbit, oinfo(iOrbit).name)

start_time_to_build_this_orbit = tic;

% Initialize orbit arrays.

latitude = single(nan(1354,orbit_length));
longitude = single(nan(1354,orbit_length));
SST_In = single(nan(1354,orbit_length));
qual_sst = int8(nan(1354,orbit_length));
flags_sst = int16(nan(1354,orbit_length));
sstref = single(nan(1354,orbit_length));

scan_seconds_from_start = single(nan(1,orbit_length));

granule_start_time_guess_save = granule_start_time_guess;

data_granule = oinfo(iOrbit).ginfo(iGranule).data_name;
metadata_granule = oinfo(iOrbit).ginfo(iGranule).metadata_name;

% Populate the orbit with data from this granule.

[status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = add_granule_data_to_orbit( 'current', data_granule, metadata_granule, latitude, longitude, ...
    SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);

if status ~= 0
    return
end

% In the rare--I hope--event when the first granule found in a new orbit
% also contains the start of the next orbit, i.e., .pirate_osscan is not
% empty, pirate data from the next orbit and return.

if isfield(oinfo(iOrbit).ginfo(iGranule), 'pirate_osscan')
    if print_diagnostics
        fprintf('Pirating data on the first call for orbit #%i, granule: %s\n', oinfo(iOrbit).orbit_number, oinfo(iOrbit).ginfo(iGranule).metadata_name)
    end
    
    [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
        = pirate_data( latitude, longitude, SST_In, qual_sst, flags_sst, sstref, ...
        scan_seconds_from_start, granule_start_time_guess);
end

%% Loop over the remainder of granules in this orbit.
% Added 1 minute to the end time to avoid an orbit being ended because it
% is very close to the end time or there were 2030 scans in the last
% granule instead of 2040. (I'm not sure if the last thing is really a
% problem.)

while granule_start_time_guess <= (oinfo(iOrbit).end_time + 60 / secs_per_day)
    % Get metadata information for the next granule-g... increments
    % granule_start_time... by 5 minutes.
    
    [status, granule_start_time_guess] = find_next_granule_with_data( granule_start_time_guess);
    
    % Status returned from find_next_granule_with_data is either 0 - all OK,
    % 201 - granule start time exceeded the end of orbit time without
    % finding a granule with a start time in it or 901 end of run. If
    % status = 201 or 901 break out of this loop.

    if (status == 201) | (status == 231) | (status > 900)
        oinfo(iOrbit).time_to_build_orbit = toc(start_time_to_build_this_orbit);

        if print_times
            fprintf('   Time to build this orbit: %6.1f seconds. Current date/time: %s\n', oinfo(iOrbit).time_to_build_orbit, datestr(now))
        end

        return
        
    else
        
        % Populate the orbit with data from this granule.
        
        data_granule = oinfo(iOrbit).ginfo(iGranule).data_name;
        metadata_granule = oinfo(iOrbit).ginfo(iGranule).metadata_name;
        
        [ status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
            = add_granule_data_to_orbit( 'current', data_granule, metadata_granule, ...
            latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);
        
        % And the data to pirate data if we need to do this.
        
        if isfield(oinfo(iOrbit).ginfo(iGranule), 'pirate_osscan')
            [ status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
                = pirate_data( latitude, longitude, SST_In, qual_sst, flags_sst, sstref, ...
                scan_seconds_from_start, granule_start_time_guess);
        end
    end

    % When the granule start time is very near the estimated end time of
    % the orbit this script gets a bit confused and sometimes keeps reading
    % granules after a new orbit has been found. This results in the
    % program bombing. The next lines deal with this. 
    
    if ~isempty(start_line_index)
        break
    end
end

oinfo(iOrbit).time_to_build_orbit = toc(start_time_to_build_this_orbit);

if print_times
    fprintf('   Time to build this orbit: %6.1f seconds. Current date/time: %s\n', oinfo(iOrbit).time_to_build_orbit, datestr(now))
end
