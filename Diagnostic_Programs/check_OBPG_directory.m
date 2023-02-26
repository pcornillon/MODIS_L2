function check_OBPG_directory(Year)
% check_OBPG_directory - make sure that all the files in day and night directories have an OBPG metadata file - PCC
%

filelist_combined = dir(['/Volumes/Aqua-1/MODIS_R2019/combined/' num2str(Year) '/AQUA*']);
filelist_OBPG = dir(['/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/' num2str(Year) '/AQUA*']);

for iFile=1:length(filelist_combined)

    filename_combined = filelist_combined(iFile).name;
    nn = strfind( filename_combined, 'AQUA_MODIS_');

    datetime_part_combined = filename_combined(nn+11:nn+25);

    found_this_one = 0;
    for jFile=1:length(filelist_OBPG)

        filename_OBPG = filelist_OBPG(jFile).name;
        nn = strfind( filename_OBPG, 'AQUA_MODIS_');

        datetime_part_OBPG = filename_OBPG(nn+11:nn+25);

        if isempty(strcmp( datetime_part_combined, datetime_part_OBPG)) == 0
            found_this_one = 1;
            break
        end
    end

    if found_this_one == 0
        fprintf('Didn''t find combined file(\i): %s\n', iFile, filename_combined)
    end
end



