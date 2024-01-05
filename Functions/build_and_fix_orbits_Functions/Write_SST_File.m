function Write_SST_File( longitude, latitude, SST_In, qual_sst, SST_In_Masked, refined_mask, scan_seconds_from_start, ...
    regridded_longitude, regridded_latitude, regridded_sst, easting, northing, regridded_easting, regridded_northing, ...
    regridded_sst_alternate, along_scan_gradient, along_track_gradient, grad_lon_per_km, grad_lat_per_km, Fix_MODIS_Mask_number, ...
    region_start, region_end, fix_mask, fix_bowtie, regrid_sst, get_gradients)
% Write_SST_File - will create and write a file for the gradient/fronts workflow SST and mask data - PCC
%
% The SST field (raw), SST_In, passed in is masked based on refined_mask,
% also passed in. refined_mask is a 0/1 field, 0s being good SSTs. Pixels in
% sst_in_masked corresponding to those in refined_mask set to 1 are set to nan. This
% field is written out to the file.
%
% This function also generates the bulk of the metadata used in the Fronts/
% Gradients workflow, the metadata that will be passed from file to file.
%
% INPUT
%   base_dir - the location to which this file is to be written.
%   sst_in_masked - the raw SST read in.
%   refined_mask - the refined mask.
%   Fix_MODIS_Mask_number - the version of Fix_MODIS_Mask used to create
%    the median SST field written by this function.'
%   time_coverage_start - The time this granule or orbit started.
%   north_lat_limit, south_lat_limit
%   fix_mask - if 1 fixes the mask. If absent, will set to 1.
%   fix_bowtie - if 1 fixes the bow-tie problem, otherwise bow-tie effect
%    not fixed.
%   regrid_sst - 1 to regrid SST, 0 to return SST_In without regridding.
%   get_gradients - 1 to calculate eastward and northward gradients, 0
%    otherwise.
%
% OUTPUT
%   Status - 1 if all operations ended successfully; 0 otherwise.
%
%  CHANGE LOG
%
%   Version 1.00
%
%   6/6/2021 - PCC - Original version of this function.
%
%   Version 3.00
%
%   3/26/2022 - PCC - Major modifications to include other variables.

% globals for the run as a whole.

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory_local output_file_directory_remote
global print_diagnostics print_times debug regridded_debug
global npixels

% globals for build_orbit part.

global save_just_the_facts amazon_s3_run
global formatOut
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length secs_per_granule_minus_10 
global index_of_NASA_orbit_change possible_num_scan_lines_skip
global sltimes_avg nlat_orbit nlat_avg orbit_length
global latlim
global sst_range sst_range_grid_size

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t
global Matlab_start_time Matlab_end_time

% globals used in the other major functions of build_and_fix_orbits.

global med_op

global mem_count mem_orbit_count mem_print print_dbStack mem_struct

global determine_fn_size

if determine_fn_size; get_job_and_var_mem; end

output_filename = oinfo(iOrbit).name;

% Initialize variables.

[nxDimension, nyDimension] = size(SST_In);
nadir_x = floor(nxDimension / 2);

% Defin the fill values.

fill_value_byte = int8(-1);
fill_value_int16 = int16(-32767);
fill_value_single = single(-999);
fill_value_int32 = -2147483647;

sstFillValue = fill_value_int16;
sstScaleFactor = 0.005;
LatLonScaleFactor = 0.001;
gradientScaleFactor = 0.0001;

% Write dummy file to use in search for files already processed since
% we will move processed files to URI soon after they have been written
% and then delete to save space. The dummy files will remain indicating
% that the orbit has been processed.

eval(['! touch ' strrep( output_filename, '.nc4', '.dummy')])

%% Create the variables to be written out along with their attributes and write them. Start with main variable.

if regrid_sst == 0

    % SST_In - SST in the original granules.
    
    nccreate( output_filename, 'SST_In', 'Datatype', 'int16', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4,'FillValue', sstFillValue, 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'SST_In', 'long_name', 'sst')
    ncwriteatt( output_filename, 'SST_In',  'standard_name', 'sea_surface_temperature')
    ncwriteatt( output_filename, 'SST_In', 'units', 'C')
    ncwriteatt( output_filename, 'SST_In', 'add_offset', 0)
    ncwriteatt( output_filename, 'SST_In', 'scale_factor', sstScaleFactor)
    ncwriteatt( output_filename, 'SST_In',  'valid_min', -600)
    ncwriteatt( output_filename, 'SST_In',  'valid_max', 9000)
    
    ncwrite( output_filename, 'SST_In', SST_In)
    
    % qual_sst - quality in the original granules.
    
    nccreate( output_filename, 'qual_sst', 'Datatype', 'int8', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4,'FillValue', -1, 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'qual_sst', 'long_name', 'Quality Levels, Sea Surface Temperature')
    ncwriteatt( output_filename, 'qual_sst',  'standard_name', 'sea_surface_temperature')
    ncwriteatt( output_filename, 'qual_sst', 'flag_masks', [0  1  2  3  4])
    ncwriteatt( output_filename, 'qual_sst', 'flag_meanings', 'BEST GOOD QUESTIONABLE BAD NOTPROCESSED')
    ncwriteatt( output_filename, 'qual_sst',  'valid_min', 0)
    ncwriteatt( output_filename, 'qual_sst',  'valid_max', 5)
    
    ncwrite( output_filename, 'qual_sst', qual_sst)
end

if save_just_the_facts == 0

    % longitude
    
    nccreate( output_filename, 'longitude', 'Datatype', 'int32', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'longitude', 'long_name', 'Longitude')
    ncwriteatt( output_filename, 'longitude',  'standard_name', 'longitude')
    ncwriteatt( output_filename, 'longitude', 'units', 'degrees_east')
    ncwriteatt( output_filename, 'longitude', 'add_offset', 0)
    ncwriteatt( output_filename, 'longitude', 'scale_factor', LatLonScaleFactor)
    ncwriteatt( output_filename, 'longitude', 'valid_min', -180000)
    ncwriteatt( output_filename, 'longitude', 'valid_max', 1800000)
    
    ncwrite(  output_filename, 'longitude', longitude)
    
    % latitude
    
    nccreate( output_filename, 'latitude', 'Datatype', 'int32', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'latitude', 'long_name', 'latitude')
    ncwriteatt( output_filename, 'latitude',  'standard_name', 'latitude')
    ncwriteatt( output_filename, 'latitude', 'units', 'degrees_north')
    ncwriteatt( output_filename, 'latitude', 'add_offset', 0)
    ncwriteatt( output_filename, 'latitude', 'scale_factor', LatLonScaleFactor)
    ncwriteatt( output_filename, 'latitude', 'valid_min', -90000)
    ncwriteatt( output_filename, 'latitude', 'valid_max', 90000)
    
    ncwrite(  output_filename, 'latitude', latitude)
    
    % SST_In_Masked - SST_In with the refined mask applied. Still with bowtie issues.
    
    nccreate( output_filename, 'SST_In_Masked', 'Datatype', 'int16', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4,'FillValue', sstFillValue, 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'SST_In_Masked', 'long_name', 'sst')
    ncwriteatt( output_filename, 'SST_In_Masked',  'standard_name', 'sea_surface_temperature')
    ncwriteatt( output_filename, 'SST_In_Masked', 'units', 'C')
    ncwriteatt( output_filename, 'SST_In_Masked', 'add_offset', 0)
    ncwriteatt( output_filename, 'SST_In_Masked', 'scale_factor', sstScaleFactor)
    ncwriteatt( output_filename, 'SST_In_Masked',  'valid_min', -600)
    ncwriteatt( output_filename, 'SST_In_Masked',  'valid_max', 9000)
    
    ncwrite( output_filename, 'SST_In_Masked', SST_In_Masked)
end

if fix_mask
    
    % refined_mask - the mask with high gradient and reference SST issues fixed
    
    nccreate( output_filename, 'refined_mask', 'Datatype', 'int8', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4,'FillValue',fill_value_byte, 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'refined_mask', 'long_name', 'mask for original high gradient values set to 0')
    ncwriteatt( output_filename, 'refined_mask',  'standard_name', 'mask_for_original_high_gradient_values_set_to_0')
    ncwriteatt( output_filename, 'refined_mask', 'flag_masks', [0  1])
    ncwriteatt( output_filename, 'refined_mask', 'flag_meanings', 'Good Bad')
    ncwriteatt( output_filename, 'refined_mask',  'valid_min', 0)
    ncwriteatt( output_filename, 'refined_mask',  'valid_max', 1)
    
    ncwrite(  output_filename, 'refined_mask', int8(refined_mask))
end

if fix_bowtie
    
    if regrid_sst == 1
        % regridded_sst - the input SST masked with the refined mask and then fixed for the bowtie effect.
        
        nccreate( output_filename, 'regridded_sst', 'Datatype', 'int16', ...
            'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
            'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
            'Deflatelevel', 4,'FillValue', sstFillValue, 'Format', 'netcdf4')
        
        ncwriteatt( output_filename, 'regridded_sst', 'long_name', 'regridded_sst')
        ncwriteatt( output_filename, 'regridded_sst',  'standard_name', 'masked_sea_surface_temperature')
        ncwriteatt( output_filename, 'regridded_sst', 'units', 'C')
        ncwriteatt( output_filename, 'regridded_sst', 'add_offset', 0)
        ncwriteatt( output_filename, 'regridded_sst', 'scale_factor', sstScaleFactor)
        ncwriteatt( output_filename, 'regridded_sst',  'valid_min', -600)
        ncwriteatt( output_filename, 'regridded_sst',  'valid_max', 9000)
        
        ncwrite( output_filename, 'regridded_sst', regridded_sst)

        if regridded_debug
            % regridded_sst_alternate - the input SST masked with the alternate refined mask and then fixed for the bowtie effect.
            
            nccreate( output_filename, 'regridded_sst_alternate', 'Datatype', 'int16', ...
                'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
                'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
                'Deflatelevel', 4,'FillValue', sstFillValue, 'Format', 'netcdf4')
            
            ncwriteatt( output_filename, 'regridded_sst_alternate', 'long_name', 'regridded_sst_alternate')
            ncwriteatt( output_filename, 'regridded_sst_alternate',  'standard_name', 'masked_alternat_sea_surface_temperature')
            ncwriteatt( output_filename, 'regridded_sst_alternate', 'units', 'C')
            ncwriteatt( output_filename, 'regridded_sst_alternate', 'add_offset', 0)
            ncwriteatt( output_filename, 'regridded_sst_alternate', 'scale_factor', sstScaleFactor)
            ncwriteatt( output_filename, 'regridded_sst_alternate',  'valid_min', -600)
            ncwriteatt( output_filename, 'regridded_sst_alternate',  'valid_max', 9000)
            
            ncwrite( output_filename, 'regridded_sst_alternate', regridded_sst_alternate)
        end
    end
    
    % regridded_longitude
    
    nccreate( output_filename, 'regridded_longitude', 'Datatype', 'int32', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'regridded_longitude', 'long_name', 'regridded_longitude')
    ncwriteatt( output_filename, 'regridded_longitude',  'standard_name', 'regridded_longitude')
    ncwriteatt( output_filename, 'regridded_longitude', 'units', 'degrees_east')
    ncwriteatt( output_filename, 'regridded_longitude', 'add_offset', 0)
    ncwriteatt( output_filename, 'regridded_longitude', 'scale_factor', LatLonScaleFactor)
    ncwriteatt( output_filename, 'regridded_longitude', 'valid_min', -180000)
    ncwriteatt( output_filename, 'regridded_longitude', 'valid_max', 1800000)
    
    ncwrite(  output_filename, 'regridded_longitude', regridded_longitude)
    
    % regridded_latitude
    
    nccreate( output_filename, 'regridded_latitude', 'Datatype', 'int32', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'regridded_latitude', 'long_name', 'regridded_latitude')
    ncwriteatt( output_filename, 'regridded_latitude',  'standard_name', 'regridded_latitude')
    ncwriteatt( output_filename, 'regridded_latitude', 'units', 'degrees_north')
    ncwriteatt( output_filename, 'regridded_latitude', 'add_offset', 0)
    ncwriteatt( output_filename, 'regridded_latitude', 'scale_factor', LatLonScaleFactor)
    ncwriteatt( output_filename, 'regridded_latitude', 'valid_min', -90000)
    ncwriteatt( output_filename, 'regridded_latitude', 'valid_max', 90000)
    
    ncwrite(  output_filename, 'regridded_latitude', regridded_latitude)
    
    if save_just_the_facts == 0
        % region_start
        
        nccreate( output_filename, 'region_start', 'Datatype', 'int32', ...
            'Dimensions', {'i' 4}, 'Format', 'netcdf4')
        
        ncwriteatt( output_filename, 'region_start', 'long_name', 'region_start')
        ncwriteatt( output_filename, 'region_start', 'standard_name', 'region_start')
        ncwriteatt( output_filename, 'region_start', 'valid_min', 0)
        ncwriteatt( output_filename, 'region_start', 'valid_max', 50000)
        
        ncwrite(  output_filename, 'region_start', int32(region_start))
        
        % region_end
        
        nccreate( output_filename, 'region_end', 'Datatype', 'int32', ...
            'Dimensions', {'i' 4}, 'Format', 'netcdf4')
        
        ncwriteatt( output_filename, 'region_end', 'long_name', 'region_end')
        ncwriteatt( output_filename, 'region_end', 'standard_name', 'region_end')
        ncwriteatt( output_filename, 'region_end', 'valid_min', 0)
        ncwriteatt( output_filename, 'region_end', 'valid_max', 50000)
        
        ncwrite(  output_filename, 'region_end', int32(region_end))
        
        % easting
        
        nccreate( output_filename, 'easting', 'Datatype', 'int32', ...
            'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
            'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
            'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
        
        ncwriteatt( output_filename, 'easting', 'long_name', 'easting')
        ncwriteatt( output_filename, 'easting', 'standard_name', 'easting')
        ncwriteatt( output_filename, 'easting', 'units', 'km/east')
        ncwriteatt( output_filename, 'easting', 'add_offset', 0)
        ncwriteatt( output_filename, 'easting', 'scale_factor', 1)
        ncwriteatt( output_filename, 'easting', 'valid_min', -1000000)
        ncwriteatt( output_filename, 'easting', 'valid_max', 1000000)
        
        ncwrite(  output_filename, 'easting', int32(easting))
        
        % northing
        
        nccreate( output_filename, 'northing', 'Datatype', 'int32', ...
            'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
            'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
            'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
        
        ncwriteatt( output_filename, 'northing', 'long_name', 'northing')
        ncwriteatt( output_filename, 'northing', 'standard_name', 'northing')
        ncwriteatt( output_filename, 'northing', 'units', 'km/east')
        ncwriteatt( output_filename, 'northing', 'add_offset', 0)
        ncwriteatt( output_filename, 'northing', 'scale_factor', 1)
        ncwriteatt( output_filename, 'northing', 'valid_min', -1000000)
        ncwriteatt( output_filename, 'northing', 'valid_max', 1000000)
        
        ncwrite(  output_filename, 'northing', int32(northing))
        
        % regridded_easting
        
        nccreate( output_filename, 'regridded_easting', 'Datatype', 'int32', ...
            'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
            'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
            'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
        
        ncwriteatt( output_filename, 'regridded_easting', 'long_name', 'regridded_easting')
        ncwriteatt( output_filename, 'regridded_easting', 'standard_name', 'regridded_easting')
        ncwriteatt( output_filename, 'regridded_easting', 'units', 'km/east')
        ncwriteatt( output_filename, 'regridded_easting', 'add_offset', 0)
        ncwriteatt( output_filename, 'regridded_easting', 'scale_factor', 1)
        ncwriteatt( output_filename, 'regridded_easting', 'valid_min', -1000000)
        ncwriteatt( output_filename, 'regridded_easting', 'valid_max', 1000000)
        
        ncwrite(  output_filename, 'regridded_easting', int32(regridded_easting))
        
        % regridded_northing
        
        nccreate( output_filename, 'regridded_northing', 'Datatype', 'int32', ...
            'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
            'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
            'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
        
        ncwriteatt( output_filename, 'regridded_northing', 'long_name', 'regridded_northing')
        ncwriteatt( output_filename, 'regridded_northing', 'standard_name', 'regridded_northing')
        ncwriteatt( output_filename, 'regridded_northing', 'units', 'km/east')
        ncwriteatt( output_filename, 'regridded_northing', 'add_offset', 0)
        ncwriteatt( output_filename, 'regridded_northing', 'scale_factor', 1)
        ncwriteatt( output_filename, 'regridded_northing', 'valid_min', -1000000)
        ncwriteatt( output_filename, 'regridded_northing', 'valid_max', 1000000)
        
        ncwrite(  output_filename, 'regridded_northing', int32(regridded_northing))
    end
end

if get_gradients
    
    MaxGrad = 20; % Don't expect to see gradients larger than 20 K/km
    
    if save_just_the_facts == 0
        % along_scan_gradient
                
        nccreate( output_filename, 'along_scan_gradient', 'Datatype', 'int32', ...
            'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
            'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
            'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
        
        ncwriteatt( output_filename, 'along_scan_gradient', 'long_name', 'along_scan sst gradient')
        ncwriteatt( output_filename, 'along_scan_gradient',  'standard_name', 'along_scan_temperature_gradient')
        ncwriteatt( output_filename, 'along_scan_gradient', 'units', 'C/km')
        ncwriteatt( output_filename, 'along_scan_gradient', 'add_offset', 0)
        ncwriteatt( output_filename, 'along_scan_gradient', 'scale_factor', gradientScaleFactor)
        ncwriteatt( output_filename, 'along_scan_gradient',  'valid_min', -MaxGrad / gradientScaleFactor)
        ncwriteatt( output_filename, 'along_scan_gradient',  'valid_max', MaxGrad / gradientScaleFactor)
        
        ncwrite(  output_filename, 'along_scan_gradient', along_scan_gradient)
        
        % along_track_gradient
        
        nccreate( output_filename, 'along_track_gradient', 'Datatype', 'int32', ...
            'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
            'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
            'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
        
        ncwriteatt( output_filename, 'along_track_gradient', 'long_name', 'along_track sst gradient')
        ncwriteatt( output_filename, 'along_track_gradient',  'standard_name', 'along_track_temperature_gradient')
        ncwriteatt( output_filename, 'along_track_gradient', 'units', 'C/km')
        ncwriteatt( output_filename, 'along_track_gradient', 'add_offset', 0)
        ncwriteatt( output_filename, 'along_track_gradient', 'scale_factor', gradientScaleFactor)
        ncwriteatt( output_filename, 'along_track_gradient',  'valid_min', -MaxGrad / gradientScaleFactor)
        ncwriteatt( output_filename, 'along_track_gradient',  'valid_max', MaxGrad / gradientScaleFactor)
        
% % %         nn = find(isnan(along_track_gradient));
% % %         temp_grad = int32(along_track_gradient / gradientScaleFactor);
% % %         temp_grad(nn) = fill_value_int32;
        
        ncwrite(  output_filename, 'along_track_gradient', along_track_gradient)
    end
    
    % Eastward gradient
    
    nccreate( output_filename, 'eastward_gradient', 'Datatype', 'int32', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
        
    ncwriteatt( output_filename, 'eastward_gradient', 'long_name', 'eastward sst gradient')
    ncwriteatt( output_filename, 'eastward_gradient', 'standard_name', 'eastward_temperature_gradient')
    ncwriteatt( output_filename, 'eastward_gradient', 'units', 'C/km')
    ncwriteatt( output_filename, 'eastward_gradient', 'add_offset', 0)
    ncwriteatt( output_filename, 'eastward_gradient', 'scale_factor', gradientScaleFactor)
    ncwriteatt( output_filename, 'eastward_gradient',  'valid_min', -MaxGrad / gradientScaleFactor)
    ncwriteatt( output_filename, 'eastward_gradient',  'valid_max', MaxGrad / gradientScaleFactor)
    
% % %     nn = find(isnan(grad_lon_per_km));
% % %     temp_grad = int32(grad_lon_per_km / gradientScaleFactor);
% % %     temp_grad(nn) = -999;
% % %     
    ncwrite(  output_filename, 'eastward_gradient', grad_lon_per_km)
    
    % along_track_gradient
    
    nccreate( output_filename, 'northward_gradient', 'Datatype', 'int32', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4, 'FillValue', fill_value_int32, 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'northward_gradient', 'long_name', 'northward sst gradient')
    ncwriteatt( output_filename, 'northward_gradient',  'standard_name', 'northward_temperature_gradient')
    ncwriteatt( output_filename, 'northward_gradient', 'units', 'C/km')
    ncwriteatt( output_filename, 'northward_gradient', 'add_offset', 0)
    ncwriteatt( output_filename, 'northward_gradient', 'scale_factor', gradientScaleFactor)
    ncwriteatt( output_filename, 'northward_gradient',  'valid_min', -MaxGrad / gradientScaleFactor)
    ncwriteatt( output_filename, 'northward_gradient',  'valid_max', MaxGrad / gradientScaleFactor)
    
% % %     nn = find(isnan(grad_lat_per_km));
% % %     temp_grad = int32(grad_lat_per_km / gradientScaleFactor);
% % %     temp_grad(nn) = -999;
% % %     
    ncwrite(  output_filename, 'northward_gradient', grad_lat_per_km)
end

%% Now create and write out some of the less important  variables.

% time_from_start_orbit

nccreate( output_filename, 'time_from_start_orbit', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single, 'Format', 'netcdf4')

ncwriteatt( output_filename, 'time_from_start_orbit', 'long_name', 'time in orbit')
ncwriteatt( output_filename, 'time_from_start_orbit', 'standard_name', 'time_in_orbit')
ncwriteatt( output_filename, 'time_from_start_orbit', 'units', 'seconds')

ncwrite(  output_filename, 'time_from_start_orbit', scan_seconds_from_start)

% nadir_longitude

nccreate( output_filename, 'nadir_longitude', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single, 'Format', 'netcdf4')

ncwriteatt( output_filename, 'nadir_longitude', 'long_name', 'Nadir Longitude')
ncwriteatt( output_filename, 'nadir_longitude', 'standard_name', 'nadir_longitude')
ncwriteatt( output_filename, 'nadir_longitude', 'units', 'degrees_east')

ncwrite(  output_filename, 'nadir_longitude', longitude(nadir_x,:))

% left_swath_edge_trackline_longitude

nccreate( output_filename, 'left_swath_edge_trackline_longitude', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single, 'Format', 'netcdf4')

ncwriteatt( output_filename, 'left_swath_edge_trackline_longitude', 'long_name', 'left swath edge longitude')
ncwriteatt( output_filename, 'left_swath_edge_trackline_longitude',  'standard_name', 'left_swath_edge_trackline_longitude')
ncwriteatt( output_filename, 'left_swath_edge_trackline_longitude', 'units', 'degrees_east')

ncwrite(  output_filename, 'left_swath_edge_trackline_longitude', longitude(1,:))

% right_swath_edge_trackline_longitude

nccreate( output_filename, 'right_swath_edge_trackline_longitude', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single, 'Format', 'netcdf4')

ncwriteatt( output_filename, 'right_swath_edge_trackline_longitude', 'long_name', 'right swath edge longitude')
ncwriteatt( output_filename, 'right_swath_edge_trackline_longitude',  'standard_name', 'right_swath_edge_trackline_longitude')
ncwriteatt( output_filename, 'right_swath_edge_trackline_longitude', 'units', 'degrees_east')

ncwrite(  output_filename, 'right_swath_edge_trackline_longitude', longitude(end,:))

% nadir_latitude

nccreate( output_filename, 'nadir_latitude', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single, 'Format', 'netcdf4')

ncwriteatt( output_filename, 'nadir_latitude', 'long_name', 'Nadir latitude')
ncwriteatt( output_filename, 'nadir_latitude', 'standard_name', 'nadir_latitude')
ncwriteatt( output_filename, 'nadir_latitude', 'units', 'degrees_north')

ncwrite(  output_filename, 'nadir_latitude', nlat_orbit)

% left_swath_edge_trackline_latitude

nccreate( output_filename, 'left_swath_edge_trackline_latitude', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single, 'Format', 'netcdf4')

ncwriteatt( output_filename, 'left_swath_edge_trackline_latitude', 'long_name', 'left swath edge latitude')
ncwriteatt( output_filename, 'left_swath_edge_trackline_latitude',  'standard_name', 'left_swath_edge_trackline_latitude')
ncwriteatt( output_filename, 'left_swath_edge_trackline_latitude', 'units', 'degrees_north')

ncwrite(  output_filename, 'left_swath_edge_trackline_latitude', latitude(1,:))

% right_swath_edge_trackline_latitude

nccreate( output_filename, 'right_swath_edge_trackline_latitude', 'Datatype', 'single', ...
    'Dimensions', {'ny' nyDimension}, 'FillValue', fill_value_single, 'Format', 'netcdf4')

ncwriteatt( output_filename, 'right_swath_edge_trackline_latitude', 'long_name', 'right swath edge latitude')
ncwriteatt( output_filename, 'right_swath_edge_trackline_latitude',  'standard_name', 'right_swath_edge_trackline_latitude')
ncwriteatt( output_filename, 'right_swath_edge_trackline_latitude', 'units', 'degrees_north')

ncwrite(  output_filename, 'right_swath_edge_trackline_latitude', latitude(end,:))

if save_just_the_facts == 0
    
    % cloud_free_pixels - not sure what this one is
    
    nccreate( output_filename, 'cloud_free_pixels', 'Datatype', 'int16', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4,'FillValue', int16(-1), 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'cloud_free_pixels', 'long_name', 'cloud_free_pixels')
    ncwriteatt( output_filename, 'cloud_free_pixels', 'standard_name', 'sea_surface_temperature')
    ncwriteatt( output_filename, 'cloud_free_pixels', 'valid_min', 0)
    ncwriteatt( output_filename, 'cloud_free_pixels', 'valid_max', 1)
    ncwriteatt( output_filename, 'cloud_free_pixels', 'flag_meanings',  'cloudy clear')
    ncwriteatt( output_filename, 'cloud_free_pixels', 'flag_values', [0  1])
    
    % cayula_cornillon_front_pixel - 1 if the pixel was flagged as a front pixel.
    
    nccreate( output_filename, 'cayula_cornillon_front_pixel', 'Datatype', 'int16', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4,'FillValue', int16(-1), 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'cayula_cornillon_front_pixel', 'long_name', 'sst')
    ncwriteatt( output_filename, 'cayula_cornillon_front_pixel', 'standard_name', 'cayula_cornillon_front_pixel')
    ncwriteatt( output_filename, 'cayula_cornillon_front_pixel', 'valid_min', 0)
    ncwriteatt( output_filename, 'cayula_cornillon_front_pixel', 'valid_max', 1)
    ncwriteatt( output_filename, 'cayula_cornillon_front_pixel', 'flag_meanings',  'no_front front')
    ncwriteatt( output_filename, 'cayula_cornillon_front_pixel', 'flag_values', [0  1])
    
    % day_or_night_pixel
    
    nccreate( output_filename, 'day_or_night_pixel', 'Datatype', 'int16', ...
        'Dimensions', {'nx' nxDimension 'ny' nyDimension}, ...
        'Chunksize', [min(1024,nxDimension) min(1024,nyDimension)], ...
        'Deflatelevel', 4,'FillValue', int16(-1), 'Format', 'netcdf4')
    
    ncwriteatt( output_filename, 'day_or_night_pixel', 'long_name', 'sst')
    ncwriteatt( output_filename, 'day_or_night_pixel', 'standard_name', 'day_or_night_pixel')
    ncwriteatt( output_filename, 'day_or_night_pixel', 'valid_min', 0)
    ncwriteatt( output_filename, 'day_or_night_pixel', 'valid_max', 1)
    ncwriteatt( output_filename, 'day_or_night_pixel', 'flag_meanings',  'Day Night')
    ncwriteatt( output_filename, 'day_or_night_pixel', 'flag_values', [0  1])
    
end

% Date and time of the start of this orbit seconds since 1/1/1970

time_coverage_start = datenum(oinfo(iOrbit).start_time - datenum(1970, 1, 1, 0, 0, 0)) * secs_per_day;

nccreate( output_filename, 'DateTime', 'Datatype', 'double', 'Format', 'netcdf4')

ncwriteatt( output_filename, 'DateTime', 'long_name', 'time since 1970-01-01 00:00:00.0')
ncwriteatt( output_filename, 'DateTime', 'standard_name', 'time')
ncwriteatt( output_filename, 'DateTime', 'units', 'seconds')

ncwrite( output_filename, 'DateTime', time_coverage_start)

% Contributing granules. Put these in a group. There are no high level
% Matlab commands to do this so must open the file, create the group, add
% granule metadata in the group and close the file.

nGranules = length(oinfo(iOrbit).ginfo);

if ~isempty(nGranules)
    
    % Loop over granules creating and populating a subgroup for each granule.
    
    kGranule = 0;
    filenames = [];
    for jGranule=1:nGranules
        
        % If no indicies for the location of data in the orbit, skip
        
        if ~isempty(oinfo(iOrbit).ginfo(jGranule).osscan)
            kGranule = kGranule + 1;
            group_name = ['/contributing_granules/granule_' num2str(jGranule) '/'];
            
            % Load the granule filenams into variable filenames.
            
            % % % nn = strfind(oinfo(iOrbit).ginfo(jGranule).data_name, 'AQUA_MODIS.');
            % % % filename = oinfo(iOrbit).ginfo(jGranule).data_name(nn:end);
            
            nn = strfind(oinfo(iOrbit).ginfo(jGranule).data_name, '/');

            filename = oinfo(iOrbit).ginfo(jGranule).data_name(nn(end)+1:end);
            filenames = [filenames; filename];
            
            % Next load the start and end times of this granule.

            start_times(kGranule) = datenum(oinfo(iOrbit).ginfo(jGranule).start_time - datenum(1970, 1, 1, 0, 0, 0)) * secs_per_day;
            end_times(kGranule) = datenum(oinfo(iOrbit).ginfo(jGranule).end_time - datenum(1970, 1, 1, 0, 0, 0)) * secs_per_day;
            
            % Now for the start and end indices of the location of the data
            % from this granule in the orbit.

            osscans(kGranule) = oinfo(iOrbit).ginfo(jGranule).osscan;
            oescans(kGranule) = oinfo(iOrbit).ginfo(jGranule).oescan;
            
            % And the start and end indices for the data from this granule.

            gsscans(kGranule) = oinfo(iOrbit).ginfo(jGranule).gsscan;
            gescans(kGranule) = oinfo(iOrbit).ginfo(jGranule).gescan;
        end
    end
    
    % Create the variable name for the name of this granule and write to the file.
    
    nccreate( output_filename, '/contributing_granules/filenames', 'Datatype', 'char', ...
        'Dimensions', {'nGranules' kGranule 'name_length', length(filename)}, 'Format', 'netcdf4')
    ncwrite( output_filename, '/contributing_granules/filenames', filenames)
    
    % Next the start and end times of this granule.
    
    nccreate(   output_filename, '/contributing_granules/start_time', 'Dimensions', {'nGranules' kGranule}, 'Format', 'netcdf4')
    ncwriteatt( output_filename, '/contributing_granules/start_time', 'long_name', 'start time since 1970-01-01 00:00:00.0')
    ncwriteatt( output_filename, '/contributing_granules/start_time', 'standard_name', 'start_time_of_granule')
    ncwriteatt( output_filename, '/contributing_granules/start_time', 'units', 'seconds')
    ncwrite(    output_filename, '/contributing_granules/start_time', start_times)
    
    nccreate(   output_filename, '/contributing_granules/end_time', 'Dimensions', {'nGranules' kGranule}, 'Format', 'netcdf4')
    ncwriteatt( output_filename, '/contributing_granules/end_time', 'long_name', 'end time since 1970-01-01 00:00:00.0')
    ncwriteatt( output_filename, '/contributing_granules/end_time', 'standard_name', 'end_time_of_granule')
    ncwriteatt( output_filename, '/contributing_granules/end_time', 'units', 'seconds')
    ncwrite(    output_filename, '/contributing_granules/end_time', end_times)
    
    % Now for the start and end indices of the location of the data
    % from this granule in the orbit.
    
    nccreate(   output_filename, '/contributing_granules/orbit_start_index', 'Dimensions', {'nGranules' kGranule}, 'Format', 'netcdf4')
    ncwriteatt( output_filename, '/contributing_granules/orbit_start_index', 'long_name', 'first index in the orbit for this granule')
    ncwriteatt( output_filename, '/contributing_granules/orbit_start_index', 'standard_name', 'first_index_in_orbit')
    ncwrite(    output_filename, '/contributing_granules/orbit_start_index', osscans)
    
    nccreate(   output_filename, '/contributing_granules/orbit_end_index', 'Dimensions', {'nGranules' kGranule}, 'Format', 'netcdf4')
    ncwriteatt( output_filename, '/contributing_granules/orbit_end_index', 'long_name', 'last index in the orbit for this granule')
    ncwriteatt( output_filename, '/contributing_granules/orbit_end_index', 'standard_name', 'last_index_in_orbit')
    ncwrite(    output_filename, '/contributing_granules/orbit_end_index', oescans)
    
    % And the start and end indices for the data from this granule.
    
    nccreate(   output_filename, '/contributing_granules/granule_start_index', 'Dimensions', {'nGranules' kGranule}, 'Format', 'netcdf4')
    ncwriteatt( output_filename, '/contributing_granules/granule_start_index', 'long_name', 'first index in the granule for this granule')
    ncwriteatt( output_filename, '/contributing_granules/granule_start_index', 'standard_name', 'first_index_in_granule')
    ncwrite(    output_filename, '/contributing_granules/granule_start_index', gsscans)
    
    nccreate(   output_filename, '/contributing_granules/granule_end_index', 'Dimensions', {'nGranules' kGranule}, 'Format', 'netcdf4')
    ncwriteatt( output_filename, '/contributing_granules/granule_end_index', 'long_name', 'last index in the granule for this granule')
    ncwriteatt( output_filename, '/contributing_granules/granule_end_index', 'standard_name', 'last_index_in_granule')
    ncwrite(    output_filename, '/contributing_granules/granule_end_index', gescans)
end

%% Now for the global attributes.

nn = strfind( output_filename, 'SST');

if isempty(nn)
    disp(['This function is setup for SST only but this does not appear to be an SST granule.'])
    keyboard
end

parameter_name = 'SST';

nn = strfind(output_filename, 'AQUA');
if ~isempty(nn)
    Satellite = output_filename(nn(end):nn(end)+3);
    data_obtained_from = 'https://oceancolor.gsfc.nasa.gov/cgi/browse.pl?sen=amod';
else
    nn = strfind(output_filename, 'TERRA');
    if ~isempty(nn)
        Satellite = output_filename(nn(end):nn(end)+4);
        data_obtained_from = 'https://oceancolor.gsfc.nasa.gov/cgi/browse.pl?sen=tmod';
    else
        disp(['Satellite not found in: ' output_filename])
        keyboard
    end
end

Title = ['Conditioned 1km (L2) MODIS ' Satellite ' SST'];
ncwriteatt(output_filename, '/', 'title', Title);

nn = strfind(output_filename, 'MODIS');
if ~isempty(nn)
    Sensor = output_filename(nn(end):nn(end)+4);
    iVarName = 'along-scan';
    jVarName = 'along-track';
else
    disp(['Sensor not found in: ' output_filename])
    keyboard
end

Summary = [ 'The field in this file was generated from an L2 MODIS ' Satellite ...
    ' granule obtained from the Goddard Ocean Color web site: ' data_obtained_from '.'...
    'Pixels for which the input ' parameter_name 'values were determined to be of low quality by ' ...
    ' Fix_MODIS_Mask were set to ' num2str(sstFillValue) '. The first dimension in the array (i) is in the ' iVarName ' direction. '...
    ' The second dimension (j) is in the ' jVarName ' direction. This file also contains a good/bad pixel ' ...
    'field: 1 for good, 0 for bad; a Cayula-Cornillon fronts field: 0 for no front, ' ...
    '1 for a front pixel, and; a day/night field based on the solar zenith angle at the pixel: ' ...
    '1 if this angle is less than 90 degrees, day, and 0 otherwise, night.'];

ncwriteatt(output_filename, '/', 'Summary', Summary);

ncwriteatt(output_filename, '/', 'Conventions', 'CF-1.5');
ncwriteatt(output_filename, '/', 'standard_name_vocabulary', 'CF-1.5');
ncwriteatt(output_filename, '/', 'Metadata_Conventions', 'Unidata Dataset Discovery v1.0');

UUID = string(javaMethod('toString', java.util.UUID.randomUUID));
ncwriteatt(output_filename, '/', 'uuid', UUID);
ncwriteatt(output_filename, '/', 'standard_name_vocabulary', 'CF-1.5');
ncwriteatt(output_filename, '/', 'date_created', datestr(now));
ncwriteatt(output_filename, '/', 'source', 'Satellite observation');

History = strcat('{', datestr(now), ' : Fix_MODIS_Mask version ', num2str(Fix_MODIS_Mask_number), ': ', UUID, '}');
ncwriteatt(output_filename, '/', 'history', History);

ncwriteatt(output_filename, '/', 'creator_name', 'Peter Cornillon');
ncwriteatt(output_filename, '/', 'creator_url', 'http://www.sstfronts.org');
ncwriteatt(output_filename, '/', 'creator_email', 'pcornillon@gso.uri.edu');
ncwriteatt(output_filename, '/', 'institution', 'University of Rhode Island - Graduate School of Oceanography');
ncwriteatt(output_filename, '/', 'project', 'SST Fronts');
ncwriteatt(output_filename, '/', 'acknowledgement', 'The Graduate School of Oceanography generated this data file with support from NASA (Grant #NNX11AF23G). Please acknowledge the use of these data with the following: {These data were acquired from URI-GSO on [date] from http://www.sstfronts.org.} See the license attribute for information regarding use and re-distribution of these data.');
ncwriteatt(output_filename, '/', 'license', 'These data are openly available to the public. Please acknowledge the use of these data with the text given in the acknowledgement attribute.');
ncwriteatt(output_filename, '/', 'contributor_name', 'National Aeronautics and Space Administration http://oceandata.sci.gsfc.nasa.gov./');
ncwriteatt(output_filename, '/', 'contributor_role', 'Generated SST fields from MODIS data.');
ncwriteatt(output_filename, '/', 'publisher_name', 'SST Fronts');
ncwriteatt(output_filename, '/', 'publisher_url', 'http://www.sstfronts.org');
ncwriteatt(output_filename, '/', 'publisher_institution','University of Rhode Island - Graduate School of Oceanography');
ncwriteatt(output_filename, '/', 'cdm_data_type', 'Grid');

% % ncwriteatt(output_filename, '/', 'LatLonFileName', good_filename_out);

%% And get the global attributes from the input file

for iAttribute = 1:length(oinfo(iOrbit).ginfo(1).metadata_global_attrib.Attributes)
    
    switch oinfo(iOrbit).ginfo(1).metadata_global_attrib.Attributes(iAttribute).Name
        
        case {'time_coverage_end' 'start_center_longitude' 'start_center_latitude' 'end_center_longitude' 'end_center_latitude' ...
                'northernmost_latitude' 'southernmost_latitude' 'easternmost_longitude' 'westernmost_longitude' ...
                'geospatial_lat_units' 'geospatial_lon_units' 'geospatial_lat_max' 'geospatial_lat_min' 'geospatial_lon_max' 'geospatial_lon_min' ...
                'startDirection' 'endDirection' 'day_night_flag' 'earth_sun_distance_correction'}
            
            ncwriteatt(output_filename, '/', ...
                oinfo(iOrbit).ginfo(1).metadata_global_attrib.Attributes(iAttribute).Name, ...
                oinfo(iOrbit).ginfo(1).metadata_global_attrib.Attributes(iAttribute).Value);
            
        otherwise
    end
end

% The granule attributes take up much too much space in oinfo, which is
% saved for each orbit so, after writing them out for the first granule,
% remove the rest from oinfo

if length(oinfo(iOrbit).ginfo) > 1
    for jGranule=2:length(oinfo(iOrbit).ginfo)
        oinfo(iOrbit).ginfo(jGranule).metadata_global_attrib = [];
    end
end

%% Submit a batch job to copy the file just written from local to remote storage.

% The reason for this is that writing a netCDF file to remote storage takes
% a long time compared to writing it to local storage so write it to local
% storage and then submit a batch job to copy it from local storage to
% remote storage. Only do this if output_file_directory_remote is not empty. 
% Note that output_filename in the following is the local filename. 

% % % if ~isempty(output_file_directory_remote)
% % % 
% % %     % Check to see if copy_output_no is running.
% % %     
% % %     nn = strfind(output_filename, '/SST/');
% % %     remote_filename = [output_file_directory_remote output_filename(nn+5:end)];
% % % 
% % %     copy_output_no = batch( 'copy_output_file', 0, {output_filename, remote_filename}, CaptureDiary=true);
% % % end
