function array1 = test1

global array0

[pid, process_memory, varNames, var_gb] = get_process_memory('test1_sub: 1', 0, 0);
nbytes = get_bytes_required_for_all_vars(0);
fprintf('\ntest1_sub: Memory required by the calling process: %5.2f GB. %5.2f megabytes required by all variables.\n', process_memory/10^6, nbytes/10^6)

array1 = array0.^2;

[pid, process_memory, varNames, var_gb] = get_process_memory('test1_sub: 2', 0, 0);
nbytes = get_bytes_required_for_all_vars(0);
fprintf('\ntest1_sub: Memory required by the calling process: %5.2f GB. %5.2f megabytes required by all variables.\n', process_memory/10^6, nbytes/10^6)

end