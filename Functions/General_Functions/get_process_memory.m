function  [pid, process_memory, varNames, var_gb] = get_process_memory(Loc, details)
% get_process_memory - get main memory required by this process - PCC
%
% Get the pid for this process, get the memory it uses, parse the
% resulting string to extract the space and print out. In the printout
% scale the output to bytes, megabytes and gigabytes.
%
% INPUT
%   Loc - a string used to denote the location from which the function was
%    called.
%   details - 1 to get the memory by different types, free, active,...
%
% OUTPUT
%   pid = process identifier.
%   process_mem - main memory required for this process.
%   varNames - names of pages for which the size has been obtained from vm_sat.
%   var_gb - the number of gigabyts allocated to the given page.

% [status, cmdout] = system('ps -e -o pid,ppid,args,rss -ww | grep -i matlab'); cmdout

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

% Get the size of the main memory of the calling process.

[status, cmdout] = system(['ps -o rss -p ' pid]);

for i = 1:length(cmdout)
    char = cmdout(i);
    asciiVal = double(char);  % Convert char to its ASCII value
    octalStr = sprintf('%o', asciiVal);  % Convert ASCII value to octal
    %     fprintf('Character: %c, Octal: %s\n', char, octalStr);
    
    if strcmp( octalStr, '12')
        break
    end
end

process_mem = str2num( cmdout(i+1:end));

% And print it out.

if process_mem < 10^5
    fprintf('\nMemory required by the calling process: %5.2f KB. Called at %s.\n', process_mem, Loc)
else
    fprintf('\nMemory required by the calling process: %5.2f GB. Called at %s.\n', process_mem/10^6, Loc)
end

%% Get memory information from vm_stat

if details
    vm_vars = {'Pages free' 'Pages active' 'Pages inactive' 'Pages speculative' 'Pages throttled' 'Pages wired down' 'Pages purgeable' '"Translation' 'Pages copy-on-write' 'Pages zero filled' 'Pages reactivated' 'Pages purged' 'File-backed'};
    
    for iVar=1:length(vm_vars)-1
        varNames{iVar} = strrep( vm_vars{iVar}, ' ', '_');
        varNames{iVar} = strrep(varNames{iVar}, '-', '_');
        varNames{iVar} = strrep(varNames{iVar}, 'P', 'p');
        varNames{iVar} = strrep(varNames{iVar}, '"', '');
    end
    
    % Load the memory info into cmdout
    
    [status, cmdout] = system('vm_stat');
    
    % Extract the number of bytes per category.
    
    for iVar=1:length(varNames)
        nn = strfind( cmdout, vm_vars{iVar});
        mm = strfind( cmdout, vm_vars{iVar+1});
        aline = cmdout(nn:mm-2);
        kk = strfind(aline, ' ');
        var_gb(iVar) = str2num( aline(kk(end)+1:end)) / 256000;
    end
    
    fprintf('\n%5.2f GB for free, active and inactive pages.\n', sum(var_gb(1:3)))
    fprintf('%5.2f GB for free and inactive pages.\n', sum(var_gb(1:2:3)))
    fprintf('%5.2f GB for active pages.\n\n', var_gb(2))
else
    varNames = {''};
    var_gb = [];
end

end