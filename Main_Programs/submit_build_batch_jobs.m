% submit_build_batch_jobs - used to submit a number of build_and_fix_orbit jobs - PCC

fprintf('Enter periods to process in start and end time pairs. For example:\n')
fprintf('\n{[2010 2 10 2 0 0] [2010 2 10 5 0 0]; [2010 6 19 2 0 0] [2010 6 19 5 0 0]; [2010 7 19 2 0 0] [2010 7 19 5 0 0]} \n')
fprintf('\nTo submit 3 batch jobs, one to process the orbits between 2/10/2010 02:00:00 and 05:00:00\n')
fprintf('the second between 6/19/2010 02:00:00 and 05:00:00\n')
fprintf('and the second between 7/19/2010 02:00:00 and 05:00:00\n')
fprintf('\n')

periods_to_process = input('Enter the periods to process as indicated above: ');

Option = input('Enter 1, 2 or 3 for the computer you are using (Peter''s laptop, satdat1, AWS): ');

switch Option
    case 1 % Peter's laptop
        ProgDir = '/Users/petercornillon/MATLAB/Projects/MODIS_L2/';

    case 2 % satdat1
        ProgDir = '/Users/petercornillon/MATLAB/Projects/MODIS_L2/';

    case 3 % AWS
        ProgDir = '/home/ubuntu/Documents/MODIS_L2/';
end

addpath([ProgDir 'Main_Programs/'])
prj = openProject([ProgDir 'MODIS_L2.prj']);

for iJob=1:size(periods_to_process,1)
    job_number(iJob) = batch( 'build_wrapper', 0, {Option, periods_to_process{iJob,1}, periods_to_process{iJob,2}});
end