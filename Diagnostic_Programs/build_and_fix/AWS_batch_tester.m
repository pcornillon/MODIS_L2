% AWS_batch_tester - To test submitting Matlab headless, no hangup,...

submit_as_batch = 1; % Set to 0 if job is to be submitted interactively.
num_batch = 2;

logs_directory = '/Users/petercornillon/Logs/';

for iJob=1:num_batch
    if submit_as_batch
        fprintf('Command for job #%i: %s\n', iJob, ['job_number(iJob) = batch( ''tester'', 0, {' num2str(iJob^2) '}, CaptureDiary=true);'])
        job_number(iJob) = batch( 'tester', 0, {iJob^2}, CaptureDiary=true)
    else
        tester(iJob^2)
    end
end

