% test2

clear all
clear global

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 1', 0);
nbytes = get_bytes_required_for_all_vars;

array0 = ones(10000);

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 2 -- before call to test2_sub', 0);
nbytes = get_bytes_required_for_all_vars;

array1 = test2_sub(array0);

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 3 -- after call to test2_sub', 0);
nbytes = get_bytes_required_for_all_vars;
