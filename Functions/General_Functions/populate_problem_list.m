function status = populate_problem_list( status, problem_filename)
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
%   problem_filename - the name of the metadata or data file associated
%    with the error/waring. This name can be empty.
%
% OUTPUT
%   status - the status code passed in.
%

global oinfo iOrbit iGranule iProblem problem_list

iProblem = iProblem + 1;

problem_list(iProblem).filename = problem_filename;
problem_list(iProblem).code = status;

% In what function did the error occur?

st = dbstack;
problem_list(iProblem).calling_function = st(2).name;

end

