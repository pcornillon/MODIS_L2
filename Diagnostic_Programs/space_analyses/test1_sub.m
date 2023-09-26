function rarray1 = test1

global rarray0

[pid, process_memory] = get_process_memory('test1_sub: 1');
nbytes = get_bytes_required_for_all_vars;

rarray1 = rarray0.^2;

[pid, process_memory] = get_process_memory('test1_sub: 2');
nbytes = get_bytes_required_for_all_vars;

end