% alternate_calculation_of_osscan - alternate means of calculating osscan - PCC
%
% The following is a snippet of code to generate osscan using the start
% time of this granule and the end time of the previous granule and to
% compare the result obtained above using the canonical orbit. This
% snippet is also used in get_osscan_etc_NO_sli.

global oinfo iOrbit iGranule iProblem problem_list
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length time_of_NASA_orbit_change
global print_diagnostics save_just_the_facts debug
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg

% % % % % % % % % % First, if already one granule exists for this orbit and this is the
% % % % % % % % % % simple case of this granule immediately following the previous one, then
% % % % % % % % % % so, get the start location of the data for this granule in the orbit and
% % % % % % % % % % return.
% % % % % % % % %
% % % % % % % % % if iGranule >1
% % % % % % % % %     if abs(scan_line_times(1) - oinfo(iOrbit).ginfo(iGranule-1).end_time) * secs_per_day < 3 * secs_per_scan_line
% % % % % % % % %         indices.current.osscan = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1;
% % % % % % % % %         return
% % % % % % % % %     end
% % % % % % % % % end
% % % % % % % % %

% Check the start line in the current orbit determined from the latitude in
% the canonical orbit with an estimate of the start line based on the time
% between the beginning of this granule and the end of the previous one, if
% this is the 2nd or higher granule available for this orbit. This is just
% a sanity check on the calculaiton. Start by getting the number of lines
% to skip if any.

if iGranule > 1
    
    % Make sure that there is a previous granule to use for this alternate
    % calculation. If it does not exist, skip this check.
    
    search_threshold = 2;
    
    lines_to_skip = floor( abs((oinfo(iOrbit).ginfo(iGranule).start_time - oinfo(iOrbit).ginfo(iGranule-1).end_time) * secs_per_day + 0.05) / secs_per_scan_line);
    
    if length(lines_to_skip) ~= 1
        fprintf('Should only find one value of the number of lines to skip, but found %i. This should never happen./n', length(lines_to_skip))
        
        status = populate_problem_list( 111, ['Wants to skip ' num2str(lines_to_skip) ' lines.']);
        
        if debug
            keyboard
        end
        
        return
    end
    
    % The lines to skip must be an integer multiple of 0, 1020, 1030, 1040 or 1050.
    
    base_lines = [1020:10:1050];
    num_possible = [1:39];
    
    possible_values = reshape([num_possible' * base_lines], length(base_lines)*length(num_possible), 1);
    possible_values = [0; possible_values];
    
    nn = find( min(abs(lines_to_skip - possible_values)) == abs(lines_to_skip - possible_values));
    
    if length(nn) ~= 1
        fprintf('Should only find one value of the number of lines to skip, but found %i. This should never happen./n', length(nn))
        
        status = populate_problem_list( 112, ['Wants to skip ' num2str(lines_to_skip) ' lines.']);
        
        if debug
            keyboard
        end
        
        return
    end
    
    if abs(lines_to_skip - possible_values(nn))> search_threshold
        fprintf('Wanted to skip %i lines but must be within %i of an integer multiple of 0, 1020, 1030, 1040 or 1050. Will force to %i lines.\n', lines_to_skip, search_threshold, possible_values(nn))
        
        status = populate_problem_list( 112, ['Wants to skip an ' num2str(lines_to_skip) ' lines.']);
        
        if debug
            keyboard
        end
    end
    
    lines_to_skip = possible_values(nn);
    
    % % % % Now check to see if there is approximate agreement between the two
    % % % % methods of determining osscan. In the end the start of the location for
    % % % % this granules data in the orbit will be a multiple of either 0, 1020,
    % % % % 1030, 1040 or 1050.
    % % %
    % % % if lines_to_skip == 0
    % % %     if abs(indices.current.osscan - (oinfo(iOrbit).ginfo(iGranule-1).oescan + 1)) > 1
    % % %         fprintf('Adjacent orbits but osscan calculated from canonical orbit is %i for %s. Setting osscan to previous %i+1.\n', indices.current.osscan, oinfo(iOrbit).ginfo(iGranule).metadata_name,oinfo(iOrbit).ginfo(iGranule-1).oescan)
    % % %
    % % %         status = populate_problem_list( 111, oinfo(iOrbit).ginfo(iGranule).metadata_name);
    % % %
    % % %         if debug
    % % %             keyboard
    % % %         end
    % % %     end
    % % %
    % % %     indices.current.osscan = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1;
    % % % else
    % % %
    % % %     osscan_test = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1 + lines_to_skip;
    % % %
    % % %     if indices.current.osscan ~= osscan_test
    % % %         fprintf('Problem with start of scanline granules in this orbit for granule %s\n    %i calcuated based on canonical orbit, %i calcuated based on previous granule.  Using osscan from canonical orbit\n', ...
    % % %             oinfo(iOrbit).ginfo(iGranule).metadata_name, indices.current.osscan, osscan_test)
    % % %
    % % %         status = populate_problem_list( 113, oinfo(iOrbit).ginfo(iGranule).metadata_name);
    % % %
    % % %         if debug
    % % %             keyboard
    % % %         end
    % % %     end
    % % % end
    % % %
    
    osscan_test = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1 + lines_to_skip;
    
    % Allow the two estimates to differ by 1 to account for a slightly
    % different amount of time separating scans on this orbit compared with
    % the canonical orbit.
    
    if abs(indices.current.osscan - osscan_test) > 3
        fprintf('Problem with start of scanline granules in this orbit for granule %s\n    %i calcuated based on canonical orbit, %i calcuated based on previous granule.  Using osscan from canonical orbit\n', ...
            oinfo(iOrbit).ginfo(iGranule).metadata_name, indices.current.osscan, osscan_test)
        
        status = populate_problem_list( 113, oinfo(iOrbit).ginfo(iGranule).metadata_name);
        
        if debug
            keyboard
        end
    end

    indices.current.osscan = osscan_test;
end



