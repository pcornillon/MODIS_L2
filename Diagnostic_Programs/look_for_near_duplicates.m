% look_for_near_closes - look for granules in combined within a few minutes of each other  - PCC
%
% The OBPG has put granules into day and night folders. There is however
% overlap between these foloder--granules which overlap the terminus. This
% script loads the names of all granules for a given year, extracts the
% times for each from their names, writes them to an list, does a first
% difference on the times and then finds all granules separated by less
% than one minute.
%

% base_dir = '/Volumes/Aqua-1/MODIS_R2019/combined/';
base_dir = '/Volumes/Aqua-1/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/';

close_granules = [];
iclose = 0;

iDeleted = 0;
for iYear=2002:2021
    YearS = num2str(iYear);

    fprintf('\nWorking on %s\n\n', YearS)

    % Get the list of granules in the given year of folder1.

    clear file_list

    tic; file_list = dir([base_dir YearS '/AQUA*']); toc

    for iGranule1=1:length(file_list)-1

        granule1_filename = [file_list(iGranule1).folder '/' file_list(iGranule1).name];

        nn = strfind(granule1_filename, 'AQUA_MODIS') + 11;

        matlab_time_granule1 = datenum(str2num(granule1_filename(nn:nn+3)), str2num(granule1_filename(nn+4:nn+5)), str2num(granule1_filename(nn+6:nn+7)), ...
            str2num(granule1_filename(nn+9:nn+10)), str2num(granule1_filename(nn+11:nn+12)), str2num(granule1_filename(nn+13:nn+14)));

        % Check for a files within 2 minutes of the current one.

        iGranule2 = iGranule1+1;

        granule2_filename = [file_list(iGranule2).folder '/' file_list(iGranule2).name];

        nn = strfind(granule2_filename, 'AQUA_MODIS') + 11;

        matlab_time_granule2 = datenum(str2num(granule2_filename(nn:nn+3)), str2num(granule2_filename(nn+4:nn+5)), str2num(granule2_filename(nn+6:nn+7)), ...
            str2num(granule2_filename(nn+9:nn+10)), str2num(granule2_filename(nn+11:nn+12)), str2num(granule2_filename(nn+13:nn+14)));

        if abs(matlab_time_granule1 - matlab_time_granule2) == 0

            % If the two files are at the exact same time, check to see if
            % the 2nd file has a .1 extension at the end. If it does,
            % delete it. If not, check to see if one of the files is an NRT
            % file. If not, note and move on. If so check the creation time
            % of the NRT file to see if it is more recent than the non-NRT
            % file. If so, delete the non-NRT file. If not, note and move
            % on.

            fprintf('%i) %s - %s --- %s - %s\n', iGranule1, datestr(matlab_time_granule1), granule1_filename, datestr(matlab_time_granule2), granule2_filename)

            if ~isempty(strfind(granule2_filename, 'nc.1'))
                % Here if the 2nd file is a duplicate; ends with nc.1.

                fprintf('Removing granule %s\n', granule2_filename)
                eval(['! rm ' granule2_filename])

                iDeleted = iDeleted + 1;
                deleted_files(iDeleted) = string(granule2_filename);

            else
                % This is not a duplicate file but rather an NRT file. Make
                % sure that this is the case. If so, see if the creation
                % time of the NRT file is more recent than that of the
                % non-NRT file. If so, delete the non-NRT file. If not,
                % note and more on.

                % Get the matlab time if iGranule1 contains NRT in the name

                creation_time1 = datenum(file_list(iGranule1).date);
                creation_time2 = datenum(file_list(iGranule2).date);

                if ~isempty(strfind( granule1_filename, 'NRT'))
                    if creation_time1 >= creation_time2
                        fprintf('%i) %s is an NRT file created at %s after %s, created at %s.\n', ...
                            iGranule1, granule1_filename, file_list(iGranule1).date, granule2_filename, file_list(iGranule2).date)
                        fprintf('Removing granule %s\n', granule2_filename)
                        eval(['! rm ' granule2_filename])

                        iDeleted = iDeleted + 1;
                        deleted_files(iDeleted) = string(granule2_filename);
                   else
                        fprint('NRT granule #\i, %s, was created (%s) before #\i, %s. Not doing anything with it. \n', ...
                            iGranule1, granule1_filename, file_list(iGranule1).date, iGranule2, granule2_filename, file_list(iGranule2).date)
                    end
                end

                if ~isempty(strfind( granule2_filename, 'NRT'))
                    if creation_time2 >= creation_time1
                        fprintf('%i) %s is an NRT file created at %s after %s, created at %s.\n', ...
                            iGranule2, granule2_filename, file_list(iGranule2).date, granule1_filename, file_list(iGranule1).date)
                        fprintf('Removing granule %s\n', granule1_filename)
                        eval(['! rm ' granule1_filename])

                        iDeleted = iDeleted + 1;
                        deleted_files(iDeleted) = granule1_filename;
                    else
                        fprint('NRT granule #\i, %s, was created (%s) before  #\i, %s. Not doing anything with it. \n', ...
                            iGranule2, granule2_filename, file_list(iGranule2).date, iGranule1, granule1_filename, file_list(iGranule1).date)
                    end
                end
            end

        elseif abs(matlab_time_granule1 - matlab_time_granule2) < 2/(24*60)

            % Here if the time difference between the two files differs
            % by less than 2 minutes but the times are not equal. Check
            % to see if one of the files is an NRT file. 

            iclose = iclose + 1;

            close_granules(iclose).iGranule = iGranule1;

            close_granules(iclose).image1 = granule1_filename;
            close_granules(iclose).image2 = granule2_filename;

            close_granules(iclose).time1 = matlab_time_granule1;
            close_granules(iclose).time2 = matlab_time_granule2;
        end
    end
end

deletion_filelist = dir('/Volumes/Aqua-1/MODIS_R2019/combined/Filelists_and_Logs/deletion_log*');
save(['/Volumes/Aqua-1/MODIS_R2019/combined/Filelists_and_Logs/deletion_log_' num2str(length(deletion_filelist)+1) '.txt'], 'iDeleted', 'iclose', 'deleted_files', 'close_granules')

