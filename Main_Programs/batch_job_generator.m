% batch_job_generator - used to submit a number of build_and_fix_orbit jobs - PCC

Option = 4;
save_orbits = 1;

fprintf('\nYou will be asked to enter a information needed to submit a number of batch jobs.\n')
fprintf('For each input requested there will be an example. The example will submit 5 batch jobs\n')
fprintf('with the first job starting with data on 10 February 2010 at 2 AM. This job will process\n')
fprintf('6 hours worth of data; i.e., from [2010 2 10 2 0 0] to [2010 2 10 8 0 0]. The start of the\n')
fprintf('second jobwill be offset from the start of the first job by 1 day ([0 0 1 0 0 0]) and it\n')
fprintf('will also process 6 hours of data; i.e., from [2010 2 11 2 0 0] to [2010 2 11 8 0 0].\n')
fprintf('And so, with the fifth job processing data from [2010 2 14 2 0 0] to [2010 2 14 8 0 0]\n')
fprintf('Don''t worry, were you to ask for 90 jobs, it will figure out the change in month and \n')
fprintf('year if necessary. Have at it.\n\n')

start_time = input('Enter the start date/time the batch jobs are to use as [yyyy mm dd hh min ss]; e.g, [2010 2 10 2 0 0]: ');
period_to_process = input('Enter the date/time range for each batch job as [yyyy mm dd hh min ss]; e.g, [0 0 0 6 0 0] to process 6 hours worth of data: ');
time_between_batch_jobs = input('Enter the date/time between the start of one batch times and the next as [yyyy mm dd hh min ss]; e.g, [0 0 1 0 0 0] for one day of satellite time between batch intervals: ');
num_batch = input('Enter the number of batch jobs to submit; e.g, 5 to submit 5 batch jobs: ');
fprintf('\n')

for_real = input('Enter 1 if you would like to actually submitted jobs, 0 to see what time periods you will be submitting without submitting the jobs: ');
fprintf('\n')

mat_start_time = datenum(start_time);
mat_period_to_process = datenum(period_to_process);
mat_time_between_batch_jobs = datenum(time_between_batch_jobs);

for iJob=1:num_batch
    tStart = datevec(mat_start_time + mat_time_between_batch_jobs * (iJob - 1));
    tEnd = datevec(datenum(tStart) + mat_period_to_process);

    fprintf('Submitting job #%i to process from %s to %s\n', iJob, datestr(tStart), datestr(tEnd))

    if for_real == 1
        job_number(iJob) = batch( 'build_wrapper', 0, {Option, tStart, tEnd, save_orbits}, CaptureDiary=true);
    end
end