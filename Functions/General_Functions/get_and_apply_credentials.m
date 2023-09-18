function get_and_apply_credentials(line_credentials)
% get_and_apply_credentials - will get the credentials to read NASA data from s3 in AWS - PCC 
%
% Use Angelina's function to get the credentials if no credentials are
% passed in otherwise, use the credentials passed in.
%
% INPUT
%   line_credentials - empty to reassign the credentials otherwise use
%    credentials obtained from the NASA Earth data search GUI.
%
% OUTPUT
%   none
%

% Remove previous credentials and unset environmental variables.
!rm /home/ubuntu/credentials

unsetenv('AWS_ACCESS_KEY_ID')
unsetenv('AWS_SECRET_ACCESS_KEY')
unsetenv('AWS_SESSION_TOKEN')
unsetenv('AWS_DEFAULT_REGION')

% Get the credentials and put them in a file in the main directory if line_credentials is empty.

if isempty(line_credentials)

    ! aws lambda invoke --function-name nasa_cred --payload file:///home/ubuntu/.modis_l2/pccc.json /home/ubuntu/credentials

    % Open file with credentials and extract the needed stings.

    fid = fopen('/home/ubuntu/credentials');
    line_credentials = fgetl(fid);

    nn_offset = 0;
else
    nn_offset = 4;
end

nn = strfind( line_credentials , '"');
access_key = line_credentials(nn(7-nn_offset)+1:nn(8-nn_offset)-1);
secret_access_key = line_credentials(nn(11-nn_offset)+1:nn(12-nn_offset)-1);
session_token = line_credentials(nn(15-nn_offset)+1:nn(16-nn_offset)-1);

% apply them

setenv('AWS_ACCESS_KEY_ID', access_key); 
setenv('AWS_SECRET_ACCESS_KEY', secret_access_key);
setenv('AWS_SESSION_TOKEN', session_token); 
setenv('AWS_DEFAULT_REGION', 'us-west-2');

end