% batch_job_generator - used to submit a number of build_and_fix_orbit jobs - PCC

submit_as_batch = 1;
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
% % % 
% % % while period_to_process(1) ~= 0
% % %     period_to_process = input('Sorry but can''t shift by years; please re-enter the date/time range for each batch job: ');
% % % end
% % % 
batch_step = input('Enter the date/time between the start of one batch times and the next as [yyyy mm dd hh min ss]; e.g, [0 0 1 0 0 0] for one day of satellite time between batch intervals: ');
% % % 
% % % while batch_step(1) ~= 0
% % %     batch_step = input('Sorry but can''t shift by years; please re-enter the date/time range for each batch job: ');
% % % end
% % % 
num_batch = input('Enter the number of batch jobs to submit; e.g, 5 to submit 5 batch jobs: ');
fprintf('\n')

% % % mat_start_time = datenum(start_time);
% % % mat_period_to_process = datenum(period_to_process);
% % % mat_time_between_batch_jobs = datenum(batch_step);

startYear = start_time(1);
startMonth = start_time(2);
startDay = start_time(3);
startHour = start_time(4);
startMinute = start_time(5);
startSecond = start_time(6);

% Define the time shift for the length of the interval to process, days,
% hour, minutes and seconds; months will be handled in the loop.

yearShift_period = period_to_process(1);
monthShift_period = period_to_process(2);
dayShift_period = days(period_to_process(3));
hourShift_period = hours(period_to_process(4));
minuteShift_period = minutes(period_to_process(5));
secondShift_period = seconds(period_to_process(6));

% Define the time shift for the separation of start times, days, hour,
% minutes and seconds; months will be handled in the loop.

yearShift_step = batch_step(1);
monthShift_step = batch_step(2);
dayShift_step = days(batch_step(3));
hourShift_step = hours(batch_step(4));
minuteShift_step = minutes(batch_step(5));
secondShift_step = seconds(batch_step(6));

% Create a datetime for the starting point

startTime = datetime(start_time);
endTime = startTime + calmonths(12) * yearShift_period + calmonths(1) * monthShift_period + dayShift_period + hourShift_period;

% Initialize an array to hold the datetime values

timeSeries_start = NaT(1, num_batch); % 'NaT' creates an array of Not-a-Time for preallocation
timeSeries_end = NaT(1, num_batch);

fprintf('The following jobs will be submitted: \n\n')

% Generate the time series

for iJob = 1:num_batch
    
    % Calculate the new time point, shifted by the defined durations
    % Handle month incrementation separately

    month_Shift_step = calmonths(iJob-1) * monthShift_step; % creates a duration of (i-1) months

    % Then, add the months, days, and hours
    
    timeSeries_start(iJob) = startTime + (iJob-1) * calmonths(12) * yearShift_step + month_Shift_step + (iJob-1) * (dayShift_step + hourShift_step);
    timeSeries_end(iJob) = endTime + (iJob-1) * calmonths(12) * yearShift_step + month_Shift_step + (iJob-1) * (dayShift_step + hourShift_step);

    mat_start(iJob) = datenum(timeSeries_start(iJob));
    mat_end(iJob) = datenum(timeSeries_end(iJob));

    fprintf('Job #%i, Job would process from %s to %s\n', iJob, datestr(mat_start(iJob)), datestr(mat_end(iJob)))
end

do_it = input('\nEnter 1 if you would like to actually submit these jobs, 0 to quit: ');
fprintf('\n')

if do_it == 1
    for iJob=1:num_batch
        fprintf('Submitting job #%i to process from %s to %s\n', iJob, datestr(mat_start(iJob)), datestr(mat_end(iJob)))

        base_diary_filename = strrep(strrep([datestr(now) '_Job_' num2str(iJob) '_From_' datestr(mat_start(iJob)) '_To_' datestr(mat_end(iJob))], ':', 'h'), ' ', '_');

        if submit_as_batch
            job_number(iJob) = batch( 'build_wrapper', 0, {Option, datevec(mat_start(iJob)), datevec(mat_end(iJob)), base_diary_filename}, CaptureDiary=true);
        else
            build_wrapper(Option, datevec(mat_start(iJob)), datevec(mat_end(iJob)), base_diary_filename)
        end
    end
end