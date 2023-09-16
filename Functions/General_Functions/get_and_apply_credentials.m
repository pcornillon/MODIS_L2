function get_and_apply_credentials
% get_and_apply_credentials - will get the credentials to read NASA data from s3 in AWS - PCC 

% Get the credentials and put them in a file in the main directory.

! aws lambda invoke --function-name nasa_cred --payload file:///home/ubuntu/.modis_l2/pccc.json /home/ubuntu/credentials

% Open file with credentials and extract the needed stings.

fid = fopen('/home/ubuntu/credentials');
line_credentials = fgetl(fid);

nn = strfind( line_credentials , '"');
access_key = line_credentials(nn(7)+1:nn(8)-1);
secret_access_key = line_credentials(nn(11)+1:nn(12)-1);
session_token = line_credentials(nn(15)+1:nn(16)-1);

% apply them

setenv('AWS_ACCESS_KEY_ID', access_key); 
setenv('AWS_SECRET_ACCESS_KEY', secret_access_key);
setenv('AWS_SESSION_TOKEN', session_token); 
setenv('AWS_DEFAULT_REGION', 'us-west-2');

end