% test1 

clear all
clear global

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 1', 0);
nbytes = get_bytes_required_for_all_vars;

global array0

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 2', 0);
nbytes = get_bytes_required_for_all_vars;

array0 = ones(10000);

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 3 -- before call to test1_sub', 0);
nbytes = get_bytes_required_for_all_vars;

array1 = test1_sub;

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 4 -- after call to test1_sub', 0);
nbytes = get_bytes_required_for_all_vars;
