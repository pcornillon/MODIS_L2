function [status, metadata_file_list, data_file_list, indices, granule_start_time_guess] = find_next_granule_with_data( granule_start_time_guess)
% find_next_granule_with_data - step through 5 minute segments looking for next granule with data - PCC
%
% This function will build the approximate granule name for corresponding
% to the time passed in and then do a dir function on it to see if there is
% a granule there. If so, it will ask if the granule is an end-of-orbit
% granule. If it is, it will get osscan, oescan... for the locations of
% scanlines in the current orbit and the next orbit. If not, it will get
% osscan, oescan,... for the location of the scanlines in the current
% orbit. In either case, it will return with a status of 0.
%
% If a granule was not found, it will increment the granule time by 5
% minutes. If the incremented time is past the end time for this run, it
% will return with a status of 100. If the incremented time is still in the
% range for this run, it will increment the granule time and...
%
% INPUT
%   granule_start_time_guess - the matlab_time of the granule to start with.
%
% OUTPUT
%   status  : 0 - OK
%           : 101 - No data granule corresponding the metadata granule - go
%             to next granule.
%           : 201 - estimated time past the end of the orbit - return.
%           : 901 - estimated time past the end of the run - return.
%      The following returned from calls to get_osscan_etc...
%           : 111 - Adjacent orbits but osscan calculations disagree. Will
%             use value based on end of previous granule and continue.
%           : 112 - Didn't skip either 1020, 1030, 1040 or 1050 scan lines.
%             Set the # of lines to skip to 0 and continued.
%           : 113 Calculated osscans do not agree. Will use the calculation
%             based on the canonical orbit and continue.
%           : 114 - (from ...with_sli) Length of orbit calculation does not
%               agree with mandated length, nominally 40,271. oescan and
%               gescan forced for an orbit of 40,271 and continued.
%           : 125 - (from ...NO_sli) Length of orbit calculation does not
%               agree with mandated length, nominally 40,271. oescan and
%               gescan forced for an orbit of 40,271 and continued.
%   metadata_file_list - list of granule metadata files found at time passed in.
%   data_file_list - list of granule data files found at time passed in.
%   indices - a structure with the discovered indices.
%   granule_start_time_guess - the matlab_time of the granule to start with. If scan
%    times are obtained for this granule, granule_start_time_guess will be set to the
%    first scan of the granule; otherwise the value passed in will be returned.
%

% Granule file names:
%
% Local data granule: ~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/combined/2010/AQUA_MODIS.20100619T052000.L2.SST.nc'
% Local metadata granule: ~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/2010/AQUA_MODIS_20100619T052000_L2_SST_OBPG_extras.nc4
%
% s3 data granule: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100619052000-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global Matlab_start_time Matlab_end_time
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length time_of_NASA_orbit_change
global print_diagnostics save_just_the_facts debug
global print_diagnostics save_just_the_facts debug
global amazon_s3_run
global formatOut

% Initialize return variables.

status = 0;
indices = [];

% Start of loop searching for next granule.

start_time = granule_start_time_guess;
metadata_file_list = [];

while 1==1
        
    % Is this time passed the end of the run.
    
    if granule_start_time_guess > Matlab_end_time
        if print_diagnostics
            fprintf('*** No start of an orbit in the specified range %s to %s.\n', datestr(start_time), datestr(Matlab_end_time))
        end
        
        status = populate_problem_list( 901, 'End of run');

        return
    end
    
    % Is this time passed the end time of the orbit? Only check if an orbit
    % already exists from which the time has been calculated; i.e., only if
    % oinfo exists. If it does but this is beyond the end of an orbit, then
    % it is old information so clear oinfo to allow the search for the next
    % granule to go on until either a granule is found or the end of the
    % run is reached. 
    
% % %     if ~isempty(oinfo(iOrbit))
    if length(oinfo) == iOrbit
        if granule_start_time_guess > oinfo(iOrbit).end_time
            if print_diagnostics
                fprintf('*** No start of an orbit in the specified range %s to %s.\n', datestr(start_time), datestr(oinfo(iOrbit).end_time))
            end
            
            status = populate_problem_list( 201, ['Granule past predicted end of orbit time: ' datestr(oinfo(iOrbit).end_time)]);

            oinfo(iOrbit) = [];
            
            if debug
                keyboard
            end
            
            return
        end
    end
    
    % Build the output filename for the next metadata and data granules
    % and do a directory listing on each.
    
    % If the dir request is the same for both amazon_s3 and local, I can
    % reduce the following down to just one line.
    
	metadata_file_list = dir( [metadata_directory datestr(granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS_' datestr(granule_start_time_guess, formatOut.yyyymmddThhmm) '*']);
    
    % Was a metadata file found at this time?
    
    if ~isempty(metadata_file_list)
                
        % Is the data granule for this time present? If so, get the range
        % of locations of scanlines in the orbit and the granule to use.
        % Otherwise, add to problem list and continue search for a data
        % granule; remember, a metadata granule was found so this should
        % not occur.
        
        if amazon_s3_run
            data_file_list = dir( [granules_directory datestr(granule_start_time_guess, formatOut.yyyy) '/' datestr(granule_start_time_guess, formatOut.yyyymmddhhmm) '*-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc']);
        else
            data_file_list = dir( [granules_directory datestr(granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS.' datestr(granule_start_time_guess, formatOut.yyyymmddThhmm) '*']);
        end
        
        if isempty(data_file_list)
            % Reset metadata_file_list to empty since no data granule
            % exists for this time, even though a metadata granule does,
            % flag and keep searching.
            
            metadata_file_list = [];
            
            fprintf('No data granule found for template: %s. Return.\n', ['/AQUA_MODIS.' datestr(granule_start_time_guess, formatOut.yyyymmddThhmm) '*'])
            
            status = populate_problem_list( 101, ['/AQUA_MODIS.' datestr(granule_start_time_guess, formatOut.yyyymmddThhmm) '*']);
        else
            data_temp_filename = [data_file_list(1).folder '/' data_file_list(1).name];
            metadata_temp_filename = [metadata_file_list(1).folder '/' metadata_file_list(1).name];
            
            % Get the metadata for this granule.
            
            [status, granule_start_time_guess] = get_granule_metadata( metadata_file_list, 1, granule_start_time_guess);
            
            % If status not equal to zero, either problems with start times
            % or 1st detector, not 1st detector in group of 10. Neither of
            % these should happen so we will assume that this granule is
            % bad and go to the next one. 
            
            if status == 0
                
                iGranule = iGranule + 1;
                
                % Populate oinfo for this granule for info. oinfo(iOrbit).name 
                % has not been defined yet but will be shortly using some
                % of these values. 

                oinfo(iOrbit).ginfo(iGranule).data_name = data_temp_filename;
                
                oinfo(iOrbit).ginfo(iGranule).metadata_name = metadata_temp_filename;
                oinfo(iOrbit).ginfo(iGranule).NASA_orbit_number = ncreadatt( oinfo(iOrbit).ginfo(iGranule).metadata_name,'/','orbit_number');
                
                oinfo(iOrbit).ginfo(iGranule).start_time = scan_line_times(1);
                oinfo(iOrbit).ginfo(iGranule).end_time = scan_line_times(end) + (secs_per_scan_line * 10) /  secs_per_day;
                
                oinfo(iOrbit).ginfo(iGranule).metadata_global_attrib = ncinfo(oinfo(iOrbit).ginfo(iGranule).metadata_name);
                
                oinfo(iOrbit).ginfo(iGranule).scans_in_this_granule = num_scan_lines_in_granule;
                                
                if isempty(start_line_index)
                    [~, indices] = get_osscan_etc_NO_sli;
                    
                    % If this is the first granule read for this orbit, it
                    % means that the previous orbit ended with a missing
                    % file so we need to get the output filename. To do
                    % this, we will find the start time of this orbit based
                    % on the latitude of the first scan line in this granule.
                    
                    if isempty(oinfo(iOrbit).name)
                        if print_diagnostics
                            fprintf('Need to determine the orbit number if the first granule in this orbit is mid-orbit. Am in find_next_granule_with_data.\n')
                        end
                        
                        status = generate_output_filename('no_sli');
                    end
                else
                    [~, indices] = get_osscan_etc_with_sli;
                        
                    status = generate_output_filename('sli');                    
                end                
                    
                % And now for scan line indices.
                
                oinfo(iOrbit).ginfo(iGranule).osscan = indices.current.osscan;
                oinfo(iOrbit).ginfo(iGranule).oescan = indices.current.oescan;
                
                oinfo(iOrbit).ginfo(iGranule).gsscan = indices.current.gsscan;
                oinfo(iOrbit).ginfo(iGranule).gescan = indices.current.gescan;
                
                if isfield(indices, 'pirate')
                    oinfo(iOrbit).ginfo(iGranule).pirate_osscan = indices.pirate.osscan;
                    oinfo(iOrbit).ginfo(iGranule).pirate_oescan = indices.pirate.oescan;
                    
                    oinfo(iOrbit).ginfo(iGranule).pirate_gsscan = indices.pirate.gsscan;
                    oinfo(iOrbit).ginfo(iGranule).pirate_gescan = indices.pirate.gescan;
                end
                
                if isfield(indices, 'next')
                    oinfo(iOrbit+1).ginfo(1).osscan = indices.next.osscan;
                    oinfo(iOrbit+1).ginfo(1).oescan = indices.next.oescan;
                    
                    oinfo(iOrbit+1).ginfo(1).gsscan = indices.next.gsscan;
                    oinfo(iOrbit+1).ginfo(1).gescan = indices.next.gescan;
                    
                    % Return here because the start of a new orbit has been
                    % found.
                    
                    return
                end
            end
        end
    end
end

