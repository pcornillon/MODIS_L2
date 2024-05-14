% read_and_plot_processing_times - PCC
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

% Specify the file name
filename = '/Users/petercornillon/Dropbox/Data/From_AWS/processing_times.txt';

% Open the file for reading
fileID = fopen(filename, 'r');

% Define the format for each line (4 integers/floats per line)
formatSpec = '%d %d %d %f';

% Read the data from the file using textscan
data = textscan(fileID, formatSpec);

% Close the file
fclose(fileID);

% Extract columns into separate variables (if needed)
iBatchJob = data{1}; % batch job index
iOrbit = data{2}; % orbit processed in this batch job
LinuxTime = data{3}; % time of processing in seconds since 1/1/1970
processingTime = data{4}; % time to process

% Alternatively, you can store the data in a matrix form like this:
resultMatrix = [iBatchJob, iOrbit, LinuxTime, processingTime];

% Convert seconds since 1/1/1970 to Matlab time. Subtract 4 hours for time
% zone difference (I think)

matTime = datetime( double(LinuxTime), 'ConvertFrom', 'posixtime') - 4 / 24;

% Now plot the data

figure(1)
plt = plot( matTime, processingTime, '.');
set(gca, fontsize=20)
grid on

xlabel('Time');
ylabel('Values');
title('Processing Time vs Time Processed');

% Optionally, customize the date format on the x-axis
ax = gca;
ax.XAxis.TickLabelFormat = 'yyyy-MM-dd HH:mm:ss';

% Improve the layout
datetick('x', 'yyyy-mm-dd HH:MM:SS', 'keepticks');

%% Now plot the a line from the first to the last time of each batch job

% BatchStart = nan(90,1);
% BatchEnd = BatchStart;

for jOrbit=1:length(iOrbit)
    for iBatch=1:90
        if iBatch == iBatchJob(jOrbit)
            if iOrbit(jOrbit) == 1
                BatchStart(iBatch) = datenum(matTime(jOrbit));
            else
                BatchEnd(iBatch) = datenum(matTime(jOrbit));
            end
        end
    end
end

% And plot

figure(2)
clf

for iBatch=1:90
    plot( [BatchStart(iBatch) BatchEnd(iBatch)], [1 1]*iBatch, 'k', linewidth=2)
end
figure(2);clf
for iBatch=1:90
    plot( [BatchStart(iBatch) BatchEnd(iBatch)], [1 1]*iBatch, 'k', linewidth=2)
    hold on
end

grid on
set(gca, fontsize=20)

xlabel('Time');
ylabel('Batch Job #');
title('Period of Processing');

% % Optionally, customize the date format on the x-axis
% ax = gca;
% ax.XAxis.TickLabelFormat = 'yyyy-MM-dd HH:mm:ss';
% % Improve the layout
% datetick('x', 'yyyy-mm-dd HH:MM:SS', 'keepticks');

%% Now calculate how many batch jobs are running at any given time.

startTime = floor(datenum(min(matTime)) * 24) / 24;
endTime = ceil(datenum(max(matTime)) * 24) / 24;

jTime = 0;

for iTime=startTime:1/24:endTime
    jTime = jTime + 1;
    
    nn = find( (iTime>datenum(BatchStart)) & (iTime<=datenum(BatchEnd)));
    
    newTime(jTime) = iTime;
    numJobs(jTime) = length(nn);
end
newTimep = datetime(datevec(newTime));

figure(1)
hold on

yyaxis right

plot( newTimep, numJobs, 'r')