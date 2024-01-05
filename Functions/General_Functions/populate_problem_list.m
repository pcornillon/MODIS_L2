function status = populate_problem_list( status, problem_description, granule_start_time_guess)
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
%   granule_start_time_guess - time of start of granule. Optional.
%
% OUTPUT
%   status - the status code passed in.
%

global oinfo iOrbit iGranule iProblem problem_list

iProblem = iProblem + 1;

problem_list(iProblem).problem_description = problem_description;
problem_list(iProblem).code = status;

if exist('granule_start_time_guess')
    problem_list(iProblem).granule_start_time = granule_start_time_guess;
end

% In what function did the error occur?

st = dbstack;
problem_list(iProblem).calling_function = st(2).name;

end

