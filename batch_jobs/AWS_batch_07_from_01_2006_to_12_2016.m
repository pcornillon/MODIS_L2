% AWS_batch_07_from_1_2006_to_12_2016 - Batch job to run build_and_fix_orbits at AWS - PCC 
%
% The four variables intialized below, start_time, period_to_process, batch_step 
% and num_batch define the range of the period for which orbits will be
% processed. The range will be specified in the versioning below.
% 
% Versions.
%   1.0.0 - 9/3/2024 - This is a cleanup run going from 1/01/2006 through
%           12/31/2016 in steps of 1 month, but submitting 132 jobs.
%           Currently designed to run on x2idn.16xlarge. This computer has
%           64 virtural cores and 1.9 TB of main memory, so Matlab will
%           default to 32 jobs at once and then start new ones as ones
%           either finish or fail - PCC  

global version_struct

version_struct.AWS_batch_07_from_1_2006_to_12_2016 = '1.0.0';

% There is a test mode, which, if set to 1, allows you to run this script
% without submitting any jobs. It will however print out the range of dates
% to process. You should always run a test first and then remember to
% change test_run to 0 when you want this script to actually submit batch
% jobs. 

test_run = false; % Set to 1 to print out jobs to be sumitted. Set to 0 when ready to actually submit the jobs

submit_as_batch = true; % Set to 0 if job is to be submitted interactively.

% The next line needs to be replaced with the line after if an AWS spot instance.

Option = 8; % Reads data from s3 in us-west-2.

% Open the Matlab Project MODIS_L2.

machine = pwd;
if (~isempty(strfind(machine, 'ubuntu'))) & (~test_run)
    prj = openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj');
    fprintf('Opened /home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj \n')
end

% Note that for the start time you MUST specify a month and day other than
% 0; i.e., [2002 7 1 0 0 0] will start at 00h00 on 1 July 2002. If you were
% to have entered [2002 7 0 0 0 0], the job would have started at 00h00 on
% 30 June 2002. 

start_time = [2006 1 01 0 0 0];   % This is the start date/time the batch jobs are to use as [yyyy mm dd hh min ss]
period_to_process = [0 1 0 4 0 0]; % This is the date/time range for each batch job entered as the number of [years months days hours minutes seconds]
batch_step = [0 1 0 0 0 0]; % And the satellite date/time between the start of one batch job and the start of the next [yyyy mm dd hh min ss]
num_batch = 132; % The number of batch jobs to submit

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
