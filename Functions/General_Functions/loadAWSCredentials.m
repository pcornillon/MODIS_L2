function s3Credentials = loadAWSCredentials(daacCredentialsEndpoint, login, password)
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

global version_struct
version_struct.loadAWSCredentials = '1.0.1';

global s3_expiration_time

if nargin < 2 || isempty(login)
    login = getenv('EARTHDATA_LOGIN') ;
end
if nargin < 3 || isempty(password)
    password = getenv('EARTHDATA_PASSWORD') ;
end

% Get S3 credentials from EarthData
opts = weboptions('ContentType', 'json', 'HeaderFields', ...
    {'Authorization', ['Basic ',matlab.net.base64encode([login,':',password])]});
s3Credentials = webread(daacCredentialsEndpoint, opts) ;

% Set relevant environment variables with AWS credentials/region
setenv('AWS_ACCESS_KEY_ID', s3Credentials.accessKeyId) ;
setenv('AWS_SECRET_ACCESS_KEY', s3Credentials.secretAccessKey) ;
setenv('AWS_SESSION_TOKEN',  s3Credentials.sessionToken) ;
setenv('AWS_DEFAULT_REGION', 'us-west-2') ;

% Update the time at which the credentials were set to now.

s3_expiration_time = now;

end

