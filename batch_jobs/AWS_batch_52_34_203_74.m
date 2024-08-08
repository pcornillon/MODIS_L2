% AWS_batch_52_34_203_74 - Batch job to run build_and_fix_orbits on 52.34.203.74 at AWS - PCC 
%
% The four variables intialized below, start_time, period_to_process, batch_step 
% and num_batch define the range of the period for which orbits will be
% processed. The range will be specified in the versioning below.
% 
%
% Versions.
%   1.0.0 - 5/6/2024 - Initial version for test. - PCC
%   1.1.0 - 5/6/2024 - First major processing - PCC
%   1.1.1 - 5/7/2024 - Whoops, back to testing with 4 jobs. - PCC
%   1.1.2 - 5/8/2024 - Configured for major job. Will start processing at 
%           2015/1/1 00h00. Each job will process one month. - PCC
%   1.1.3 - 5/13/2024 - Configured for major job. Will start processing at 
%           2003/1/1 00h00. Each job will process one month. - PCC
%   2.0.0 - 6/4/2024 - Will run 90 batch jobs. Each job will process 20
%           days of data starting on 16-Feb-2005 for a total of 1800 days,
%           about 5 years. The last 20 day interval is from 01-Jan-2010 to
%           21-Jan-2010 04:00:00. The reason for the relatively short
%           period is, if all works well, for this job to finish before I
%           leave for my bike trip in France. 
%   2.0.1 - 7/25/2024 - Changed start time to 25 December 2014, the number
%           of jobs to run (54) to run and the number of days for each job
%           to process to 40.
%           Removed code specifying the number of workers to use.
%   2.0.2 - modified to process from 7/1/2012 in steps of 2 months,
%           submitting a new job as soon as one ends. End time 6/30/2017.

global version_struct

version_struct.AWS_batch_52_34_203_74 = '2.0.2';

% There is a test mode, which, if set to 1, allows you to run this script
% without submitting any jobs. It will however print out the range of dates
% to process. You should always run a test first and then remember to
% change test_run to 0 when you want this script to actually submit batch
% jobs. 

test_run = false; % Set to tru to print out jobs to be sumitted. Set to 0 when ready to actually submit the jobs

submit_as_batch = true; % Set to 0 if job is to be submitted interactively.

% The next line needs to be replaced with the line after if an AWS spot instance.

Option = 8; % Reads data from s3 in us-west-2.

% Open the Matlab Project MODIS_L2.

machine = pwd;
if (~isempty(strfind(machine, 'ubuntu'))) & (~test_run)
    prj = openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj');
    fprintf('Opened /home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj \n')
% else
%     prj=openProject('/Users/petercornillon/Git_repos/MODIS_L2/MODIS_L2.prj'); 
%     fprintf('Opened /Users/petercornillon/Git_repos/MODIS_L2/MODIS_L2.prj \n')
end

% Note that for the start time you MUST to specify a month and day other
% than 0; i.e., [2002 7 1 0 0 0] will start at 00h00 on 1 July 2002. If you
% were to have entered [2002 7 1 0 0 0], the job would have started at
% 00h00 on 30 June 2002.

start_time = [2012 7 1 0 0 0];   % This is the start date/time the batch jobs are to use as [yyyy mm dd hh min ss]
period_to_process = [0 1 0 4 0 0]; % This is the date/time range for each batch job entered as the number of [years months days hours minutes seconds]
batch_step = [0 1 0 0 0 0]; % And the satellite date/time between the start of one batch job and the start of the next [yyyy mm dd hh min ss]
num_batch = 60; % The number of batch jobs to submit

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

%%  OK, start the batch jobs now.

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
end

% Two variables that will rarely need to be changed. They will only be
% changed if you want to submit jobs using a different set of input data
% and/or if you want to run jobs interactively.

for iJob=1:num_batch
    base_diary_filename = strrep(strrep([datestr(now) '_Job_' num2str(iJob) '_From_' datestr(mat_start(iJob)) '_To_' datestr(mat_end(iJob))], ':', 'h'), ' ', '_');

    fprintf('Submitting job #%i to process from %s to %s. Diary file: %s\n', iJob, datestr(mat_start(iJob)), datestr(mat_end(iJob)), base_diary_filename)

    Var1 = datevec(mat_start(iJob));  % This line for debug, get rid of it later.

    if ~test_run
        if submit_as_batch
            fprintf('Command for job #%i: %s\n', iJob, ['job_number(iJob) = batch( ''build_wrapper'', 0, {' num2str(Option) ', ' num2str(datevec(mat_start(iJob))) ', ' num2str(datevec(mat_end(iJob))) ', ' base_diary_filename '}, CaptureDiary=true);'])
            job_number(iJob) = batch( 'build_wrapper', 0, {Option, datevec(mat_start(iJob)), datevec(mat_end(iJob)), base_diary_filename}, CaptureDiary=true);
        else
            build_wrapper( Option, datevec(mat_start(iJob)), datevec(mat_end(iJob)), base_diary_filename)
        end
    end
end

fprintf('\nTo get status of these jobs use ''job_number(iJob).xxx'', where iJob is one of the job numbers above\n and xxx is a particular characteristic of the job such as State or RunningDuration.\n')

% Wait until all jobs have completed and then exit Matlab

if ~test_run
    for iJob=1:num_batch
        job_number(iJob).wait();
    end

    exit
end
