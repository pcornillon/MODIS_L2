% Meaning of return status. Old values in parentheses.
%
% INFORMATIONAL, NO ACTION REQUIRED ON RETURN.
%
% 101 - find_next_granule_with_data - data granule missing but metadata granule present. Will skip to next granule. 
%
% 111 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli - Adjacent orbits but osscan calculations disagree. Will use value based on end of previous granule.
% 112 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli - Didn't want to skip 1020, 1030, 1040 or 1050 scanlines. Setting lines to skip to 0.
% 113 - get_osscan_etc_with_sli, get_osscan_etc_NO_sli - Calculated start location of scan line in orbit does not agree between the two methods used. Will use the calculation based on the canonical orbit. 
% 114 - get_osscan_etc_with_sli - Calculated end of orbit scanline does not agree with the mandated orbit length, nominally 40,271. Forcing it to agree.
% 115 - get_osscan_etc_NO_sli - Calculated end of orbit scanline does not agree with the mandated orbit length, nominally 40,271. Forcing it to agree.
%
% 121 - add_granule_data_to_orbit - Error reading data granule. Will not populate from this granule. 
% 122 - add_granule_data_to_orbit - No data granule found but pirate_osscan is not empty. Should never get here. No scan lines added to the orbit.
%
% ACTION REQUIRED ON RETURN
%
% 201 - get_granule_metadata - end of orbit (100)
%
% 211 - get_granule_metadata - No scanline start times for scanlines in this granule. This should never happen - skip this granule.
% 212 - get_granule_metadata - 1st scan line in the granule not the first in a 10 detector array. This should never happen - skip this granule.
%
% 
% END OF RUN
%
% 901 - find_next_granule_with_data - end of run (used to be -999).
%
% 911 - get_start_of_first_full_orbit - end of run.