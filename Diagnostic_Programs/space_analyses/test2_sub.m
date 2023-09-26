function rarray2 = test2(rarray1)

[pid, process_memory] = get_process_memory('test2_sub: 1');
nbytes = get_bytes_required_for_all_vars;

rarray2 = rarray1.^2;

[pid, process_memory] = get_process_memory('test2_sub: 2');
nbytes = get_bytes_required_for_all_vars;

end