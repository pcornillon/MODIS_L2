function [numOrbits, dataMatrix] = parse_file_list
% parse_file_list - to determine how many orbits have been processed by month - PCC
%
% Read the text list of orbit numbers, year and month for each dummy file
% written to /mnt/uri-nsf-cornill/. 
% Get the list of files on AWS as follows:
%
%   cd /mnt/uri-nfs-cornillon/
%   ls -lR SST > ./temp_list.txt
%
% Then copy the resulint file to my local disk. Go to ~/Dropbox/Data/From_AWS 
% and type the following:  
%
%   scp ubuntu@ec2-52-11-152-158.us-west-2.compute.amazonaws.com:/mnt/uri-nfs-cornillon/temp_list.txt /Users/petercornillon/Dropbox/Data/From_AWS/
%
% Finally, run the script with no arguments.
%
% INPUT
%   none
% 
% OUTPUT
%   numOrbits: number of orbits by year and month.
%   dataMatrix: structure. For each orbit grouped by year and month
%       orbit number
%       day
%       hour
%       minute 
%       second

filename = '/Users/petercornillon/Dropbox/Data/From_AWS/temp_list.txt';

% Read the data.

lines = readlines(filename);

% Initialize the results

numOrbits = zeros(23,12);

% Put orbit number, year and month in vectors.

% % % iOrbit = 1;
currentMonth = 0;
currentYear = 0;

for iLine=1:length(lines)

    temp_line = lines(iLine);

    if ~isempty(strfind(temp_line, 'AQUA_MODIS'))
        if ~isempty(strfind(temp_line, 'dummy'))
            % -rw-r--r-- 1 root   ubuntu    0 Jul 18 02:00 AQUA_MODIS_orbit_000886_20020704T003949_L2_SST-URI_24-1.dummy
            
            nn = strfind( temp_line, 'orbit_');
            temp_chars = char(temp_line);
            line_string = temp_chars(nn+6:end);

            currentOrbit = str2num(line_string(1:6));

            orbitS = line_string(1:6);
            orbit = str2num(orbitS);

            tempYear = str2num(line_string(8:11));
            tempMonth = str2num(line_string(12:13));

            % Count the number of orbits for this year/month

            if tempMonth ~= currentMonth
                currentMonth = tempMonth;
                currentMonthS = line_string(12:13);

                if tempYear ~= currentYear
                    currentYear = tempYear - 2000;
                    currentYearS = line_string(8:11);
                end
            end

            numOrbits( currentYear, currentMonth) = numOrbits( currentYear, currentMonth) + 1;
            iOrbit = numOrbits( currentYear, currentMonth);

            eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).orbits = str2num(line_string(1:6));'])
            eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).day = str2num(line_string(14:15));'])
            eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).hour = str2num(line_string(17:18));'])
            eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).minute = str2num(line_string(19:20));'])
            eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).second = str2num(line_string(21:22));'])
        end
    end
end

% % % currentOrbit = str2num(line_string(1:6));
% % % 
% % % currentYearS = line_string(8:11);
% % % currentMonthS = line_string(13:14);
% % % 
% % % currentYear = str2num(currentYearS) - 2000;
% % % currentMonth = str2num(currentMonthS);
% % % 
% % % numOrbits( currentYear, currentMonth) = 1;
% % % 
% % % eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).orbits = currentOrbit;'])
% % % eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).day = str2num(line_string(16:17));'])
% % % eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).hour = str2num(line_string(19:20));'])
% % % eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).minute = str2num(line_string(22:23));'])
% % % eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).second = str2num(line_string(25:26));'])
% % % 
% % % for iLine=2:length(lines)
% % % line_string = char(lines(iLine));
% % % 
% % %     currentOrbit = str2num(line_string(1:6));
% % % 
% % %     orbitS = line_string(1:6);
% % %     orbit = str2num(orbitS);
% % % 
% % %     tempYear = str2num(line_string(8:11));
% % %     tempMonth = str2num(line_string(13:14));
% % % 
% % %     % Count the number of orbits for this year/month
% % % 
% % %     if tempMonth ~= currentMonth
% % %         currentMonth = tempMonth;
% % % 
% % %         if tempYear ~= currentYear
% % %             currentYear = tempYear - 2000;
% % %         end
% % %     end
% % % 
% % %     numOrbits( currentYear, currentMonth) = numOrbits( currentYear, currentMonth) + 1;
% % %     iOrbit = numOrbits( currentYear, currentMonth);
% % % 
% % %     eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).orbits = str2num(line_string(1:6));'])
% % %     eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).day = str2num(line_string(16:17));'])
% % %     eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).hour = str2num(line_string(19:20));'])
% % %     eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).minute = str2num(line_string(22:23));'])
% % %     eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).second = str2num(line_string(25:26));'])
% % % end

