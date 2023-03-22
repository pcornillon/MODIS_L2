function [indices] = get_osscan_etc( orbit_status, inputArg2)
% get_osscan_etc - determine the starting and ending indices for orbit and granule data - PCC
%
% This function is called after either the start of an orbit was found in a
% granule or the start time of the granule just read is later than the
% estimated end time of the current orbit. For the first case, the function
% will calculate the starting and ending indices for the data from the
% current granule in the current orbit and in the next orbit. It will also
% determine whether or not data is needed from the next granule to complete
% the current orbit. If so, it will determine the start and end indices for
% that orbit. It will also determin the corresponding locations from which
% to copy the data in the current granule.
%
% If the granule just read is past the end of the current orbit, the
% function will determine indices for where to place the data in the orbit
% with which that granule corresponds, for the subsequent orbit and for the
% granules.
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

% Which case, start of new orbit found or granule past end of existing
% orbit?

if isempty(start_line_index)
    indices.case = 3;
    
    % Find location on canonical orbit.
    
    indices.osscan_p1 = 
    
else
    
    indices.case = 1;
    
    if strcmp(orbit_status, 'continue_orbit')
        
        % Get lines to skip for missing granules. Will, hopefully, be 0 if no granules skipped.

        oinfo(iOrbit).ginfo(iGranule).start_time = scan_line_times(1) * secs_per_day;
        oinfo(iOrbit).ginfo(iGranule).end_time = scan_line_times(end) * secs_per_day + secs_per_scan_line * 10;
                
        lines_to_skip = floor( abs((oinfo(iOrbit).ginfo(iGranule).start_time - oinfo(iOrbit).ginfo(end-1).end_time) + 0.05) / secs_per_scan_line);
        
        % The lines to skip should be either 1030 or 1040 -- I think. If
        % less than 1000, set to zero.
        
        if isempty(lines_to_skip == [1:39]'*[1020:10:1050])
            fprint('Wanted to skip %i lines but the only permissible values are multiles of 1020, 1030, 1040 or 1050. Setting lines to skip to 0.\n', lines_to_skip)
            lines_to_skip = 0;
        
            status = populate_problem_list( 60, []);
        end
        
        indices.osscan = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1 + lines_to_skip;
        indices.oescan = indices.osscan + start_line_index + 100 - 2;
        indices.gsscan = 1;
        indices.gescan = start_line_index;
        
        % Determine how many scan lines are needed to bring the length
        % of this orbit to orbit_length, nominally 40,271 scan lines.
        % This should result in about 100 lines of overlap with the
        % next orbit--it varies from orbit to orbit because some orbits
        % are 40,160 and some are 40,170. Plus we
        % want 1 extra scan line at the end to allow for the bow-tie
        % correction. If the number of scan lines remaining to be
        % filled exceed the number of scan lines in this granule,
        % default to reading the entire granule and set a flag to tell
        % the function to get the remaining lines to complete the orbit
        % from the next granule.
        
        if (oescan + 1 - osscan) > num_scan_lines_in_granule
            indices.case = 2;
            
            indices.oescan = indices.osscan + num_scan_lines_in_granule - 1;
            indices.gescan = num_scan_lines_in_granule;
            
            indices.osscan_a = indices.oescan + 1;
            indices.oescan_a = orbit_length;
            indices.gsscan_a = 1;
            indices.gescan_a = indices.oescan_a - indices.osscan_a + 1;
        else
            oinfo(iOrbit).ginfo(iGranule).oescan = orbit_length;
            
            oinfo(iOrbit).ginfo(iGranule).gescan = oinfo(iOrbit).ginfo(iGranule).oescan - oinfo(iOrbit).ginfo(iGranule).osscan + 1;
        end
    end
    
    indices.osscan_p1 = 1;
    indices.oescan_p1 = num_scan_lines_in_granule - start_line_index + 1;
    indices.gsscan_p1 = start_line_index;
    indices.gescan_p1 = num_scan_lines_in_granule;
    
    % Save the start time for the next orbit. This will be passed
    % back to the main program.
    
    oinfo(iOrbit+1).orbit_start_time = scan_line_times(start_line_index);
    oinfo(iOrbit+1).ginfo(1).metadata_name = oinfo(iOrbit).ginfo(iGranule).metadata_name;
    
end

% Read the data for the next granule in this orbit.

[status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
    = add_granule_data_to_orbit( granules_directory, check_attributes, ...
    latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);

oinfo(iOrbit).ginfo(iGranule).status = status;

% If need more scans to complete this orbit, get them from the next
% granule. Be careful not to clobber the variables from this
% granule as they will be needed to start the next orbit.

if pirate_from_next_granule
    
    [status, latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start] ...
        = pirate_data_here(metadata_directory, granules_directory, granule_start_time_guess, check_attributes, ...
        latitude, longitude, SST_In, qual_sst, flags_sst, sstref, scan_seconds_from_start);
    
    break
end

% If this granule corresponds to the start of a new orbit break out
% of this while loop and process this orbit.

if ~isempty(start_line_index)
    break
end

% Increment start time.

granule_start_time_guess = granule_start_time_guess + 5 / (24 * 60);
end

oinfo(iOrbit).time_to_build_orbit = toc(start_time_to_build_this_orbit);

if print_diagnostics
    fprintf('   Time to build this orbit: %6.1f seconds.\n', oinfo(iOrbit).time_to_build_orbit)
end

end





% but the 3rd point would be very close to the end of
% the orbit. If the function is being used to find  result in using a few 
% points from this granule to complete 
% this orbit, the vast majority of which would be
% empty and then the remaining points as the 1st
% part of the next granule. Using the 1st point
% found would mean that the 1st few scan lines on
% this orbit would be empty but the remainder of
% the orbit would be complete. In either case, we
% would end up using all the points on this granule
% but it would be more complicated to use the 3rd
% point so, that's what we will do! Note that we're
% searching for the 5th and 10th point. This is to
% make sure that the orbit starts in the middle of
% a 10 detector group.

filename_to_use = oinfo(iOrbit).ginfo(iGranule).metadata_name;
nnToUse = get_scanline_index( nlat_t(5), nlat_t(11), filename_to_use);

% This index has to be an even multiple of 10.

nnToUse = floor(mod(nnToUse(1))/10 * 10;






% %     if isempty(start_line_index)
% %
% %         % Didn't find the start of a new orbit but the granule for
% %         % the start of the next orbit may be missing so, check the
% %         % to see if the end was skipped. If so, break out of this while
% %         % loop over granules for this orbit, i.e., assume that the orbit
% %         % has ended and process what we have for this orbit. Do not use
% %         % the scan lines in this granule. When done processing, the
% %         % script will start a new orbit, estimating the number of scan
% %         % lines into that orbit that correspond to this granule.
% %
% %         if oinfo(iOrbit).ginfo(iGranule).start_time > (oinfo(iOrbit).ginfo(1).start_time + secs_per_orbit + 300)
% %             fprintf('... Seems like the granule containing the start of the next orbit is MISSING,\nThat this granule\n %s\nis in a new orbit so break our of loop over granules for this orbit.\n', oinfo(iOrbit).ginfo(iGranule).metadata_name)
% %             oinfo(iOrbit+1).ginfo(1) = oinfo(iOrbit).ginfo(iGranule);
% %             break
% %         end
% %
% %         oinfo(iOrbit).ginfo(iGranule).oescan = oinfo(iOrbit).ginfo(iGranule).osscan + num_scan_lines_in_granule - 1;
% %
% %         % Make sure that this granule does not add more scan lines than
% %         % the maximum allowed, orbit_length. This should not happen
% %         % since this granule does not have the start of an orbit in it.
% %
% %         if oinfo(iOrbit).ginfo(iGranule).oescan > orbit_length
% %
% %             status = populate_problem_list( 110, oinfo(iOrbit).ginfo(iGranule).data_granule_name);
% %             return
% %         end
% %
% %         oinfo(iOrbit).ginfo(iGranule).gescan = num_scan_lines_in_granule;
% %
% %         if isempty(oinfo(iOrbit).ginfo(iGranule).osscan) | ...
% %                 isempty(oinfo(iOrbit).ginfo(iGranule).oescan) | ...
% %                 isempty(oinfo(iOrbit).ginfo(iGranule).gsscan) | ...
% %                 isempty(oinfo(iOrbit).ginfo(iGranule).gescan)
% %             keyboard
% %         end
% %
% %     else

