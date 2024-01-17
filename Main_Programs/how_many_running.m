% how_many_running - how many batch jobs are still running - PCC
% 
% This script is submitted periodically, like once every 15 minutes, to
% determine how many batch jobs submitted from Matlab are still running.
% The idea is that when this number goes below a given threshold the job
% ends.
%

number_of_jobs = length(job_number);
number_running = 0;
number_finished = 0;

for iJob=1:number_of_jobs

    status(iJob) = job_number(iJob).State;

    if strcmp(status(iJob), 'running')
        number_running = number_running + 1;
    elseif strcmp(status(iJob), 'finished')
        number_finished = number_finished + 1;
    end
end

fprintf('At %s of %i jobs submitted, %i have finished and %i are still running.\n', ...
    datestr(now), number_of_jobs, number_finished, number_running)

if (number_running + number_finished) ~= number_of_jobs
    fprintf('*** Gulp, the number finished + the number running, %i, is not equal to the number submitted, %i.\n', ...
        number_of_jobs+number_finished, number_of_jobs)
end

