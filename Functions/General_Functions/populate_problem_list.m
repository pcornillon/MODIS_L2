function status = populate_problem_list( status, problem_description, granule_start_time)
% populate_problem_list - updates problem_list for this error/warning code - PCC
%
% This function get the index to use for this error/warning from
% problem_list.iProblem, increments it by 1, writes the new value back to
% problem_list.iProblem then writes the name of the file in which the
% problem occurred (passed in), the status passed in and the name of the 
% calling function; i.e., the function in which the error occured. 
%
% INPUT
%   status - the error/warning code to use. 
%   problem_description - Description of the problem.
%   granule_start_time - time of start of granule. Optional.
%
% OUTPUT
%   status - the status code passed in.
%
%  CHANGE LOG
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/21/2024 - Initial version - PCC
%   1.0.1 - 5/12/2024 - Modified to print out error messages that were,
%           previoulsy printed in the calling functions. This way the
%           printing code could be regularized. This assumes that there are
%           4 groups of errors, those with codes between 100 and 700,
%           between 700 and 800, 800 and 900 and > 900 - PCC

global version_struct
version_struct.find_next_granule_with_data = '1.2.0';

global oinfo iOrbit iGranule iProblem problem_list
global print_E100 print_E600 print_E700 print_E800 print_E900 

iProblem = iProblem + 1;

problem_list(iProblem).code = status;
problem_list(iProblem).problem_description = problem_description;

% In what function did the error occur?

st = dbstack;
problem_list(iProblem).calling_function = st(2).name;

% Add info about the orbit in which this problem occurs.

if iOrbit > 0
    if ~isempty(oinfo(iOrbit).name)
        problem_list(iProblem).orbit_name = oinfo(iOrbit).name;

        if ~isempty(oinfo(iOrbit).orbit_number)
            problem_list(iProblem).orbit_number = oinfo(iOrbit).orbit_number;
            problem_list(iProblem).orbit_start_time = oinfo(iOrbit).start_time;
        end

        if exist('iGranule')
            problem_list(iProblem).iGranule = iGranule;
        end
    end
end

if exist('granule_start_time')
    problem_list(iProblem).granule_start_time = granule_start_time;
end

%% Now print out to the terminal if print_E for this status is set.

if print_E100 & (status < 700)
    disp(['***11111*** status: ' num2str(status) ': ' problem_description])
end

if print_E600 & (600 <= status) & (status < 700)
    disp(['*** Skip granule *** status: ' num2str(status) ': ' problem_description])
end

if print_E700 & (700 <= status) & (status < 800)
    disp(['*** End orbit *** status: ' num2str(status) ': ' problem_description])
end

if print_E800 & (800 <= status) & (status < 900)
    disp(['*** Skip orbit *** status: ' num2str(status) ': ' problem_description])
end

if print_E900 & (900 <= status)
    disp(['*** End Run*** status: ' num2str(status) ': ' problem_description])
end

end

