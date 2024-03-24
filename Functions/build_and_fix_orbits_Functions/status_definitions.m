% Meaning of return status. Old values in parentheses.
%
% % % % means that these are up to date.
%
% 101 - get_scanline_index - data granule missing but metadata granule present. Will skip to next granule.  
%       status = populate_problem_list( 101, ['No data granule found corresponding to ' metadata_file_list(1).folder '/' metadata_file_list(1).name '.'], granule_start_time_guess);
%       contnues from here; no return at this point -- WARNING

% 102 - find_next_granule_with_data - starting index less than 10. Setting
%       to 1. Not sure if this is correct.
% 104 - get_scanline_index - Only one intersection of nlat_t(5) found with nlat_avg. 

% 111- find_next_granule_with_data - Wrong number of scan lines in granule.
%
%       error - skips granule, returns from function. 

% 115 - find_next_granule_with_data - Number of lines to skip for this granule is not an acceptable value. Forcing to the possible number of lines to skip.
%       status = populate_problem_list( 115, ['Number of lines to skip for ' oinfo(iOrbit).ginfo(iGranule).metadata_name(kk+11:end-23) ...
%        ', ' num2str(lines_to_skip) ', is not an acceptable value. Forcing to ' num2str(possible_num_scan_lines_skip(3,nn)) '.'], granule_start_time_guess);
%       contnues from here; no return at this point -- WARNING

% 116 - find_next_granule_with_data - First 1/2 mirror rotation skipped for the granule, will skip xx lines at aa longitude, bb latitude.
%       status = populate_problem_list( 116, ['1st 1/2 mirror rotation missing for ' oinfo(iOrbit).ginfo(iGranule).metadata_name(kk+11:end-23) ...
%        '. Skipping ' num2str(lines_to_skip) ' scan lines at lon ' num2str(clon_2(1)) ', lat ' num2str(clat_2(1))], granule_start_time_guess);
%       contnues from here; no return at this point -- WARNING

% 117 - find_next_granule_with_data - Says to skip 10 lines for this granule, but the distance, which is xx km, isn't right. Will not skip any lines.
%       status = populate_problem_list( 117, ['Says to skip 10 lines for ' oinfo(iOrbit).ginfo(iGranule).metadata_name(kk+11:end-23) ...
%          ', but the distance, ' num2str(lines_to_skip) ' km, isn''t right. Will not skip any lines.'], granule_start_time_guess);
%       contnues from here; no return at this point -- WARNING

 
% 121 - add_granule_data_to_orbit - Error reading data granule. Will not populate from this granule. 
% 122 - add_granule_data_to_orbit - No data granule found but pirate_osscan is not empty. Should never get here. No scan lines added to the orbit.
%
% 131 - generate_output_filename - Calculation of end times do not agree.
%
% % % % 141 - get_granule_metadata - mirror rotation rate seems to have changed.
% % % %       status = populate_problem_list( 141, ['Number of scan lines in this granules is ' num2str(length(scan_line_times)) ', neither 2030 nor 2040. Continuing but be careful.'], granule_start_time_guess);
% % % %       continues; on return, continues if status = 141 -- WARNING
%
% % % % 142 - get_granule_metadata - mirror rotation rate seems to have changed.
% % % %       abs(dt - (secs_per_granule * length(scan_line_times) / 2030 - 10 * secs_per_scan_line))
% % % %       continues; on return, continues if status = 142 -- WARNING
%
% % % % 151 - find_next_granule_with_data - mirror side for the first scan line on granule same as that of the last scan of the prevous granule.
% % % %       continue -- WARNING.
% % % %
% % % % 152 - find_next_granule_with_data - mirror side for the 1st scan line in the 1st granule of this orbit is the same as that of the last scan of the last granule in the previous orbit.
% % % %       continue -- WARNING.
% % % %
% % % % 153 - find_next_granule_with_data - Can''t find the start of a group of 10 scan lines. Thought that it would be %i. SHOULD NEVER GET HERE.
% % % %       continue -- WARNING.
% % % %
% % % % 161 - extract_datetime_from_filename - Something wrong with filename passed into this function. SHOULD NEVER GET HERE.
% % % %       continue -- WARNING.
% % % %
% % % %   175 - build_and_fix_orbits - failed to copy output file to remote location.
% % % %         status = populate_problem_list( 175, ['Failed to copy ' output_filename ' to ' remote_filename '.']);
% % % %         error - nothing done here but need to fix quickly because it will result in a buildup of files in the local output directory.

% ACTION REQUIRED ON RETURN
%
% 201 - get_granule_metadata - Time for this granule is past the predicted end time of the current orbit.
%       status = populate_problem_list( 201, ['Granule past predicted end of orbit time: ' datestr(oinfo(iOrbit).end_time)], granule_start_time_guess);
%       return
%
% 211 - get_granule_metadata - No scanline start times for scanlines in this granule. This should never happen - skip this granule.
% 212 - get_granule_metadata - 1st scan line in the granule not the first in a 10 detector array. This should never happen - skip this granule.
%
% 231 - generate_output_filename - Should never happen; means the function was called with an argument other than 'sli' or 'no_sli'.
% 
% 241 - build_orbit - orbit name not built for iOrbit>1. Very bad. Abort.

% % % % 251 - build_orbit - This orbit already built, have skipped to the start of the next orbit. 
% % % %       return -- WARNING
% % % %

% 261 - build_orbit - length of oinfo less than iOrbit. Not sure how it would get here. 
%       status = populate_problem_list( 261, ['*** don''t think that we should ever get here: [iOrbit, iGranule]=[' num2str(iOrbit)] ', ' num2str(iGranule) ']. Orbit name: ' oinfo(iOrbit).name '.');
%       contnues from here; no return at this point -- WARNING

% 415 - get_osscan_etc_NO_sli - Calculated end of orbit scanline does not agree with the mandated orbit length, nominally 40,271. Forcing it to agree.
% 416 - get_osscan_etc_with_sli - Calculated end of orbit scanline does not agree with the mandated orbit length, nominally 40,271. Forcing it to agree.
%

% 600 - Wtite_SST_File - error copying file. 

%% **************** fix_MODIS_mask_full_orbit ****************

% % % % 701 - fix_MODIS_mask_full_orbit - No good data in granule. Set mask to nan and return.
% % % %       status = populate_problem_list( 701, 'No good data in SST_In. Set Final_Mask field to 1 and returned.');
% % % %       return == no action on return; status not passed back.

%% **************** regrid_MODIS_orbits ****************

% % % % 301 - regrid_MODIS_orbits - Found too many very large changes in longitude. 
% % % %       status = populate_problem_list( 301, ['Too many large longitudinal changes for scan line ' num2str(jpix)']);
% % % %       return == no action on return; status not passed back.

%% **************** get_scanline_index ****************

% % % % 801 - get_scanline_index - nan latitudes read from granule. This should not happen.  
% % % %       status = populate_problem_list( 101, ['Latitude for nlat_t(5) is nan for ' oinfo(iOrbit).ginfo(iGranule).metadata_name '. This should not happen. Skipping this granule.']);
% % % %       return -- no action on return since status is not passed back.
% % % % 
% % % % 802 - get_scanline_index - something fishy with latitudes read from granule.  
% % % %       status = populate_problem_list( 102, ['Latitudes don''t appear to be right for ' oinfo(iOrbit).ginfo(iGranule).metadata_name '. First latitude is ' num2str(nlat_t(1))])
% % % %       return -- no action on return since status is not passed back.
% % % % 
% % % % 803 - get_scanline_index - problem when trying to match current latitudes with the canonical orbit.   
% % % %       status = populate_problem_list( 103, ['Only one intersection of nlat_t(5) found with nlat_avg for ' oinfo(iOrbit).ginfo(iGranule).metadata_name]);
% % % %       continue -- WARNING -- status not passed back.
% % % % 
% % % % 804 - get_scanline_index - problem when trying to match current latitudes with the canonical orbit.   
% % % %       status = populate_problem_list( 104, ['Be careful, for granule ' oinfo(iOrbit).ginfo(iGranule).metadata_name ' get_scanline_index found a starting index of num2str(nnToUse). Is setting nnToUse to 1.']);   
% % % %       continue -- WARNING -- status not passed back.

% END OF RUN
% % % %
% % % % 901 - find_next_granule_with_data - Did not find a granule that crosses 78 S since the end of the last orbit. (used to be -999).
% % % %       status = populate_problem_list( 901, ['*** Did not cross ' num2str(latlim, 6.2) ' between end of previous orbit (' datestr(start_time) ') and (' datestr(Matlab_end_time) ')'], granule_start_time_guess);
% % % %       return -- ERROR
% % % % 902 - build_orbit - End of run. 
% % % %       status = populate_problem_list( 902, ['*** Have reached the end of the run: ' datestr(Matlab_end_time)], granule_start_time_guess);
% % % %       return -- ERROR

% 
% 911 - get_start_of_first_full_orbit - end of run.

%% ******************* regrid_MODIS_orbits ********************************
% % % % 1001 - regrid_MODIS_orbits - All of the SSTs in a section 1 to be regridded are nan. 
% % % %        status = populate_problem_list( 1001, ['All SST_In values in Section 1 are nan for orbit ' oinfo(iOrbit).name], fi_granule);
% % % %   continue -- WARMING -- status not passed back. 
% % % % 
% % % % 1002 - regrid_MODIS_orbits - All of the SSTs in a section 2 or 4 to be regridded are nan. 
% % % %        status = populate_problem_list( 1002, ['All SST_In values in Section 2 or 4 are nan for orbit ' oinfo(iOrbit).name], fi_granule);
% % % %   continue -- WARMING -- status not passed back. 
% % % % 
% % % % 1003 - regrid_MODIS_orbits - All of the SSTs in a section 3 to be regridded are nan. 
% % % %        status = populate_problem_list( 1003, ['All SST_In values in Section 3 are nan for orbit ' oinfo(iOrbit).name], fi_granule);
% % % %   continue -- WARMING -- status not passed back. 
% % % % 