% AWS_batch_test - 
%
% The four variables intialized below, start_time, period_to_process, batch_step 
% and num_batch must be changed for each version of this script. For the
% current values, it will do January and February 2015 and should take
% about 1 3/4 days, 42 hours to process.
% 
% The values for this version of the script will 3 submit batch jobs to
% process the first 4 orbits for days 1, 2 and 3 of January 2012

% Versions.
%   1.0.0 - 5/6/2024 - Initial version for test. - PCC
%   1.1.0 - 5/6/2024 - First major processing - PCC
%   1.1.1 - 5/7/2024 - Whoops, back to testing with 4 jobs. - PCC
%   1.1.2 - 5/8/2024 - Configured for major job. Will start processing at 
%           2015/1/1 00h00. Each job will process one month. - PCC
%   1.1.3 - 5/13/2024 - Configured for major job. Will start processing at 
%           2003/1/1 00h00. Each job will process one month. - PCC
%   2.0.0 - 6/2/2024 - Configured to run 84 cores each processing one month
%           starting on 01/01/2010 and ending with 12/31/202016 - PCC 

global version_struct
version_struct.AWS_batch_test = '2.0.0';

% There is a test mode, which, if set to 1, allows you to run this script
% without submitting any jobs. It will however print out the range of dates
% to process. You should always run a test first and then remember to
% change test_run to 0 when you want this script to actually submit batch
% jobs. 

test_run = 0; % Set to 1 to print out jobs to be sumitted. Set to 0 when ready to actually submit the jobs

submit_as_batch = 1; % Set to 0 if job is to be submitted interactively.

% The next line needs to be replaced with the line after if an AWS spot instance.

Option = 8; % Reads data from s3 in us-west-2.

% Open the Matlab Project MODIS_L2.

machine = pwd;
if (~isempty(strfind(machine, 'ubuntu'))) & (test_run == 0)
    prj = openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj');
    fprintf('Opened /home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj \n')
% else
%     prj=openProject('/Users/petercornillon/Git_repos/MODIS_L2/MODIS_L2.prj'); 
%     fprintf('Opened /Users/petercornillon/Git_repos/MODIS_L2/MODIS_L2.prj \n')
end

% % % if (~isempty(strfind(machine, '/Users/petercornillon/'))) & (test_run == 0) & (submit_as_batch == 1)
% % %     prj = openProject('/Users/petercornillon/MATLAB/Projects/MODIS_L2/MODIS_L2.prj');
% % % end

% Note that for the start time you MUST to specify a month and day other
% than 0; i.e., [2002 7 1 0 0 0] will start at 00h00 on 1 July 2002. If you
% were to have entered [2002 7 1 0 0 0], the job would have started at
% 00h00 on 30 June 2002.

start_time = [2010 01 01 0 0 0];   % This is the start date/time the batch jobs are to use as [yyyy mm dd hh min ss]
period_to_process = [0 1 0 4 0 0]; % This is the date/time range for each batch job entered as the number of [years months days hours minutes seconds]
batch_step = [0 1 0 0 0 0]; % And the satellite date/time between the start of one batch job and the start of the next [yyyy mm dd hh min ss]
num_batch = 84; % The number of batch jobs to submit

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
%             fprintf('Command for job #%i: %s\n', iJob, ['job_number(iJob) = batch( ''tester'', 0, {' num2str(iJob^2) ', ' num2str(Var1) '}, CaptureDiary=true);'])
%             job_number(iJob) = batch( 'tester', 0, {iJob^2, Var1}, CaptureDiary=true)
        else
            build_wrapper( 3, datevec(mat_start(iJob)), datevec(mat_end(iJob)), base_diary_filename)
%             tester(iJob^2, Var1)
        end
    end
end

fprintf('To get status of these jobs use ''job_number(iJob).xxx'', where iJob is one of the job numbers above\n and xxx is a particular characteristic of the job such as State or RunningDuration.\n')

for iJob=1:num_batch
    job_number(iJob).wait();
end

exit