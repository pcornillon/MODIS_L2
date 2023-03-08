function [status, fi_granule, problem_list] ...
    = build_granule_filename( fi_metadata, granules_directory, problem_list, check_attributes)
% build_granule_filename - based on metadata granule name - PCC
%   
% Start by finding the data/time information. Then build the granule file
% name for either Amazon s3 file or for an OBPG file.
%
% INPUT
%   fi_metadata - the filename for the metadata file for this granule. The
%    metadata information was copied from the OBPG granule because it does
%    not exist in the PO.DAAC granule.
%   granules_directory - the name of the directory with the granules.
%   check_attributes - 1 to read the global attributes for the data granule
%    and check that they exist and/or are reasonable.
%   problem_list - structure with list of filenames (filename) for skipped 
%    file and the reason for it being skipped (problem_code):
%    problem_code: 1 - couldn't find the file in s3.
%                : 2 - couldn't find the metadata file copied from OBPG data.
%
% OUTPUT
%   status  : 0 - OK
%           : 1 - couldn't find the data granule.
%           : 2 - didn't find number_of_lines global attribute.
%           : 3 - number of pixels global attribute not equal to 1354.
%           : 4 - number of scan lines global attribute not between 2020 and 2050.
%           : 5 - couldn't find the metadata file copied from OBPG data.
%   fi_granule - granule filename. 
%   problem_list - as above but the list is incremented by 1 if a problem.
%

% fi_metadata: AQUA_MODIS_20030101T002505_L2_SST_OBPG_extras.nc4
% fi_granule_OBPG: /Volumes/Aqua-1/MODIS_R2019/combined/2003/Aqua-1AQUA_MODIS.20030101T002505.L2.SST.nc
% fi_granule_s3: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100620224008-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc

status = 0;
fi_granule = [];

% Get the index for the problem list.

if isnan(problem_list(1).problem_code)
    iProblemFile = 0;
else
    iProblemFile = length(problem_list.problem_code);
end

% Start building the name of the data granule. Get the bare filename first,
% this will avoid problems with '_'s in the directory names.

ss = strfind(fi_metadata, '/');
filename_in = fi_metadata(ss(end)+1:end);

nn = strfind( filename_in, '_2');

name_in_date = filename_in(nn(1)+1:nn(1)+8);
name_in_hr_min = filename_in(nn(1)+10:nn(1)+15);

% % % ss = strfind(fi_metadata, '/');

if strcmp( granules_directory(1:2), 's3') == 1
    
    % Build the name.
    
    fi_granule = [granules_directory name_in_date name_in_hr_min(1:end-2) '07-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc'];
    
    % Check for existence. If it is not found increment the seconds by 1
    % and check again. For some reason the seconds differ between the
    % PO.DAAC granules and the OBPG granules.
    
    if exist(fi_granule) ~= 2
        
        fi_granule = [granules_directory name_in_date name_in_hr_min(1:end-2) '08-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc'];
        
        if exist(fi_granule) ~= 2

            % Here for a problem add this file to the problem list. 
            
            iProblemFile = iProblemFile + 1;
            
            problem_list.fi_metadata{iProblemFile} = fi_metadata;
            problem_list.problem_code(iProblemFile) = 1;
            
            status = problem_list.problem_code(iProblemFile);
            return
        end
    end
else
    YearS = name_in_date(1:4);
    
    fi_granule = [granules_directory YearS '/AQUA_MODIS.' name_in_date 'T' name_in_hr_min '.L2.SST.nc'];
    
    % If the data file does not exist, very bad.
    
    if exist(fi_granule) ~= 2
        fprintf('Whoops, couldn''t find %s.\n', fi_granule)
                
        iProblemFile = iProblemFile + 1;
        
        problem_list.fi_metadata{iProblemFile} = fi_metadata;
        problem_list.problem_code(iProblemFile) = 1;

        status = problem_list.problem_code(iProblemFile);
        return
    end
end

% Check the global attributes in the granule data file if requested.

if check_attributes
    [status, problem_list] = check_global_attrib( fi_granule, problem_list);
end

end

