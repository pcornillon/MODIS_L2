function  [pid, process_memory] = get_process_memory(Loc)
% get_process_memory - get main memory required by this process - PCC
%   
% Get the pid for this process, get the memory it uses, parse the
% resulting string to extract the space and print out. In the printout
% scale the output to bytes, megabytes and gigabytes.
%
% INPUT
%   Loc - a string used to denote the location from which the function was
%    called. 
%
% OUTPUT
%   pid = process identifier.
%   process_mem - main memory required for this process.
%

process_memory = -1;

% Get the pid for this process.

pid = num2str(feature('getpid'));

% Get memory it uses.

[status, cmdout] = system(['! ps -o rss -p ' pid]);

for i = 1:length(cmdout)
    char = cmdout(i);
    asciiVal = double(char);  % Convert char to its ASCII value
    octalStr = sprintf('%o', asciiVal);  % Convert ASCII value to octal
    % fprintf('Character: %c, Octal: %s\n', char, octalStr);

    if strcmp( octalStr, '12')
        break
    end
end

% And print it out.

process_mem = str2num( cmdout(i+1:end));

if process_mem < 10^5
    fprintf('Memory required by this job (1): %5.2f bytes. Called at %s.\n', process_mem, Loc)
elseif process_mem < 10^7
    fprintf('Memory required by this job (1): %5.2f MB. Called at %s.\n', process_mem/10^6, Loc)
else
    fprintf('Memory required by this job (1): %5.2f GB. Called at %s.\n', process_mem/10^9, Loc)
end


end