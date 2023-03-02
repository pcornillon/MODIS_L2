function check_OBPG_directory(Year)
% check_OBPG_directory - make sure that all the files in day and night directories have an OBPG metadata file - PCC
%

filelist_combined = dir(['/Volumes/Aqua-1/MODIS_R2019/combined/' num2str(Year) '/AQUA*']);
filelist_OBPG = dir(['/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/' num2str(Year) '/AQUA*']);

jStart = 1;
iBad = 0;
for iFile=1:length(filelist_combined)

    filename_combined = filelist_combined(iFile).name;
    nn = strfind( filename_combined, 'AQUA_MODIS');

    datetime_part_combined = filename_combined(nn+11:nn+25);

    if mod(iFile,10000) == 0
        fprintf('Processed file #%i - %s - Elapsed time %6.0f seconds. \n', iFile, datetime_part_combined, toc)
        tic
    end

    found_this_one = 0;
    for jFile=jStart:length(filelist_OBPG)

        filename_OBPG = filelist_OBPG(jFile).name;
        nn = strfind( filename_OBPG, 'AQUA_MODIS');

        datetime_part_OBPG = filename_OBPG(nn+11:nn+25);

        if strcmp( datetime_part_combined, datetime_part_OBPG) == 1
            jStart = jFile;
            found_this_one = 1;
            break
        end
    end

    if found_this_one == 0
        iBad = iBad + 1;
        fprintf('Didn''t find OBPG file(%i) for combined file: %s\n', iFile, filename_combined)
    end
end

if iBad == 0
    fprintf('\n\nFound an OBPG file for each combined file.\n\n')
end

%% And now repeat for the opposite comparison


filelist_combined = dir(['/Volumes/Aqua-1/MODIS_R2019/combined/' num2str(Year) '/AQUA*']);
filelist_OBPG = dir(['/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/' num2str(Year) '/AQUA*']);

jStart = 1;
iBad = 0;
for iFile=jStart:length(filelist_OBPG)

    filename_OBPG = filelist_OBPG(iFile).name;
    nn = strfind( filename_OBPG, 'AQUA_MODIS');

    datetime_part_OBPG = filename_OBPG(nn+11:nn+25);

    if mod(iFile,10000) == 0
        fprintf('Processed file #%i - %s - Elapsed time %6.0f seconds. \n', iFile, datetime_part_OBPG, toc)
        tic
    end

    found_this_one = 0;
    for jclFile=1:length(filelist_combined)

        filename_combined = filelist_combined(jFile).name;
        nn = strfind( filename_combined, 'AQUA_MODIS');

        datetime_part_combined = filename_combined(nn+11:nn+25);

        if strcmp( datetime_part_combined, datetime_part_combined) == 1
            jStart = jFile;
            found_this_one = 1;
            break
        end
    end

    if found_this_one == 0
        iBad = iBad + 1;
        fprintf('Didn''t find combined file(%i) for OBPG file: %s\n', iFile, filename_OBPG)
    end
end

if iBad == 0
    fprintf('\n\nFound a combined file for each OBPG file.\n\n')
end
