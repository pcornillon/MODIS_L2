function get_job_and_var_mem
% function get_job_and_var_mem - get the memory required for the job and for all variables in the workspace - PCC
%
% This function will determine the line # and function from which it is being
% run, the memory required for the hob and the memory required for all
% variables in the workspace. It will then print out that information.
%
%   mem_count - the number of times memory has been called for this orbit.
%   mem_print - 1 to print out memory stats here; 0 to just accumulate them. 
%   print_dbStack - 1 to print call heirarchy for the funcion call.
%

global mem_count mem_orbit_count mem_print print_dbStack mem_struct

global oinfo iOrbit iGranule iProblem problem_list

% Find out where we are.

dbStack = dbstack;

% Get the Process ID and the space required by various elements of memory
% associated with this job

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 1', 0, 0);

% Get the memory required by the variables in the current workspace.

nbytes = get_bytes_required_for_all_vars(0);

% Print it all out.

if mem_print
    fprintf('\n*****At line #%i in %s, the memory required by the calling process: %5.2f GB. %5.2f gigabytes required by all variables.\n', dbStack(2).line, dbStack(2).file, process_memory/10^6, nbytes/10^9)
end

if (mem_count == 1 & isempty(mem_orbit_count)) | (mem_count ~= length(mem_struct)) 
    mem_orbit_count = 1;
else
    mem_orbit_count = mem_orbit_count + 1;
end

mem_struct(mem_count).function{mem_orbit_count} = dbStack(2).file;
mem_struct(mem_count).line(mem_orbit_count) = dbStack(2).line;
mem_struct(mem_count).memory(mem_orbit_count) = process_memory / 10^6;
mem_struct(mem_count).var_size(mem_orbit_count) = nbytes / 10^9;

if ~isempty(iOrbit)
    mem_struct(mem_count).orbit = oinfo(iOrbit).orbit_number;
end

if print_dbStack
    if length(dbStack) > 2
        fprintf('Length of dbStack %i\n', length(dbStack))
        for iStack=3:length(dbStack)
            fprintf('        Called at line #%i in %s.\n', dbStack(iStack).line, dbStack(iStack).file)
        end
        fprintf('\n')
    end
end

