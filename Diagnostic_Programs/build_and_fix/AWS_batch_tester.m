% AWS_batch_tester - 
%

job_number(iJob) = batch( 'Tester', 0, {1}, CaptureDiary=true);
pause(60)

job_number(iJob) = batch( 'Tester', 0, {11}, CaptureDiary=true);

fprintf('To get status of these jobs use ''job_number(iJob).xxx'', where iJob is one of the job numbers above\n and xxx is a particular characteristic of the job such as State or RunningDuration.\n')
