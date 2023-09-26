% test1 

clear all
clear global

[pid, process_memory] = get_process_memory('Main: 1');
nbytes = get_bytes_required_for_all_vars;

global array0

[pid, process_memory] = get_process_memory('Main: 2');
nbytes = get_bytes_required_for_all_vars;

array0 = ones(1000);

[pid, process_memory] = get_process_memory('Main: 3 -- before call to test1_sub');
nbytes = get_bytes_required_for_all_vars;

array1 = test1_sub;

[pid, process_memory] = get_process_memory('Main: 4 -- after call to test1_sub');
nbytes = get_bytes_required_for_all_vars;
