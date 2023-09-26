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

% Alternatively, you could use the following in place of this line since
% 'feature' is not a supported Matlab function although it is a function
% that is part of the Matlab code base.
%
% runtime_bean = java.lang.management.ManagementFactory.getRuntimeMXBean();
% jvmName = char(runtime_bean.getName());
% pid = sscanf(jvmName, '%d');
% disp(pid);

% Get the memory of the calling process.

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

process_mem = str2num( cmdout(i+1:end));

% If called from the Matlab GUI, you need to get the size of the Matlab
% program from which the GUI was called. So, I need to see if this pid is
% working in the GUI. I think that the way to do this is to look for
% 'maci64' in the argument list of the pid. If present, then get the memory
% required for this task and then the memory for the main Matlab calling
% program.

[status, cmdout] = system(sprintf('ps -p %d -ww -o args', pid));

if contains(cmdout, 'maci64')

    fprintf('\nLooks like the Matlab GUI was called from a Matlab process so will get the size of both.\n')

    % Matlab working from the GUI. Get memory of the main Matlab program

    [status, cmdout] = system(sprintf('ps -p %d -ww -o ppid', pid));

    for i = 1:length(cmdout)
        char = cmdout(i);
        asciiVal = double(char);  % Convert char to its ASCII value
        octalStr = sprintf('%o', asciiVal);  % Convert ASCII value to octal
        % fprintf('Character: %c, Octal: %s\n', char, octalStr);

        if strcmp( octalStr, '12')
            break
        end
    end

    pid = = str2num( cmdout(i+1:end));

    % Add the memory for the calling program to process_mem.

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

    process_mem = process_mem + str2num( cmdout(i+1:end));
end

% And print it out.

if process_mem < 10^5
    fprintf('Memory required by this job (1): %5.2f bytes. Called at %s.\n', process_mem, Loc)
elseif process_mem < 10^7
    fprintf('Memory required by this job (1): %5.2f MB. Called at %s.\n', process_mem/10^6, Loc)
else
    fprintf('Memory required by this job (1): %5.2f GB. Called at %s.\n', process_mem/10^9, Loc)
end


end