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


% Open the file for reading
fileID = fopen( filename, 'r');

% Define the format of the data (e.g., %s for string, %d for integer, %f for floating point)
formatSpec = '%i %i %i %i %i %i %i';  % Example format for a file with string and float data

% Read the file into a cell array
data = textscan(fileID, formatSpec);

% Close the file
fclose(fileID);

