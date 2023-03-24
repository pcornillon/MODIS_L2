function [status, granule_start_time_guess] = find_next_granule_with_data( granule_start_time_guess)
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

filelist = [];

if isempty(filelist)
    
        granule_start_time_guess = granule_start_time_guess + 5 /(24 * 60);

end

