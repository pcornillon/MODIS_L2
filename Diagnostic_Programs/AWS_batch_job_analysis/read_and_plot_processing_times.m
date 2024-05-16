function [batch_job_no, orbit_index, matTime, processingTime, yFit] = read_and_plot_processing_times(AWS, BatchNo)
% function read_and_plot_processing_times(BatchNo) - to determine orbit processing times - PCC
%
% Open and read the processing table file written at AWS by reading the
% build_and_fix_orbit log files. This file contains a number for the batch
% job that processed the file, a number for the orbit processed, the
% processing time in seconds and the time since 1970,1,1 that the
% processing of the orbit was completed. Then plot the times to process
% versus the time processing was completed.
%
% The script to generate the table at AWS is MODIS_L2/Shell_scripts/generate processing_times_table.py
% To copy from AWS: scp ubuntu@ec2-52-11-152-158.us-west-2.compute.amazonaws.com:/mnt/uri-nfs-cornillon/Logs/processing_times.txt /Users/petercornillon/Dropbox/Data/From_AWS/
%
% INPUT
%   AWS: 1 if access to /Users/petercornillon/mnt/uri-nfs-cornillon/Logs, 0
%        for local access.
%   BatchNo: the number of the batch group to read.

% Specify the file name

if AWS
    filename = ['/Users/petercornillon/mnt/uri-nfs-cornillon/Logs/Batch-' num2str(BatchNo) '_processing_times.txt'];
    if exist(filename) ~= 2
        filename = ['/Users/petercornillon/mnt/uri-nfs-cornillon/Logs/Batch-' num2str(BatchNo) '/Batch-' num2str(BatchNo) '_processing_times.txt'];
    end
else
    filename = ['/Users/petercornillon/Dropbox/Data/From_AWS/Batch-' num2str(BatchNo) '_processing_times.txt'];
    if exist(filename) ~= 2
        filename = ['/Users/petercornillon/Dropbox/Data/From_AWS/Batch-' num2str(BatchNo) '/Batch-' num2str(BatchNo) '_processing_times.txt'];
    end
end

% Open the file for reading
fileID = fopen(filename, 'r');

% Define the format for each line (4 integers/floats per line)
formatSpec = '%d %d %d %f';

% Read the data from the file using textscan
data = textscan(fileID, formatSpec);

% Close the file
fclose(fileID);

% Extract columns into separate variables (if needed)
batch_job_no = data{1}; % batch job index
orbit_index = data{2}; % orbit processed in this batch job
LinuxTime = data{3}; % time of processing in seconds since 1/1/1970
processingTime = data{4} / 60; % time to process

% Alternatively, you can store the data in a matrix form like this:
resultMatrix = [batch_job_no, orbit_index, LinuxTime, processingTime];

% Convert seconds since 1/1/1970 to Matlab time. Subtract 4 hours for time
% zone difference (I think)

matTime = datetime( double(LinuxTime), 'ConvertFrom', 'posixtime') - 4 / 24;

% Get start and end time for the data processed thus far in this batch.

startTime = floor(datenum(min(matTime)) * 24) / 24;
endTime = ceil(datenum(max(matTime)) * 24) / 24;

% Write out some stats

hourThreshold = 6;

mm = find(datenum(matTime) < startTime+hourThreshold/24);
nn = find(datenum(matTime) > startTime+hourThreshold/24);

fprintf('\nFor the first      %i hours, the processing times average to: %5.1f +/- %3.1f minutes / orbit.\n', hourThreshold, mean(processingTime(mm)), std(processingTime(mm)))
fprintf('For the remaining %i hours, the processing times average to: %5.1f +/- %3.1f minutes / orbits.\n\n', floor(24*(endTime-startTime)-hourThreshold), mean(processingTime(nn)), std(processingTime(nn)))

% Now plot the data

figure(1)
clf

subplot(211)

plt = plot( matTime, processingTime, '.');
set(gca, fontsize=20)
grid on

xlabel('Date/Time');
ylabel('Processing Time (minutes)');
title('Processing Time vs Time Processed');

% % % Optionally, customize the date format on the x-axis
% % ax = gca;
% % ax.XAxis.TickLabelFormat = 'yyyy-MM-dd HH:mm:ss';
% % 
% % % Improve the layout
% % datetick('x', 'yyyy-mm-dd HH:MM:SS', 'keepticks');

%% Now plot the a line from the first to the last time of each batch job

for jOrbit=1:length(orbit_index)
    for iBatch=1:max(batch_job_no)
        if iBatch == batch_job_no(jOrbit)
            if orbit_index(jOrbit) == 1
                % BatchStart(iBatch) = datenum(matTime(jOrbit));
                BatchStart(iBatch) = matTime(jOrbit);
            else
                % BatchEnd(iBatch) = datenum(matTime(jOrbit));
                BatchEnd(iBatch) = matTime(jOrbit);
            end
        end
    end
end

% And plot

subplot(212)

for iBatch=1:max(batch_job_no)
    if datenum(BatchStart(iBatch)) ~= 0
        plot( [BatchStart(iBatch) BatchEnd(iBatch)], [iBatch iBatch], 'k', linewidth=2)
        hold on
    end
end

grid on
set(gca, fontsize=20)

xlabel('Date/Time');
ylabel('Batch Job #');
title('Period of Processing');

% % Optionally, customize the date format on the x-axis
% ax = gca;
% ax.XAxis.TickLabelFormat = 'yyyy-MM-dd HH:mm:ss';
% % Improve the layout
% datetick('x', 'yyyy-mm-dd HH:MM:SS', 'keepticks');

%% Now calculate how many batch jobs are running at any given time.

jTime = 0;

for iTime=startTime:1/(24*60):endTime
    jTime = jTime + 1;
    
    nn = find( (iTime>datenum(BatchStart)) & (iTime<=datenum(BatchEnd)));
    
    newTime(jTime) = iTime;
    numJobs(jTime) = length(nn);
    
%     meanProcessingTime(jTime) = mean( processingTime(nn), [], 'all', 'debug')
end
newTimep = datetime(datevec(newTime));

% Plot num batch jobs running versus time.

subplot(211)
hold on

yyaxis right
ylabel('Jobs Running')

plot( newTimep, numJobs, 'r')

% Find trend if any in processing time after the run settles down a bit.

nn = find(datenum(matTime) > startTime+hourThreshold/24);

pp = polyfit( datenum(matTime(nn)), processingTime(nn), 1);
yFit = polyval(pp, datenum(matTime(nn)));

min_per_day = (yFit(end) - yFit(1)) / ( datenum(matTime(nn(end))) - datenum(matTime(nn(1))));
fprintf('Processing time changes by %7.4f minutes per day between %s and %s\n\n', min_per_day, matTime(nn(1)), matTime(nn(end)))

% And plot this line.

subplot(211)
hold on

yyaxis left

hh = plot( matTime(nn), yFit, 'm', linewidth=2);

legend(hh, 'Best fit line to processing times')

