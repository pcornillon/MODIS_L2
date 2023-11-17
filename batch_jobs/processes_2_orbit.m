% processs_day_1_for_01_2003_thru_12_2010 - Script to submit build_and_fix batch jobs - PCC

% The four variables intialized below, start_time, period_to_process, batch_step 
% and num_batch must be changed for each version of this script. 
% 
% The values for this version of the script will submit batch jobs to
% process the first five orbits for the first day in each month of starting
% with January 2003 and ending with December 2010

% ANGELINA, you need to change the following four parameters for other
% runs. Don't forget to change the file name to reflect the period that
% will be processed. You will also need to expose the file to the project
% and to push the updated repository to GitHub. To expose the new files you
% make to the Matlab Project, click on the tab: Project - MODIS_L2 and then
% on the Add Files tab under Project. This will bring up the 'Add files to
% the project' window. In this window click on > next to batch_jobs and
% then on the button for the job you just added.  Ignore the .asv files.
% When you have saved and tested, remember to commit it since the AWS
% machine will need it.

% There is a test mode, which, if set to 1, allows you to run this script
% without submitting any jobs. It will however print out the range of dates
% to process. You should always run a test first and then remember to
% change test_run to 0 when you want this script to actually submit batch
% jobs. 

test_run = 1; % Set to 1 to print out jobs to be sumitted. Set to 0 when ready to actually submit the jobs
% Open the project if on AWS, otherwise, assume that it is already open.

machine = pwd
if (~isempty(strfind(machine, 'ubuntu'))) & (test_run == 0)
    prj = openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj')
end


% Note that for the start time you need to specify a month and day other
% than 0; i.e., [2002 7 1 0 0 0] will start at 00h00 on 1 July 2002. If you
% were to have entered [2002 7 1 0 0 0], the job would have started at
% 00h00 on 30 June 2002.

start_time = [2010 1 2 0 0 0];   % This is the start date/time the batch jobs are to use as [yyyy mm dd hh min ss]
period_to_process = [0 0 0 6 0 0]; % This is the date/time range for each batch job entered as the number of [years months days hours minutes seconds]
batch_step = [0 1 0 0 0 0]; % And the satellite date/time between the start of one batch job and the start of the next [yyyy mm dd hh min ss]
num_batch = 1; % The number of batch jobs to submit

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

submit_as_batch = 1; % Set to 0 if job is to be submitted interactively.

Option = 4; % Reads data from s3 in us-west-2.

for iJob=1:num_batch
    fprintf('Submitting job #%i to process from %s to %s\n', iJob, datestr(mat_start(iJob)), datestr(mat_end(iJob)))

    base_diary_filename = strrep(strrep([datestr(now) '_Job_' num2str(iJob) '_From_' datestr(mat_start(iJob)) '_To_' datestr(mat_end(iJob))], ':', 'h'), ' ', '_');

    if ~test_run
        if submit_as_batch
            %build_wrapper(Option, datevec(mat_start(iJob)), datevec(mat_end(iJob)), base_diary_filename)
            job_number(iJob) = batch( 'build_wrapper', 0, {Option, datevec(mat_start(iJob)), datevec(mat_end(iJob)), base_diary_filename}, CaptureDiary=true);
        else
            build_wrapper(Option, datevec(mat_start(iJob)), datevec(mat_end(iJob)), base_diary_filename)
        end
    end
end
