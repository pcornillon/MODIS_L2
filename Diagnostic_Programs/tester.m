function tester(A)
% tester - a simple function to test batch job submission.
%

A2 = A^2;

fprintf('You passed %f into this function. It''s squared value is: %f at %s\n', A, A2, datetime)

% Pause for 3 minutes

pause(30)

A4 = A2^2;

fprintf('And the input to the 4th power is:  %f at %s\n', A4, datetime)
