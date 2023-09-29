% test2

clear all
clear global

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 1', 0, 0);
nbytes = get_bytes_required_for_all_vars(0);
fprintf('\ntest2: Memory required by the calling process: %5.2f GB. %5.2f megabytes required by all variables.\n', process_memory/10^6, nbytes/10^6)

array0 = ones(10000);

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 2', 0, 0);
nbytes = get_bytes_required_for_all_vars(0);
fprintf('\ntest2: Memory required by the calling process: %5.2f GB. %5.2f megabytes required by all variables.\n', process_memory/10^6, nbytes/10^6)

% function array2 = test2(array1)
% 
% [pid, process_memory, varNames, var_gb] = get_process_memory('test2_sub: 1', 0, 0);
% nbytes = get_bytes_required_for_all_vars(0);
% fprintf('\ntest2_sub: Memory required by the calling process: %5.2f GB. %5.2f megabytes required by all variables.\n', process_memory/10^6, nbytes/10^6)
% 
% array2 = array1(1).^2;
% 
% [pid, process_memory, varNames, var_gb] = get_process_memory('test2_sub: 2', 0, 0);
% nbytes = get_bytes_required_for_all_vars(0);
% fprintf('\ntest2_sub: Memory required by the calling process: %5.2f GB. %5.2f megabytes required by all variables.\n', process_memory/10^6, nbytes/10^6)
% 
% end

array1 = test2_sub(array0);

[pid, process_memory, varNames, var_gb] = get_process_memory('Main: 3', 0, 0);
nbytes = get_bytes_required_for_all_vars(0);
fprintf('\ntest2: Memory required by the calling process: %5.2f GB. %5.2f megabytes required by all variables.\n', process_memory/10^6, nbytes/10^6)
