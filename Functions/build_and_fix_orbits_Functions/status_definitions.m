% Meaning of return status. Old values in parentheses.
%
% INFORMATIONAL, NO ACTION REQUIRED ON RETURN.
%
% 101 - get_scanline_index - data granule missing but metadata
%       granule present. Will skip to next granule.  
% 102 - find_next_granule_with_data - starting index less than 10. Setting
%       to 1. Not sure if this is correct.
% 103 - get_scanline_index - Latitude for nlat_t(5) is nan. This should not
%       happen. Skipping this granule. 
% 104 - get_scanline_index - Only one intersection of nlat_t(5) found with nlat_avg. 
%
% 115 - find_next_granule_with_data - Number of lines to skip for this granule is not an acceptable value. Forcing to the possible number of lines to skip.
% 116 - find_next_granule_with_data - First 1/2 mirror rotation skipped for the granule, will skip xx lines at aa longitude, bb latitude.
% 117 - find_next_granule_with_data - Says to skip 10 lines for this granule, but the distance, which is xx km, isn't right. Will not skip any lines.
%
% 121 - add_granule_data_to_orbit - Error reading data granule. Will not populate from this granule. 
% 122 - add_granule_data_to_orbit - No data granule found but pirate_osscan is not empty. Should never get here. No scan lines added to the orbit.
%
% 131 - generate_output_filename - Calculation of end times do not agree.
%
% 141 - get_granule_metadata - mirror rotation rate seems to have changed.
%
% ACTION REQUIRED ON RETURN
%
% 201 - get_granule_metadata - end of orbit (100)
%
% 211 - get_granule_metadata - No scanline start times for scanlines in this granule. This should never happen - skip this granule.
% 212 - get_granule_metadata - 1st scan line in the granule not the first in a 10 detector array. This should never happen - skip this granule.
%
% 231 - generate_output_filename - Should never happen; means the function was called with an argument other than 'sli' or 'no_sli'.
% 
% 241 - build_orbit - orbit name not built for iOrbit>1. Very bad. Abort.
% 251 - build_orbit - This orbit already built, have skipped to the start of the next orbit. 
%

% 415 - get_osscan_etc_NO_sli - Calculated end of orbit scanline does not agree with the mandated orbit length, nominally 40,271. Forcing it to agree.
% 416 - get_osscan_etc_with_sli - Calculated end of orbit scanline does not agree with the mandated orbit length, nominally 40,271. Forcing it to agree.
%
% END OF RUN
%
% 901 - find_next_granule_with_data - end of run (used to be -999).
% 
% 911 - get_start_of_first_full_orbit - end of run.