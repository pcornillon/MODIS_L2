function get_granule_filelists(Years)
% get_granule_filelists - generates list of filenames and Matlab time extracted from the names - PCC
%
% INPUT
%   Years: cell array with years to processs {'2002' '2005'}
%

Test = 0;

for iYear=1:length(Years)
    
    Year = Years{iYear};
    
    % Get the file list for this year.
    
    if Test
        % load ~/Dropbox/TempForTransfer/filelist.mat
        load ~/Desktop/filelist.mat
    else
        eval(['fileList = dir(''/Volumes/MODIS_L2_Original/OBPG/combined/' Year '/AQUA*'');'])
    end
    
    for iFile=1:length(fileList)
        filename = fileList(iFile).name;
        
        granuleList(iFile).filename = filename;
        granuleList(iFile).matTime = parse_filename(filename);
    end
    
    eval(['save(''~/Dropbox/Data/MODIS_L2/granuleList_' Years{iYear} '.mat'', ''granuleList'');']);
end