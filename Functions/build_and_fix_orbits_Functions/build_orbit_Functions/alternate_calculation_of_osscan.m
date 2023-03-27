% alternate_calculation_of_osscan - alternate means of calculating osscan - PCC 
%
% The following is a snippet of code to generate osscan using the start
% time of this granule and the end time of the previous granule and to
% compare the result obtained above using the canonical orbit. This
% snippet is also used in get_osscan_etc_NO_sli.

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule sltimes_avg nlat_avg
global Matlab_start_time Matlab_end_time
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length
global print_diagnostics save_just_the_facts
global amazon_s3_run
global formatOut

% Check the start line in the current orbit determined determined from
% the latitude in the canonical orbit with an estimate of the start
% line based on the time between the beginning of this granule and the
% end of the previous one. This is just a sanity check on the
% calculaiton. Start by getting the number of lines to skip if any.

lines_to_skip = floor( abs((oinfo(iOrbit).ginfo(iGranule).start_time - oinfo(iOrbit).ginfo(iGranule-1).end_time) + 0.05) / secs_per_scan_line);

% The lines to skip should be either 0, 1020, 1030, 1040 or 1050. First 
% check to see if it is zero, the most probable case.

if lines_to_skip == 0
    if indices.current.osscan ~= (oinfo(iOrbit).ginfo(iGranule-1).oescan + 1)
        fprintf('Adjacent orbits but osscan calculated from canonical orbit is %i for %s. Setting osscan to previous %i+1.\n', indices.current.osscan, oinfo(iOrbit).ginfo(iGranule).metadata_name,oinfo(iOrbit).ginfo(iGranule-1).oescan)

        indices.current.osscan = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1;
        
        status = populate_problem_list( 111, oinfo(iOrbit).ginfo(iGranule).metadata_name);
    end
else
    if isempty(lines_to_skip == [1:39]'*[1020:10:1050])
        fprintf('Wanted to skip %i lines but the only permissible values are 0, 1020, 1030, 1040 or 1050. Setting lines_to_skip to 0.\n', lines_to_skip)
        
        lines_to_skip = 0;
        
        status = populate_problem_list( 112, []);
    end
    
    osscan_test = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1 + lines_to_skip;
    
    if indices.current.osscan ~= osscan_test
        fprintf('Problem with start of scanline granules in this orbit for granule %s\n    %i calcuated based on canonical orbit, %i calcuated based on previous granule.  Using osscan from canonical orbit\n', ...
            oinfo(iOrbit).ginfo(iGranule).metadata_name, indices.current.osscan, osscan_test)
        
        status = populate_problem_list( 113, oinfo(iOrbit).ginfo(iGranule).metadata_name);
    end
end
