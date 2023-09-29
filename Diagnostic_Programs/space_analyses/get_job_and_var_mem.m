% get_job_and_var_mem - get the memory required for the job and for all variables in the workspace - PCC
%
% This script will determine the line # and function from which it is being
% run, the memory required for the hob and the memory required for all
% variables in the workspace. It will then print out that information.
%   

% Find out where we are.

dbStack = dbstack;

% Get the Process ID and the space required by various elements of memory
% associated with this job

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 1', 0, 0);

% Get the memory required by the variables in the current workspace.

nbytes = get_bytes_required_for_all_vars(0);

% Print it all out.

fprintf('\n*****At line #%i in %s, the memory required by the calling process: %5.2f GB. %5.2f gigabytes required by all variables.\n', dbStack(2).line, dbStack(2).file, process_memory/10^6, nbytes/10^9)

if length(dbStack) > 2
    for iStack=3:length(dbStack)
        fprintf('        Called at line #%i in %s.\n', dbStack(iStack).line, dbStack(iStack).file)
    end
end

fprintf('\n')

