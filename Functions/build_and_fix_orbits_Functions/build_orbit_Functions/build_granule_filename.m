function [status] = build_granule_filename( granules_directory, check_attributes)
% build_granule_filename - based on metadata granule name - PCC
%   
% Start by finding the data/time information. Then build the granule file
% name for either Amazon s3 file or for an OBPG file.
%
% INPUT
%   granules_directory - the name of the directory with the granules.
%   check_attributes - 1 to read the global attributes for the data granule
%    and check that they exist and/or are reasonable.
%
% OUTPUT
%   status  : 0 - OK
%           : 1 - couldn't find the data granule.
%           : 2 - didn't find number_of_lines global attribute.
%           : 3 - number of pixels global attribute not equal to 1354.
%           : 4 - number of scan lines global attribute not between 2020 and 2050.
%           : 5 - couldn't find the metadata file copied from OBPG data.
%

global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule sltimes_avg nlat_avg

% fi_metadata: AQUA_MODIS_20030101T002505_L2_SST_OBPG_extras.nc4
% fi_granule_OBPG: /Volumes/Aqua-1/MODIS_R2019/combined/2003/Aqua-1AQUA_MODIS.20030101T002505.L2.SST.nc
% fi_granule_s3: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100620224008-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc

status = 0;

oinfo(iOrbit).ginfo(iGranule).data_granule_name = [];

% Start building the name of the data granule. Get the bare filename first,
% this will avoid problems with '_'s in the directory names.

ss = strfind(oinfo(iOrbit).ginfo(iGranule).metadata_name, '/');
filename_in = oinfo(iOrbit).ginfo(iGranule).metadata_name(ss(end)+1:end);

nn = strfind( filename_in, '_2');

name_in_date = filename_in(nn(1)+1:nn(1)+8);
name_in_hr_min = filename_in(nn(1)+10:nn(1)+15);

if strcmp( granules_directory(1:2), 's3') == 1
    
    % Build the name.
    
    oinfo(iOrbit).ginfo(iGranule).data_granule_name = [granules_directory name_in_date name_in_hr_min(1:end-2) ...
        '07-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc'];
    
    % Check for existence. If it is not found increment the seconds by 1
    % and check again. For some reason the seconds differ between the
    % PO.DAAC granules and the OBPG granules.
    
    if exist(oinfo(iOrbit).ginfo(iGranule).data_granule_name) ~= 2
        
        oinfo(iOrbit).ginfo(iGranule).data_granule_name = [granules_directory name_in_date name_in_hr_min(1:end-2) ...
            '08-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc'];

        if exist(oinfo(iOrbit).ginfo(iGranule).data_granule_name) ~= 2
            
            status = populate_problem_list( 1, oinfo(iOrbit).ginfo(iGranule).metadata_name);
            return
        end
    end
else
    YearS = name_in_date(1:4);
    
    oinfo(iOrbit).ginfo(iGranule).data_granule_name = [granules_directory YearS '/AQUA_MODIS.' name_in_date 'T' name_in_hr_min '.L2.SST.nc'];
    
    % If the data file does not exist, very bad.
    
    if exist(oinfo(iOrbit).ginfo(iGranule).data_granule_name) ~= 2
        fprintf('Whoops, couldn''t find %s.\n', oinfo(iOrbit).ginfo(iGranule).data_granule_name)

        status = populate_problem_list( 1, oinfo(iOrbit).ginfo(iGranule).data_granule_name);
        return
    end
end

% Check the global attributes in the granule data file if requested.

if check_attributes
    status = check_global_attrib;
end

end

