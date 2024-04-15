% AWS_batch_tester - 
%

logs_directory = '/mnt/uri-nfs-cornillon/Logs/';

base_diary_filename = strrep(strrep([datestr(now) '_tester'], ':', 'h'), ' ', '_');

diary_filename = [logs_directory  base_diary_filename '.txt'];
diary(diary_filename)

% job_number(iJob) = batch( 'Tester', 0, {1}, CaptureDiary=true);
Tester(1)

pause(60)

% job_number(iJob) = batch( 'Tester', 0, {11}, CaptureDiary=true);

Tester(11)

fprintf('To get status of these jobs use ''job_number(iJob).xxx'', where iJob is one of the job numbers above\n and xxx is a particular characteristic of the job such as State or RunningDuration.\n')
