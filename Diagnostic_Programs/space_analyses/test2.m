% test2

clear all
clear global

[pid, process_memory] = get_process_memory('Main: 1');
nbytes = get_bytes_required_for_all_vars;

array0 = ones(1000);

[pid, process_memory] = get_process_memory('Main: 2 -- before call to test2_sub');
nbytes = get_bytes_required_for_all_vars;

array1 = test2_sub(array0);

[pid, process_memory] = get_process_memory('Main: 3 -- after call to test2_sub');
nbytes = get_bytes_required_for_all_vars;
