% AWS_batch_tester - To test submitting Matlab headless, no hangup,...

logs_directory = '/Users/petercornillon/Logs/';

base_diary_filename = strrep(strrep([datestr(now) '_tester'], ':', 'h'), ' ', '_');

diary_filename = [logs_directory  base_diary_filename '.txt'];
diary(diary_filename)

fprintf('Started job. Will pause for 2 minutes.n')

pause(120)

A = 11;

fprintf('Waited 2 minutes. A = %f\n', A)
