function tester(A)
% tester - a simple function to test batch job submission.
%

if A < 2
    ! touch /Users/petercornillon/Logs/proof_of_life_1
else
    ! touch /Users/petercornillon/Logs/proof_of_life_2
end

A2 = A^2;

fprintf('You passed %f into this function. It''s squared value is: %f\n', A, A2)
disp(['And with the disp command: You passed ' num2str(A) ' into this function. It''s squared value is: ' num2str(A2)])

% Pause for 3 minutes

% pause(30)

A4 = A2^2;

fprintf('And the input to the 4th power is:  %f\n', A4)
disp(['And with the disp command: And the input to the 4th power is: ' num2str(A4)])