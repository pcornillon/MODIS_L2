function [status, s3Credentials] = loadAWSCredentials(daacCredentialsEndpoint, login, password)
% loadAWSCredentials - requests access to NASA S3 data - PCC
%
% INPUT
%   daacCredentialsEndpoint - location of s3 credentials.
%   login - AWS login name, mine is pcornillon 
%   password - just what it says, password to my AWS account.
%
% OUTPUT
%   s3Credentials - Not sure what these are for, they are returned but the
%    script never uses them.
%
% EXAMPLE 
%
%   s3Credentials = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', MyPassword);
%
%  CHANGE LOG 
%   v. #  -  data    - description     - who
%
%   1.0.0 - 5/9/2024 - Initial version - PCC
%   1.0.1 - 5/9/2024 - Added line to update the time at which the
%           credentials were set - PCC
%   2.0.0 - 5/21/2024 - Updated error handling as we move from
%           granule_start_time to metadata granule list - PCC

global version_struct
version_struct.loadAWSCredentials = '2.0.0';

global s3_expiration_time

global iProblem problem_list 

numTriesThreshold = 10;

status = 0;
s3Credentials = [];

print_diagnostics = 1;

if nargin < 2 || isempty(login)
    login = getenv('EARTHDATA_LOGIN') ;
end
if nargin < 3 || isempty(password)
    password = getenv('EARTHDATA_PASSWORD') ;
end

% Initialize the number of tries
numTries = 0;

% Infinite loop to attempt fetching credentials

while true
    
    numTries = numTries + 1;
    
    try
        % Get S3 credentials from EarthData
        opts = weboptions('ContentType', 'json', 'HeaderFields', ...
            {'Authorization', ['Basic ',matlab.net.base64encode([login,':',password])]});
        s3Credentials = webread(daacCredentialsEndpoint, opts) ;
        
        % Set relevant environment variables with AWS credentials/region
        setenv('AWS_ACCESS_KEY_ID', s3Credentials.accessKeyId) ;
        setenv('AWS_SECRET_ACCESS_KEY', s3Credentials.secretAccessKey) ;
        setenv('AWS_SESSION_TOKEN',  s3Credentials.sessionToken) ;
        setenv('AWS_DEFAULT_REGION', 'us-west-2') ;
        
        % If successful, break out of the loop
        
        break;
        
    catch ME
        % Check if the number of tries has reached the threshold
        
        if numTries >= numTriesThreshold
            % Log the failure and exit the function
            
            status = populate_problem_list( 920, ['Failed ' num2str(numTries) ' times to get the NASA S3 credentials exiting this run.']); % old status 921
            return;
        else
            % Log the retry attempt and pause before the next attempt

            dont_use_status = populate_problem_list( 115, ['Failed to get the NASA S3 credentials at ' datetime '. This is try ' num2str(numTries) '. Will pause for 30 s and try again.']); % old status 270
            pause(30);
        end
    end
end

% Update the time at which the credentials were set to now.

s3_expiration_time = now;

end

