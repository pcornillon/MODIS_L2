function [fi_granule, problem_list] = build_granule_filename( fi_metadata, granules_directory, problem_list)
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
%   problem_list - structure with list of filenames (filename) for skipped 
%    file and the reason for it being skipped (problem_code):
%    problem_code: 1 - couldn't find the file in s3.
%                : 2 - couldn't find the metadata file copied from OBPG data.
%
% OUTPUT
%   fi_granule - granule filename. 
%

% fi_metadata: AQUA_MODIS_20030101T002505_L2_SST_OBPG_extras.nc4
% fi_granule_OBPG: /Volumes/Aqua-1/MODIS_R2019/combined/2003/Aqua-1AQUA_MODIS.20030101T002505.L2.SST.nc
% fi_granule_s3: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100620224008-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc

fi_granule = [];

nn = strfind( fi_metadata, '_2');

name_in_date = fi_metadata(nn(2)+1:nn(2)+8);
name_in_hr_min = fi_metadata(nn(2)+9:nn(2)+14);

ss = strfind(fi_metadata, '/');

if strcmp( granules_directory(1:2), 's3') == 1
    
    % Build the name.
    
    fi_granule = [granules_directory name_in_date name_in_hr_min '07' fi_metadata(ss(end)+15:end)];
    
    % Check for existence. If it is not found increment the seconds by 1
    % and check again. For some reason the seconds differ between the
    % PO.DAAC granules and the OBPG granules.
    
    if exist(fi_granule) ~= 2
        
        fi_granule = [granules_directory name_in_date name_in_hr_min(1:end-2) '08' fi_metadata(ss(end)+15:end)];
        
        if exist(fi_granule) ~= 2

            % Here for a problem add this file to the problem list. 
            
            if isempty(problem_list(1).problem_code)
                iProblemFile = 1;
            else
                iProblemFile = length(problem_list.problem_code) + 1;
            end
            
            problem_list.fi_metadata{iProblemFile} = fi_metadata;
            problem_list.problem_code(iProblemFile) = 1;
        end
    end
else
    YearS = fi_metadata(nn(2)+1:nn(2)+4);
    
    fi_granule = [granules_directory YearS '/AQUA_MODIS.' name_in_date 'T' name_in_hr_min '.L2.SST.nc'];
    
    % If the data file does not exist, very bad, exit.
    
    if exist(fi_granule) ~= 2
        fprintf('Whoops, couldn''t find %s.\n', fi_granule)
        return
    end
end

end

