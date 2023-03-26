function [status, granule_start_time_guess, metadata_file_list, data_file_list, indices] = find_next_granule_with_data( metadata_directory, granules_directory, granule_start_time_guess)
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
%   metadata_directory - the directory with the OBPG metadata files.
%   granules_directory - base directory for the granule data.
%   granule_start_time_guess - the matlab_time of the granule to start with.
%
% OUTPUT
%   status  : 0 - OK
%           : 6 - 1st detector in data granule not 1st detector in group of 10.
%           : 10 - missing granule.
%           : 11 - more than 2 metadata files for a given time.
%    requested.
%   granule_start_time_guess - the matlab_time of the granule to start with. If scan
%    times are obtained for this granule, granule_start_time_guess will be set to the
%    first scan of the granule; otherwise the value passed in will be returned.
%   metadata_file_list - list of granule metadata files found at time passed in.
%   data_file_list - list of granule data files found at time passed in.
%   indices - a structure with the discovered indices.
%

% Granule file names:
%
% Local data granule: ~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/combined/2010/AQUA_MODIS.20100619T052000.L2.SST.nc'
% Local metadata granule: ~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/2010/AQUA_MODIS_20100619T052000_L2_SST_OBPG_extras.nc4
%
% s3 data granule: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100619052000-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule sltimes_avg nlat_avg
global Matlab_start_time Matlab_end_time
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global print_diagnostics save_just_the_facts
global amazon_s3_run
global formatOut

% Initialize return variables.

indices = [];

% Start of loop searching for next granule.

metadata_file_list = [];

if isempty(metadata_file_list)
    
    granule_start_time_guess = granule_start_time_guess + 5 /(24 * 60);
    
    % Is this time passed the end of the run.
    
    if granule_start_time_guess > Matlab_end_time
        status = 999;
        return
    end
    
    % Is this time passed the end time of the orbit?
    
    if granule_start_time_guess > oinfo(iOrbit).end_time
        status = 201;
        return
    end
    
    % Build the approximate filename for the next metadata and data granules
    % and do a directory listing on each.
    
    % If the dir request is the same for both amazon_s3 and local, I can
    % reduce the following down to just one line.
    
    if amazon_s3_run
        % Here for s3. May need to fix this; not sure I will have combined
        % in the name. Probably should set up to search for data or
        % metadata file as we did for the not-s3 run.
        
        metadata_file_list = dir( [metadata_directory datestr(granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS_' datestr(granule_start_time_guess, formatOut.yyyymmddThhmm) '*']);
    else
        metadata_file_list = dir( [metadata_directory datestr(granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS_' datestr(granule_start_time_guess, formatOut.yyyymmddThhmm) '*']);
    end
else
    
    % Is the data granule for this time present? If so, get the range
    % of locations of scanlines in the orbit and the granule to use.
    % Otherwise, add to problem list and continue search for a data
    % granule; remember, a metadata granule was found so this should
    % not occur.
    
    if amazon_s3_run
        % Here for s3. May need to fix this; not sure I will have combined
        % in the name. Probably should set up to search for data or
        % metadata file as we did for the not-s3 run.
        
% s3 data granule: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100619052000-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc
        data_file_list = dir( [granules_directory datestr(granule_start_time_guess, formatOut.yyyy) '/' datestr(granule_start_time_guess, formatOut.yyyymmddhhmm) '*-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc']);
    else
        data_file_list = dir( [granules_directory datestr(granule_start_time_guess, formatOut.yyyy) '/AQUA_MODIS.' datestr(granule_start_time_guess, formatOut.yyyymmddThhmm) '*']);
    end
    
    if isempty(data_file_list)
        % Reset metadata_file_list to empty since no data granule
        % exists for this time, even though a metadata granule does.
        
        metadata_file_list = [];
        
        fprintf('No data granule corresponding the metadata granule %s. Flagging to skip this granule and return.\n', oinfo(iOrbit).ginfo(iGranle).metadata_granule_name)
        
        status = populate_problem_list( 151, oinfo(iOrbit).ginfo(iGranle).metadata_granule_name);
    else        
        % Get the metadata for this granule.
        
        [status, granule_start_time_guess] = get_granule_metadata( metadata_file_list, 1, granule_start_time_guess);
        
        % If status not equal to zero, do not use this granule; i.e., look
        % for next granule with data; do not return.
        
        if status == 0
            if isempty(start_line_index)
                [indices] = get_osscan_etc_NO_sli( orbit_status);
            else
                [indices] = get_osscan_etc_with_sli( orbit_status);
            end
            
            return
        end
    end
end

