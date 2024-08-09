function parse_file_list(filename)
% parse_file_list - to determine how many orbits have been processed by month - PCC
%
% Read the text list of orbit numbers, year and month for each dummy file
% written to /mnt/uri-nsf-cornill/. Get the list of files with:
%   ls -lR SST > ./temp_list.txt
% Then parse the list in Aquamacs with a mess of c-x ( ... c-x ) commands.
% The final list should have the orbit number, year, month, day, ... like this:
%  000886 2002 07 04 00 39 49
%  000887 2002 07 04 02 18 41
%  000888 2002 07 04 03 57 35

%
% INPUT
%   filename: Name of file with the list described above.
% 
% OUTPUT

% Read the data.

lines = readlines(filename);

% Initialize the results

numOrbits = zeros(23,12);

% Put orbit number, year and month in vectors.

iOrbit = 1;

line_string = char(lines(1));

currentOrbit = str2num(line_string(1:6));

currentYearS = line_string(8:11);
currentMonthS = line_string(13:14);

currentYear = str2num(currentYearS) - 2000;
currentMonth = str2num(currentMonthS);

numOrbits( currentYear, currentMonth) = 1;

eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).orbits = currentOrbit;'])
eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).day = str2num(line_string(16:17));'])
eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).hour = str2num(line_string(19:20));'])
eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).minute = str2num(line_string(22:23));'])
eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).second = str2num(line_string(25:26));'])

for iLine=2:length(lines)
    line_string = char(lines(iLine));

    currentOrbit = str2num(line_string(1:6));
    
    orbitS = line_string(1:6);
    orbit = str2num(orbitS);

    tempYear = str2num(line_string(8:11));
    tempMonth = str2num(line_string(13:14));

    % Count the number of orbits for this year/month

    if tempMonth ~= currentMonth
        currentMonth = tempMonth;
    
        if tempYear ~= currentYear
            currentYear = tempYear - 2000;
        end
    end

    numOrbits( currentYear, currentMonth) = numOrbits( currentYear, currentMonth) + 1;
    iOrbit = numOrbits( currentYear, currentMonth);

    eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).orbits = str2num(line_string(1:6));'])
    eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).day = str2num(line_string(16:17));'])
    eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).hour = str2num(line_string(19:20));'])
    eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).minute = str2num(line_string(22:23));'])
    eval([ 'dataMatrix.y' currentYearS '.m' currentMonthS '(iOrbit).second = str2num(line_string(25:26));'])
end

