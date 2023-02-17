function [Status, along_scan_seps_array, along_track_seps_array] = ...
    write_sep_and_angle_arrays( output_filename, file_list, longitude, latitude, scan_angle, ...
    along_scan_seps, along_track_seps, min_along_scan_factor, min_along_track_factor, ...
    smoothed_min_along_scan_factor, smoothed_min_along_track_factor)
% write_sep_and_angle_arrays - will create a file and write out the separation and angle arrays for canonical MODIS orbit - PCC
%
% This function writes the refined mask created by Fix_MODIS_Mask to a
% netCDF file. The objective of the mask is to unflag as bad pixels
% mistakenly flagged as cloudy because of 'high' variability in the local
% field. In addition to writing out the mask, the function reads the global
% attributes and, those relevant to this mask, are written to the netCDF
% file.
%
% This function will also write the mask read from the input file (from
% GSFC) for pixels flagged as bad because of SST difference between the
% retrieved value and a reference field.
%
% It will also write the mask generated in Fix_MODIS_Mask based on the
% SST magnitude of the difference between the retrieved value and the
% reference field but for which the threshold depends on location and
% month. This threshold was determined from 128x128 pixel regions that were
% at least 95% clear. The maximum difference determined from these fields
% for the MODIS Aqua archive - 2003-2019.
%
% Note that MODIS scanss east-to-west for the satellite south-to-north. If 
% the scan direction is chosen as x, this defines a left-handed coordinate 
% system if forward motion of the satellite is positive so we choose the 
% along-track direction to be the x-direction, then the sensor scans in the 
% positive y direction and we have a right handed coordinate system. For
% this reason we provide arrays for both the angle, counter-clockwise from
% east of the scan vector (positive in the direction of scan) and the track
% vector (positive in the direction in which the satellite is traveling).
% To map along-scan and along track gradients to eastward and northward use: 
%
% grad_lon_per_km = grad_at_per_km .* cosd(at_ang) - grad_as_per_km .* sin(at_ang);
% grad_lat_per_km = grad_at_per_km .* sind(at_ang) + grad_as_per_km .* cosd(at_ang);
%
% where _at_ is along-track, _as_ is along scan.
%
% INPUT
%   file_list - the list of files that went into the construction of the
%    along-scan, along-track and angle arrays.
%   output_filename - the fully specified output filename
%   longitude - longitude array of canonical orbit.
%   latitude - latitude array of canonical orbit.
%   scan_angle - angle of scan line counter-clockwise from east.
%   along_scan_seps - vector of separations between pixels in the
%    along-scan direction averaged in the along-track direction.
%   along_track_seps - vector of separations between pixels in the
%    along-track direction averaged in the along-track direction.
%   min_along_scan_factor - for each scan line the factor minimizing the
%    squared difference between the vector of along-scan separations and
%    the along-scan separations averaged over orbits on the file list.
%   min_along_track_factor - for each scan line the factor minimizing the
%    squared difference between the vector of along-track separations and
%    the along-track separations averaged over orbits on the file list.
%   smoothed_min_along_scan_factor - min_along_scan_factor gaussian
%    smoothed over 1000 scan lines.
%   smoothed_min_along_track_factor - min_along_track_factor gaussian
%    smoothed over 1000 scan lines.
%
% OUTPUT
%   Status - 1 if all operations ended successfully; 0 otherwise.
%   along_scan_seps_array - reconstructed array of along-scan
%    separations. Reconstructed from along_scan_seps and
%    min_along_scan_factor.
%   along_track_seps_array - reconstructed array of along-track
%    separations.
%
%  CHANGE LOG
%
%   Version 1.00
%
%   1/17/2023 - PCC - Wrote the function
%

Status = 0;

% Get the dimensions of the input fields.

[nxDimension, nyDimension] = size(scan_angle);

% Defin the fill values.

fill_value_byte = int8(-1);
fill_value_int16 = int16(-32767);
fill_value_single = single(-999);

% Create separation arrays.

along_scan_seps_array =  along_scan_seps * smoothed_min_along_scan_factor;
along_track_seps_array =  along_track_seps * smoothed_min_along_track_factor;

%% Create and write the separation and angle files ***********

% Create and write the list of file_names ************************

% First need to convert the string array to a character array.

for iFileName=1:length(file_list)
    filenames(iFileName,:) = [file_list(iFileName).folder '/' file_list(iFileName).name];
end
[dim1, dim2] = size(filenames);

nccreate( output_filename, 'file_list', 'Datatype', 'char', ...
    'Dimensions', {'dim1' dim1 'dim2' dim2})
ncwriteatt( output_filename, 'file_list', 'long_name', 'list of filenames used')
ncwriteatt( output_filename, 'file_list',  'standard_name', 'file_list')

ncwrite(  output_filename, 'file_list', filenames)

% Create and write longitude ************************

nccreate( output_filename, 'longitude', 'Datatype', 'single', ...
    'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
    'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], 'Deflatelevel', 4,'FillValue',fill_value_single)
ncwriteatt( output_filename, 'longitude', 'long_name', 'longitude')
ncwriteatt( output_filename, 'longitude',  'standard_name', 'longitude')
ncwriteatt( output_filename, 'longitude', 'units', 'degrees_east')
ncwriteatt( output_filename, 'longitude',  'valid_min',  '-180')
ncwriteatt( output_filename, 'longitude',  'valid_max',  '180')

ncwrite(  output_filename, 'longitude', longitude)

% Create and write latitude ************************

nccreate( output_filename, 'latitude', 'Datatype', 'single', ...
    'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
    'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], 'Deflatelevel', 4, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'latitude', 'long_name', 'Latitude')
ncwriteatt( output_filename, 'latitude',  'standard_name', 'latitude')
ncwriteatt( output_filename, 'latitude', 'units', 'degrees_north')
ncwriteatt( output_filename, 'latitude',  'valid_min',  '-90')
ncwriteatt( output_filename, 'latitude',  'valid_max',  '90')

ncwrite(  output_filename, 'latitude', latitude)

% Create and write scan angle  ************************

nccreate( output_filename, 'scan_angle', 'Datatype', 'single', ...
    'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
    'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], 'Deflatelevel', 4, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'scan_angle', 'long_name', 'scan_angle')
ncwriteatt( output_filename, 'scan_angle',  'standard_name', 'scan_angle')
ncwriteatt( output_filename, 'scan_angle', 'units', 'degrees counterclockwise from east')
ncwriteatt( output_filename, 'scan_angle',  'valid_min',  '0')
ncwriteatt( output_filename, 'scan_angle',  'valid_max',  '360')

ncwrite(  output_filename, 'scan_angle', scan_angle)

% Create and write track angle  ************************

% First, get the angle the track-line makes counter-clockwise from east and
% set values less than 0 to the value +360 degrees. Track angles will then
% be in the range from 0 to 360.

track_angle = scan_angle - 90;
track_angle(track_angle<0) = track_angle(track_angle<0) + 360;

nccreate( output_filename, 'track_angle', 'Datatype', 'single', ...
    'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
    'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], 'Deflatelevel', 4, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'track_angle', 'long_name', 'track_angle')
ncwriteatt( output_filename, 'track_angle',  'standard_name', 'track_angle')
ncwriteatt( output_filename, 'track_angle', 'units', 'degrees counterclockwise from east')
ncwriteatt( output_filename, 'track_angle',  'valid_min',  '0')
ncwriteatt( output_filename, 'track_angle',  'valid_max',  '360')

ncwrite(  output_filename, 'track_angle', track_angle)

% Create and write along_track_seps_array ************************

nccreate( output_filename, 'along_scan_seps_array', 'Datatype', 'single', ...
    'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
    'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], 'Deflatelevel', 4, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'along_scan_seps_array', 'long_name', 'orbital array of pixel separations in the along-scan direction')
ncwriteatt( output_filename, 'along_scan_seps_array',  'standard_name', 'along_scan_separations')
ncwriteatt( output_filename, 'along_scan_seps_array',  'units',  'km')
ncwriteatt( output_filename, 'along_scan_seps_array',  'valid_min',  '0.5')
ncwriteatt( output_filename, 'along_scan_seps_array',  'valid_max',  '12')

ncwrite(  output_filename, 'along_scan_seps_array', along_scan_seps_array)

% Create and write along_track_seps_array ************************

nccreate( output_filename, 'along_track_seps_array', 'Datatype', 'single', ...
    'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
    'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], 'Deflatelevel', 4, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'along_track_seps_array', 'long_name', 'orbital array of pixel separations in the along-track direction')
ncwriteatt( output_filename, 'along_track_seps_array',  'standard_name', 'along_track_separations')
ncwriteatt( output_filename, 'along_track_seps_array',  'units',  'km')
ncwriteatt( output_filename, 'along_track_seps_array',  'valid_min',  '0.7')
ncwriteatt( output_filename, 'along_track_seps_array',  'valid_max',  '1.2')

ncwrite(  output_filename, 'along_track_seps_array', along_track_seps_array)

% Create and write along_scan_seps_vector ************************

nccreate( output_filename, 'along_scan_seps_vector', 'Datatype', 'single', ...
    'Dimensions', {'nx' nxDimension}, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'along_scan_seps_vector', 'long_name', 'orbital average of pixel separation in the along-scan direction')
ncwriteatt( output_filename, 'along_scan_seps_vector', 'standard_name', 'scan_line_along_scan_separation')
ncwriteatt( output_filename, 'along_scan_seps_vector',  'units',  'km')
ncwriteatt( output_filename, 'along_scan_seps_vector',  'valid_min',  '0')
ncwriteatt( output_filename, 'along_scan_seps_vector',  'valid_max',  '12')

ncwrite(  output_filename, 'along_scan_seps_vector', along_scan_seps)

% Create and write along_track_seps_vector ************************

nccreate( output_filename, 'along_track_seps_vector', 'Datatype', 'single', ...
    'Dimensions', {'nx' nxDimension}, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'along_track_seps_vector', 'long_name', 'orbital average of pixel separation in the along-scan direction')
ncwriteatt( output_filename, 'along_track_seps_vector',  'standard_name', 'scan_line_along_track_separation')
ncwriteatt( output_filename, 'along_track_seps_vector',  'units',  'km')
ncwriteatt( output_filename, 'along_track_seps_vector',  'valid_min',  '0.7')
ncwriteatt( output_filename, 'along_track_seps_vector',  'valid_max',  '1.2')

ncwrite(  output_filename, 'along_track_seps_vector', along_track_seps)

% Create and write along_scan_factor ************************

nccreate( output_filename, 'along_scan_factor', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'along_scan_factor', 'long_name', 'along scan factor')
ncwriteatt( output_filename, 'along_scan_factor',  'standard_name', 'along_scan_factor')
ncwriteatt( output_filename, 'along_scan_factor',  'units',  'km')
ncwriteatt( output_filename, 'along_scan_factor',  'valid_min',  '0.9')
ncwriteatt( output_filename, 'along_scan_factor',  'valid_max',  '1.1')

ncwrite(  output_filename, 'along_scan_factor', min_along_scan_factor)

% Create and write along_track_factor ************************

nccreate( output_filename, 'along_track_factor', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'along_track_factor', 'long_name', 'along track factor')
ncwriteatt( output_filename, 'along_track_factor',  'standard_name', 'along_track_factor')
ncwriteatt( output_filename, 'along_track_factor',  'units',  'km')
ncwriteatt( output_filename, 'along_track_factor',  'valid_min',  '0.9')
ncwriteatt( output_filename, 'along_track_factor',  'valid_max',  '1.1')

ncwrite(  output_filename, 'along_track_factor', min_along_track_factor)

% Create and write smoothed_along_scan_factor ************************

nccreate( output_filename, 'smoothed_along_scan_factor', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'smoothed_along_scan_factor', 'long_name', 'along scan factor')
ncwriteatt( output_filename, 'smoothed_along_scan_factor',  'standard_name', 'smoothed_along_scan_factor')
ncwriteatt( output_filename, 'smoothed_along_scan_factor',  'units',  'km')
ncwriteatt( output_filename, 'smoothed_along_scan_factor',  'valid_min',  '0.9')
ncwriteatt( output_filename, 'smoothed_along_scan_factor',  'valid_max',  '1.1')

ncwrite(  output_filename, 'smoothed_along_scan_factor', smoothed_min_along_scan_factor)

% Create and write smoothed_along_track_factor ************************

nccreate( output_filename, 'smoothed_along_track_factor', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single)
ncwriteatt( output_filename, 'smoothed_along_track_factor', 'long_name', 'along track factor')
ncwriteatt( output_filename, 'smoothed_along_track_factor',  'standard_name', 'smoothed_along_track_factor')
ncwriteatt( output_filename, 'smoothed_along_track_factor',  'units',  'km')
ncwriteatt( output_filename, 'smoothed_along_track_factor',  'valid_min',  '0.9')
ncwriteatt( output_filename, 'smoothed_along_track_factor',  'valid_max',  '1.1')

ncwrite(  output_filename, 'smoothed_along_track_factor', smoothed_min_along_track_factor)

%% Now for the global attributes.

% GlobalAttributes = ncinfo(file_in);

ncwriteatt(output_filename, '/', 'Title', 'Separation and Angle Arrays');

ncwriteatt(output_filename, '/', 'Summary', ['Canonical separations and anlges are generated for MODIS in a three step ', ...
    'process. The input to the algorithm is a set of complete orbits generated by build_and_fix_orbits, which saves the ', ...
    'regridded lat, lon and SST. The script does the following for each complete orbit. Fiftyfour 40,270 scan line orbits ', ...
    'were used to generate this set of along-scan, along-track and scan and track line angle orbital arrays. The overall ', ...
    'idea is that the separations in the along-scan and along-track directions are very similar for all scan lines, the ', ...
    'only difference being in a slight scale factor due to the height of the satellite and anomalies resulting from land. ', ...
    'Steps 1 and 2 obtain a pretty smoothed version of the separation fields. Step 3 obtains a final smoothed version and ', ...
    'addresses variations due to satellite height. More details are provide in the script performing these tasks.']);

ncwriteatt(output_filename, '/', 'creation_date', datestr(now));

% ncwriteatt(output_filename, '/', 'product_name', 'Separation and Angle Arrays');

ncwriteatt(output_filename, '/', 'processing_version', '1.0');

% history = [GlobalAttributes.Attributes(iAttribute).Value ' Fix_MODIS_Mask'];
% ncwriteatt(output_filename, '/', 'history', history);

ncwriteatt(output_filename, '/', 'license', 'None');

ncwriteatt(output_filename, '/', 'institution', 'University of Rhode Island, Graduate School of Oceanography');

ncwriteatt(output_filename, '/', 'creator_name', 'Peter Cornillon');

ncwriteatt(output_filename, '/', 'creator_email', 'pcornillon@uri.edu');

ncwriteatt(output_filename, '/', 'creator_url', 'https://web.uri.edu/gso/meet/peter-cornillon/');

ncwriteatt(output_filename, '/', 'project', 'Evaluate the temporal and spatial variability of the SST gradient field in the Arctic and sub-Arctic');
