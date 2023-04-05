% alternate_calculation_of_osscan - alternate means of calculating osscan - PCC
%
% The following is a snippet of code is used to check to get the correct
% location in the current orbit to put the scan lines from this granule IF
% a granule has already been found for this orbit. Specifically, if a
% granule in this orbit has already been found, compare the location of the
% start of the orbit based on this granule with that previously found. This
% location may differ by up to 7 scan lines based on the orbit and the
% location of the granule in the orbit. If the two estimates differ by less
% than 7 scan lines, the value to use for the location of these scan lines 
% in the current orbit is determined from the end of the previous granule
% plus the number of missing scan lines--forced to be a mutiple of 0, 2020,
% 2030, 2040 or 2050. If they differ by more than 7 scan lines this snippet 
% of code returns a status of 113. 
%
% The snippet also calculates the lines to skip and does various tests on
% this value. This determination is based on the start time of the current
% granule and the end time of the previous granule. 

global oinfo iOrbit iGranule iProblem problem_list
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length time_of_NASA_orbit_change
global print_diagnostics save_just_the_facts debug
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg

if iGranule > 1
    
    % Make sure that there is a previous granule to use for this alternate
    % calculation. If it does not exist, skip this check.
    
    search_threshold = 2;
    
    lines_to_skip = floor( abs((oinfo(iOrbit).ginfo(iGranule).start_time - oinfo(iOrbit).ginfo(iGranule-1).end_time) * secs_per_day + 0.05) / secs_per_scan_line);
    
    % The lines to skip must be an integer multiple of 0, 2020, 2030, 2040 or 2050.
    
    base_lines = [2020:10:2050];
    num_possible = [1:39];
    
    possible_values = reshape([num_possible' * base_lines], length(base_lines)*length(num_possible), 1);
    possible_values = [0; possible_values];
    
    nn = find( min(abs(lines_to_skip - possible_values)) == abs(lines_to_skip - possible_values));
    
    if length(nn) ~= 1
        fprintf('Should only find one value of the number of lines to skip, but found %i. This should never happen but will round to the mean of the values if it does./n', length(nn))
        
        status = populate_problem_list( 111, ['Wants to skip ' num2str(lines_to_skip) ' lines.']);
        
        if debug
            keyboard
        end
        
        nn = round(mean(nn) / 2);
    end
    
    if abs(lines_to_skip - possible_values(nn)) > search_threshold
        fprintf('Wanted to skip %i lines but must be within %i of an integer multiple of 0, 2020, 2030, 2040 or 2050. Will force to %i lines.\n', lines_to_skip, search_threshold, possible_values(nn))
        
        status = populate_problem_list( 112, ['Wants to skip ' num2str(lines_to_skip) ' lines.']);
        
        if debug
            keyboard
        end
    end
    
    lines_to_skip = possible_values(nn);
    
    % Now check to see if there is approximate agreement between the two
    % methods of determining osscan. In the end the start of the location for
    % this granules data in the orbit will be a multiple of either 0, 2020,
    % 2030, 2040 or 2050. Allow the two estimates to differ by up to 7 scan
    % lines to account for the slight difference in latitude locations
    % between the canonical orbit and the current orbit.

    osscan_test = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1 + lines_to_skip;
    
    osscan_diff = indices.current.osscan - osscan_test;
    
    if abs(osscan_diff) > 7
        fprintf('Problem with start of scanline granules in this orbit for granule %s\n    %i calcuated based on canonical orbit, %i calcuated based on previous granule.  Using osscan from canonical orbit\n', ...
            oinfo(iOrbit).ginfo(iGranule).metadata_name, indices.current.osscan, osscan_test)
        
        status = populate_problem_list( 114, oinfo(iOrbit).ginfo(iGranule).metadata_name);
        
    else
        oinfo(iOrbit).ginfo(iGranule).osscan_diff = osscan_diff;
    end

    indices.current.osscan = osscan_test;
end



