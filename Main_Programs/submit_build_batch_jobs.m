% submit_build_batch_jobs - used to submit a number of build_and_fix_orbit jobs - PCC

Option = input('Enter 1, 2 , 3 or 4 for the computer you are using (Peter''s laptop, satdat1, AWS debug, AWS S3): ');
save_orbits = input('Enter 1 to write netCDF file for each orbit, otherwise enter 0: ');

switch Option
    case 1 % Peter's laptop
        fprintf('Test set Peter''s laptop: {[2010 6 19 5 0 0] [2010 6 19 11 0 0]} \n')

    case 2 % MacStudio
        fprintf('Test set. Any range is OK; e.g., for 13 orbits: {[2010 4 19 0 0 0] [2010 4 20 0 0 0]; [2010 5 19 0 0 0] [2010 5 20 0 0 0]; [2010 7 19 0 0 0] [2010 6 20 0 0 0]} \n')

    case 3 % AWS local for debug, not from S3
        fprintf('Test set AWS-local (not from S3): {[2010 4 19 0 0 0] [2010 4 19 6 0 0]} \n')

    case 4 % AWS from S3
        fprintf('Test set AWS-S3 for 3 orbits: {[2010 4 19 0 0 0] [2010 4 19 6 0 0]; [2010 5 19 0 0 0] [2010 5 19 6 0 0]; [2010 6 19 0 0 0] [2010 6 19 6 0 0]} \n')
        fprintf('             or for 13 orbits: {[2010 4 19 0 0 0] [2010 4 20 0 0 0]; [2010 5 19 0 0 0] [2010 5 20 0 0 0]; [2010 7 19 0 0 0] [2010 6 20 0 0 0]} \n')
end

fprintf('Enter periods to process in start and end time pairs. For example:\n')
fprintf('\n{[2010 2 10 2 0 0] [2010 2 10 5 0 0]; [2010 6 19 2 0 0] [2010 6 19 5 0 0]; [2010 7 19 2 0 0] [2010 7 19 5 0 0]} \n')
fprintf('\nTo submit 3 batch jobs, one to process the orbits between 2/10/2010 02:00:00 and 05:00:00\n')
fprintf('the second between 6/19/2010 02:00:00 and 05:00:00\n')
fprintf('and the second between 7/19/2010 02:00:00 and 05:00:00\n')
fprintf('\n')

periods_to_process = input('Enter the periods to process as indicated above: ');

for iJob=1:size(periods_to_process,1)
    job_number(iJob) = batch( 'build_wrapper', 0, {Option, periods_to_process{iJob,1}, periods_to_process{iJob,2}, save_orbits}, CaptureDiary=true);
end