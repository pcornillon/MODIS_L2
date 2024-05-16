function [jobs] = show_batch_job_details( show_running, show_details, show_errors)
% show_batch_job_details - gets list of batch jobs and writes errors for those with problems - PCC
%
% This function will show characteristics of batch jobs.
%
% INPUT
%   show_running - Show status of running jobs if set to 1.
%   show_details - Show details of a specific job if set to 1. Will request
%    the job number.
%   show_errors - List all jobs with errors, showing the error and where it
%    occurred if set to 1. 
%
% OUTPUT 
%   none

% Must start Matlab first: matlab -nosplash -nodesktop -nodisplay

% Load project if not already loaded

if ~exist('prj')
    prj = openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj');
end

% Get List of Jobs

cluster = parcluster('local');                                    
jobs = findJob(cluster);

% Show status of running jobs if desired.

if show_running
    for i = 1:length(jobs)
        fprintf('%i) %s\n', i, jobs(i).State)
    end
end

% Show details of a specific job if desired.

if show_details
    job_number = input('Enter the job number for which you would like to see details: ');
    
    job = jobs(job_number);
    diary(job)
    
    out = fetchOutputs(job)
    
    log = getDebugLog(job)
end

% List all jobs with errors, showing the error and where it occurred.

if show_errors
    for iJob=1:length(jobs)
        if length(jobs(iJob).Tasks.Error) == 1
            message = [num2str(iJob) ') ' datestr(jobs(iJob).SubmitDateTime) ' :**: '];
            for iStack=1:length(jobs(iJob).Tasks.Error.stack)
                message = [message num2str(jobs(iJob).Tasks.Error.stack(iStack).line) ' in ' jobs(iJob).Tasks.Error.stack(iStack).name ' :**: '];
            end
            fprintf('\n%s\n', message)
            fprintf('ERROR MESSAGE: %s\n', jobs(iJob).Tasks.Error.message)
        end
    end
end
