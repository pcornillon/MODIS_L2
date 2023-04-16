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
% 104 - get_scanline_index - Only one intersection of nlat_t(5) found with
%       nlat_avg. 
%
% 111 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli - More than 1
%       possibility for the number of lines to skip was found, it should be
%       1. The values found were averaged and rounded to the nearest integer.
% 112 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli - The number of
%       lines to skip was not a multiple of 0, 2020, 2030, 2040 or 2050.  
% 113 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli - The estimated
%       orbit start time based on this granule differs by the equivalent of
%       more than 7 scan lines from that estimated on the granule when this
%       orbit was defined.
% 115 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli - Calculated end of orbit scanline does not agree with the mandated orbit length, nominally 40,271. Forcing it to agree.
% 116 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli -  Should only find one value for the number of lines to skip but found either 0 or more than 1.

% 111 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli - Adjacent orbits but osscan calculations disagree. Will use value based on end of previous granule.
% 112 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli - Didn't want to skip 1020, 1030, 1040 or 1050 scanlines. Setting lines to skip to 0.
% 113 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli - Calculated start location of scan line in orbit does not agree between the two methods used. Will use the calculation based on the canonical orbit. 
% 114 - get_osscan_etc_with_sli - Calculated end of orbit scanline does not agree with the mandated orbit length, nominally 40,271. Forcing it to agree.
% 115 - get_osscan_etc_NO_sli - Calculated end of orbit scanline does not agree with the mandated orbit length, nominally 40,271. Forcing it to agree.
% 116 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli -  Should only find one value for the number of lines to skip but found either 0 or more than 1.
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
% 231 - generate_output_filename - Problem determining the end time of an orbit. 
% 
% 241 - build_orbit - orbit name not built for iOrbit>1. Very bad. Abort.
% 251 - build_orbit - This orbit already built, have skipped to the start of the next orbit. 
%
% END OF RUN
%
% 901 - find_next_granule_with_data - end of run (used to be -999).
% 
% 911 - get_start_of_first_full_orbit - end of run.