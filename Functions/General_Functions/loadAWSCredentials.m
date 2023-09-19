function s3Credentials = loadAWSCredentials(daacCredentialsEndpoint, login, password)
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
end

