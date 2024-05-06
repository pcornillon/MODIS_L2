% simple_test.m -- just what it says - PCC
% prj=openProject('/Users/petercornillon/Git_repos/MODIS_L2/MODIS_L2.prj'); 
prj=openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj'); 
x = 3
job_number(1) = batch( 'simple_batch', 0, {5});
fprintf('simple_batch submitted.\n\n')

fprintf('Waiting for simple_batch.m to finish.\n\n')

job_number(1).wait();

fprintf('simple_batch.m is done.\n\n')