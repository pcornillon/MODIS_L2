function [status, variable_read] = read_nc_variable( orbit_filename, variableName, month, year, data_dir, iBadOrbit, badOrbits, failure_mode, Time_of_orbit_extracted_from_title, fileOrbitNumber)
% read_nc_variable - if error save file with accumulated problems for this month - PCC.
%
% INPUT
%   orbit_filename - name of file from which to read.
%   month - being processed.
%   year - being processed.
%   data_dir - directory into which the output file with error info will be saved.
%   iBadOrbit - the index for the info about this file in structure badOrbits
%   badOrbits - the structure with the error info.
%   variableName - the name of the variable to be read from the netCDF file.
%
% OUTPUT
%   status - 0 if variable read properly. 1 if bad.
%   variable_read - ...

status = 0;

variable_read = '';
try
    % Attempt to read the netCDF file
    eval([ 'variableRead = ncread(''' orbit_filename ''',''' variableName ''');'])

catch ME
    status = 1;

    iBadOrbit = iBadOrbit + 1;

    badOrbits(iBadOrbit).filename = string(orbit_filename);
    badOrbits(iBadOrbit).failure_mode = failure_mode;
    badOrbits(iBadOrbit).filename_start_time = Time_of_orbit_extracted_from_title;
    badOrbits(iBadOrbit).file_orbit_number = fileOrbitNumber;

    reading_problem_filename = [data_dir 'bad_files/reading_problem_' return_a_string( 2, month) '_' num2str(year)];
    save([reading_problem_filename, 'badOrbits'])

    fprintf('%s.\n', failure_mode);
end
