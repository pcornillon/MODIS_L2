function [file_list, granule_start_time_guess] = search_for_file(baseName, granule_start_time_guess, Trailer)
% search_for_file - searches times in filenames containing HHMMSS for one day returns the time when one is found - PCC
%
% INPUT
%   baseName - the fully specified name of the file to search for up to HHMMSS
%   granule_start_time_guess - the matlab_time of the granule to start with.
%   Trailer - what follows HHMMSS in the constructed filename.
%
% OUTPUT
%   file_list - a 1-element structure function with
%       - name - of the found file.
%       - folder - in which the file is.
%   granule_start_time_guess - the matlab_time of the granule after searching.
%
%  CHANGE LOG
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/6/2024 - Initial version - PCC
%   1.1.0 - 5/7/2024 - passed in time to start the search. Determined the
%           time of the granule found, if one was, or the start of the next
%           day if a granule was not found. - PCC
%

global version_struct
version_struct.search_for_file = '1.1.0';

global formatOut

HHMMSS = datestr(granule_start_time_guess, formatOut.HHMMSS);

hourStart = str2num(HHMMSS(1:2));

% Set exit flag.

exitLoops = false;

for iHour=hourStart:23
    if iHour>9
        HH = num2str(iHour);
    else
        HH = ['0' num2str(iHour)];
    end

    if iHour == hourStart
        minuteStart = str2num(HHMMSS(3:4));
    else 
        minuteStart = 0;
    end

    for iMinute=minuteStart:59
        if iMinute>9
            MM = num2str(iMinute);
        else
            MM = ['0' num2str(iMinute)];
        end

        if iMinute == minuteStart
            secondStart = str2num(HHMMSS(5:6));
        else
            secondStart = 0;
        end

        for kSecond=secondStart:59
            if kSecond>9
                SS = num2str(kSecond);
            else
                SS = ['0' num2str(kSecond)];
            end

            if exist([baseName HH MM SS Trailer])
                
                % Set the control variable to true and break out of this loop. 

                exitLoops = true;
                break;
            end
        end

        % Check the control variable to break the second level loop

        if exitLoops
            break;
        end
    end
    % Check the control variable to break the second level loop

    if exitLoops
        break;
    end
end

% Now set the output parameters.

if exitLoops
    % Extract folder and the first part of the filename from baseDir.

    nn = strfind( baseName, '/');

    folderName = baseName(1:nn(end));
    file_list(1).name = [baseName(nn(end)+1:end) HH MM SS '_L2_SST_OBPG_extras.nc4'];
    file_list(1).folder = folderName;

    % Set granule search time to the start of the granule found.

    granule_start_time_guess = floor(granule_start_time_guess) + (str2num(HH) + (str2num(MM) + str2num(SS) / 60) / 60) / 24;
else
    file_list = [];

    % Set granule search time to the start of the next day.

    granule_start_time_guess = floor(granule_start_time_guess) + 1;
end

