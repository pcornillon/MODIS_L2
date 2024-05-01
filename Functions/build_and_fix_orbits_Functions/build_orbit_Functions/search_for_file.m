function [file_list] = search_for_file(baseName, Trailer)
% search_for_file - searches times in filenames containing HHMMSS for one day returns the time when one is found - PCC
%
% INPUT
%   baseName - the fully specified name of the file to search for up to HHMMSS
%   Trailer - what follows HHMMSS in the constructed filename.
%
% OUTPUT
%   file_list - a 1-element structure function with
%       - name - of the found file.
%       - folder - in which the file is.
%

% Set exit flag.

exitLoops = false;

for iHour=0:23
    if iHour>9
        HH = num2str(iHour);
    else
        HH = ['0' num2str(iHour)];
    end

    for iMinute=0:59
        if iMinute>9
            MM = num2str(iMinute);
        else
            MM = ['0' num2str(iMinute)];
        end

        for kSecond=0:59
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
else
    file_list = [];
end