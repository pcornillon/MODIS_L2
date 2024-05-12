function setCredentialsTimeout( timeOut)
% setCredentialsTimeout - for NASA AWS s3 requests - PCC
%
% INPUT
%   timeOut in seconds.

fprint('\nSetting timeout for AWS NASA s3 credential request to %i s.\n', timeOut)

url = 'https://urs.earthdata.nasa.gov/oauth/authorize?client_id=HrBaq4rVeFgp2aOo6PoUxA&redirect_uri=https%3A%2F%2Farchive.podaac.earthdata.nasa.gov%2Fredirect&response_type=code&state=%2Fs3credentials';
options = weboptions('Timeout', timeOut);  % Set your desired timeout value in seconds
try
    data = webread(url, options);
    % Process the data as needed
catch ME
    disp(['Error occurred: ', ME.message]);
end

end