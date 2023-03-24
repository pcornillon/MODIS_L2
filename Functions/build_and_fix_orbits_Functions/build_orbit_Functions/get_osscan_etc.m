function [indices] = get_osscan_etc( orbit_status)
% get_osscan_etc - determine the starting and ending indices for orbit and granule data - PCC
%
% The function will get the starting and ending locations of scanlines in 
% the granule most recently read to be copied to the current orbit. It will
% also get the location at which these scanlines are to be written in the
% current orbit.
%
% The function should be called after the end of an orbit has been found
% either be because granule_time, the time of the start of the granule for
% which the metadata was just read is after the end time of the current
% orbit of a start of orbit has been found in the granule just read. 
%
% The function will calculate the starting and ending indices for the data
% from the current granule in the current orbit and in the next orbit. It
% will also determine whether or not data is needed from the next granule
% to complete the current orbit. If so, it will determine the start and end
% indices for that orbit. It will also determine the corresponding
% locations from which to copy the data in the current granule.
%
% INPUT
%   orbit_status - 'new_orbit' to start an orbit from scratch, 'continue_orbit',
%    to get the indices to complete the current orbit and beginning
%    building the next one.
% OUTPUT
%   indices - a structure with the discovered indices.
%

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global Matlab_start_time Matlab_end_time
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global print_diagnostics

% This case is the simplest, scanlines from the current granule up to the
% start of the next orbit plus a 100 scanline buffer will be copied to
% current orbit. And, the relevant information will be generated for the
% remainder of the current granule that is to be written to the start of
% the next orbit.

indices.case = 1;

if strcmp(orbit_status, 'continue_orbit')
    
    % Get lines to skip for missing granules. Will, hopefully, be 0 if no granules skipped.
    
    oinfo(iOrbit).ginfo(iGranule).start_time = scan_line_times(1) * secs_per_day;
    oinfo(iOrbit).ginfo(iGranule).end_time = scan_line_times(end) * secs_per_day + secs_per_scan_line * 10;
    
    lines_to_skip = floor( abs((oinfo(iOrbit).ginfo(iGranule).start_time - oinfo(iOrbit).ginfo(iGranule-1).end_time) + 0.05) / secs_per_scan_line);
    
    % The lines to skip should be either 1020, 1030, 1040 or 1050 -- I
    % think, so, if less than 1000, set to zero and add to problem_list.
    
    if isempty(lines_to_skip == [1:39]'*[1020:10:1050])
        fprint('Wanted to skip %i lines but the only permissible values are multiles of 1020, 1030, 1040 or 1050. Setting lines to skip to 0.\n', lines_to_skip)
        lines_to_skip = 0;
        
        status = populate_problem_list( 60, []);
    end
    
    % Add 101 to osscan + sli to get 100 scanline overlap of this orbit
    % with the next one plus an additional line, hence 101, to allow
    % for the scanline correction. Also, gescan is sli-2 since sli is
    % the index of the start line for the next orbit so, instead of
    % sli-1 need an extra -1.
    
    indices.current.osscan = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1 + lines_to_skip;
    indices.current.oescan = indices.current.osscan + (start_line_index - 2) + 101;
    
    indices.current.gsscan = 1;
    indices.current.gescan = start_line_index - 1;
    
    if indices.current.oescan ~= orbit_length
        fprintf('Calculated end of orbit is %i, which does no agree with the mandated orbit length, nominally 40,271\n', indices.current.oescan, orbit_length)
        indices.current.oescan = orbit_length;
        indices.current.gescan = indices.current.oescan - indices.current.osscan + 1;
        
        status = populated_problem_list( 61, oinfo(iOrbit).ginfo(iGranule));
    end
    
    % Determine how many scan lines are needed to bring the length of this
    % orbit to orbit_length, nominally 40,271 scan lines. This should
    % result in about 100 lines of overlap with the next orbit--it varies
    % from orbit to orbit because some orbits are 40,160 and some are
    % 40,170. Plus we want 1 extra scan line at the end to allow for the
    % bow-tie correction. If the number of scan lines remaining to be
    % filled exceed the number of scan lines in this granule, default to
    % reading the entire granule and set a flag to tell the function to get
    % the remaining lines to complete the orbit from the next granule.
    
    if (oescan + 1 - osscan) > num_scan_lines_in_granule
        
        % This case is arises if the additional 101 scanlines need to
        % complete the current orbit result in more scanlines being
        % required from the current granule than are available in it. In
        % this case, scanlines will need to be pirated from the next
        % granule, if it exists. This section gets the starting and ending
        % scanlines to be filled from the next granule as well as the
        % starting and ending scanlines to use from that granule.

        indices.case = 2;
        
        indices.current.oescan = indices.current.osscan + num_scan_lines_in_granule - 1;
        indices.current.gescan = num_scan_lines_in_granule;
        
        % The .pirate. group is for the scanlines to be read from the
        % next orbit to complete this orbit since adding 100 scanlines
        % resulting in going past the end of this granule (with the
        % start of an orbit in it).
        
        indices.pirate.osscan = indices.oescan + 1;
        indices.pirate.oescan = orbit_length;
        indices.pirate.gsscan = 1;
        indices.pirate.gescan = orbit_length - indices.pirate.osscan + 1;
    end
end

indices.next.osscan = 1;
indices.next.oescan = num_scan_lines_in_granule - start_line_index + 1;
indices.next.gsscan = start_line_index;
indices.next.gescan = num_scan_lines_in_granule;

% Save the start time for the next orbit. This will be passed
% back to the main program.

oinfo(iOrbit+1).orbit_start_time = scan_line_times(start_line_index);
oinfo(iOrbit+1).ginfo(1).metadata_name = oinfo(iOrbit).ginfo(iGranule).metadata_name;

% % % % Read the data for the next granule in this orbit.
% % % 
% % % [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
% % %     = add_granule_data_to_orbit( granules_directory, check_attributes, ...
% % %     latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);
% % % 
% % % oinfo(iOrbit).ginfo(iGranule).status = status;
% % % 
% % % % If need more scans to complete this orbit, get them from the next
% % % % granule. Be careful not to clobber the variables from this
% % % % granule as they will be needed to start the next orbit.
% % % 
% % % if pirate_from_next_granule
% % %     
% % %     [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
% % %         = pirate_data_here(metadata_directory, granules_directory, granule_start_time_guess, check_attributes, ...
% % %         latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);
% % %     
% % %     break
% % % end
% % % 
% % % % If this granule corresponds to the start of a new orbit break out
% % % % of this while loop and process this orbit.
% % % 
% % % if ~isempty(start_line_index)
% % %     break
% % % end
% % % 
% % % % Increment start time.
% % % 
% % % granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);
% % % end
% % % 
% % % oinfo(iOrbit).time_to_build_orbit = toc(start_time_to_build_this_orbit);
% % % 
% % % if print_diagnostics
% % %     fprintf('   Time to build this orbit: %6.1f seconds.\n', oinfo(iOrbit).time_to_build_orbit)
% % % end
% % % 
% % % end
