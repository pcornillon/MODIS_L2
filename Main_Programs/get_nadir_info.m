function problem_orbits = get_nadir_info(start_date_time, end_date_time)
% get_nadir_info - read nadir information for all granules in the specified period - PCC
%
% This function will read MODIS Aqua SST 11um granules in sequence for the
%  given specified period and save the nadir track, the swath edge tracks, 
%  and the detector number for all scan lines in each orbit (defined below)
%
% The start of each orbit is defined as the nearest scan line for the middle 
% detector of the 10 detector (detnum) to the latlim on the descending part
% of the orbit. lat lim was set to 78 S when the script was written. The
% orbit number assigned to each orbit, pcc_orbit_number is the NASA orbit
% number for the granule containing the start of the new orbit. 
%
% The script will start reading granules looking for the start of the first
% complete orbit; i.e., it will no save the portion of an orbit found prior
% to the orbit starting point, 78 S on the descending part of the orbit.
%
% Each new orbit is defined to be 40,271 scan lines long. This should 
% provide for an approximately 100 scan line overlap of sequential orbits.
%
% The function also records all granules that are missing, writing their
%  estimated name to a cell array and adding nans in place of the missing
%  scanline information.
%
% This function requires all granules for the period specified - day and
%  night granules. In the original version, these were moved from OBPG but
%  in the final version it should probably setup to run them from us-west-2.
%
% INPUT
%   start_date_time - year, month, day, hour minute vector for start time.
%   end_date_time - year, month, day, hour minute vector for end time.
%
% OUTPUT
%   problem_orbits - a structure function with the orbit numbers that are a
%    problem.
%
% EXAMPLE
%   get_nadir_info([2009 12 31 22 0], [2011 1 1 2 0]) - to process all
%    granules from 10 PM on December 31 2009 through 2 AM January 1 2011.
%    Including the last 2 hours of 2009 and the first 2 hours of 2011 will
%    assure that the first and last orbit touching 2010 are captured.

problem_orbits = [];
iProblemOrbit = 0;

nc_read = 0;

save_long = 0;  % If =1, will save lots of info, otherwise fairly little. 

first_orbit = 1;

if computer == 'MACI64'
    sw3 = 0;
    base_dir_in = '/Volumes/Aqua-1/MODIS_R2019/';
    base_dir_out = '/Volumes/Aqua-1/MODIS_R2019/';
    
    Diary_File = [base_dir_out, 'Orbits/Logs/GSO_' strrep(num2str(now), '.', '_') '.txt'];
    diary(Diary_File)
else
    sw3 = 1;
    base_dir_in =  's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';
    base_dir_out =  's3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/';
    %     s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100619075507-JPL-L2P_GHRSST-SSTskin-MODIS_A-N-v02.0-fv01.0.nc
    %     s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100620235508-JPL-L2P_GHRSST-SSTskin-MODIS_A-N-v02.0-fv01.0.nc
    
    Diary_File = [base_dir_out, 'Orbits/Logs/SW_' strrep(num2str(now), '.', '_') '.txt'];
    diary(Diary_File)
end

% Initialize various arrays and scalars

plotem = 0;
iFig = 1;

latlim = -78;

if (length(start_date_time) ~= 6) | (length(end_date_time) ~= 6)
    disp(['Input start and end time vectors must be 6 elements long. start_date_time: ' ...
        num2str(start_date_time) ' and end_date_time: ' num2str(end_date_time)])
    keyboard
end

% Convert input start and end times to Matlab times.

matlab_time_start = datenum(start_date_time);
matlab_time_end = datenum(end_date_time);

if matlab_time_end < matlab_time_start
    disp(['End time: ' datestr(matlab_time_end) ' comes before start time: ' datestr(matlab_time_start)])
    keyboard
end

iFilename = 0;
iMissing = 0;

clear filenames missing_granules

% imatlab_time is the time of the current granule. 

imatlab_time = matlab_time_start;
month_save = -100;
day_save = -100;

% Loop over granules

tic

while imatlab_time <= matlab_time_end
    
    % Add 5 minutes to the previous value of time to get the time of this granule.
    
    imatlab_time = imatlab_time + 5 / (24 * 60);
    
    % Get the date and time for this granule and generate strings for use in the names.
    
    [iyear, imonth, iday, ihour, iminute, isecond] = datevec(imatlab_time);
    
    iyears = convertStringsToChars( 2, num2str(iyear));
    imonths = return_a_string( 2, imonth);
    idays = return_a_string( 2, iday);
    ihours = return_a_string( 2, ihour);
    iminutes = return_a_string( 2, iminute);
    
% %     if iday ~= day_save
% %         day_save = iday;
% %         fprintf('Working on %i/%i/%i at time%f\n', imonths, idays, iyears, num2str(toc)])
% %     end
    
    % If this is a new month save the nadir track info and reinialize the vectors.
    
%     if (imonth ~= month_save)
%         
%         if exist('nlon')
%             % First find the start of each complete new orbit. The scan
%             % line corresponding to the start of a new orbit is described
%             % in the description of this function. 
%             
%             diff_nlat = diff(nlat);
%             nn = find( (abs(nlat(1:end-1)-latlim)<0.1) & (detnum(1:end-1)==5) & (diff_nlat<0));
%             
%             diff_nn = diff(nn);
%             mm = find(diff_nn > 50);
%             
% % % %             nn_start = [nn(mm)' nn(end)] - 100;
% % % %             nn_end = [nn_start(2:end)-1 length(nlat)-100] + 100;
% % % % 
% % % %             nn_start(1) = max(nn_start(1), 1);
% % % %             nn_end(end) = min([nn_end(end), length(nlon)]);
%             
%             nn_start = [1 nn(mm)'];
%             nn_end = nn_start + 40271;
%             nn_end(end) =length(nlon);
%             
%             % Test to see if the end of the a given orbit is more than 
%             % +/- 20 scan lines from the beginning of the next orbit. If it
%             % is flag it.
%             
%             for iOrbit=1:length(nn_start)-1
%                 if abs(nn_end(iOrbit) - nn_start(iOrbit+1)) > 20
%                     fprintf('\n********\nLength of %i (Orbit #\i) differs from 40,271 by more than 20 scan lines.\n********\n', iOrbit, orbit_no(iOrbit))
%                     
%                     iProblemOrbit = iProblemOrbit + 1;
%                     problem_orbits(iProblemOrbit) = orbit_no(iOrbit);
%                     
%                     keyboard
%                 end
%                 
%             orbit_info.scan_line_start = nn_start;
%             orbit_info.scan_line_end = nn_end;
%             
%             orbit_info.matlab_times = matlab_time(nn_start);
%             orbit_info.matlab_timee = matlab_time(nn_end);
%             
%             if save_long
%                 orbit_info.nlons = nlon(nn_start);
%                 orbit_info.nlats = nlat(nn_start);
%                 
%                 orbit_info.matlab_times = matlab_time(nn_start);
%                 orbit_info.matlab_timee = matlab_time(nn_end);
%             end
%             
%             % Now save.
%             
%             % Subtract a year from the value used in the filename if the
%             % previous month, month_save=12, since the year would have been
%             % incremented when going from month 12 to month 1.
%             
%             year_for_name = iyears;
%             if month_save == 12
%                 year_for_name = convertStringsToChars(num2str(iyear - 1));
%             end
%             
%             if save_long
%                 save( [base_dir_out, 'Orbits/nadir_info_' year_for_name '_' return_a_string(month_save) '_long'], ...
%                     'filenames', 'orbit_number', 'filename_index', 'matlab_time', '*lon', '*lat', 'detnum', ...
%                     'nsol_z', 'scan_line_in_file', 'orbit_info', 'latlim');
%             else
%                 save( [base_dir_out, 'Orbits/nadir_info_' year_for_name '_' return_a_string(month_save)], ...
%                     'filenames', 'filename_index', 'scan_line_in_file', 'nsol_z', 'orbit_info');
%             end
%             
%             % Populate the last orbit info.
%             
% %             if save_long
%                 matlab_time = matlab_time(nn_start(end):end);
%                 
%                 slat = slat(nn_start(end):end);
%                 slon = slon(nn_start(end):end);
%                 
%                 elat = elat(nn_start(end):end);
%                 elon = elon(nn_start(end):end);
%                 
%                 nlat = nlat(nn_start(end):end); % Although not saved for short file it is used below
%                 nlon = nlon(nn_start(end):end);
%                     
%                 detnum = detnum(nn_start(end):end);
%                 
%                 nsol_z = nsol_z(nn_start(end):end);
%                 scan_line_in_file = scan_line_in_file(nn_start(end):end);
% %             end
%             
%             jgranule = 0;
%             for igranule=filename_index(nn_start(end)):filename_index(end)
%                jgranule = jgranule + 1;
%                temp(jgranule) = filenames(igranule);
%             end
%             
%             filenames = temp;
%             filename_index = filename_index(nn_start(end):end) - filename_index(nn_start(end)) + 1;
% 
%             iFilename = jgranule;
%                         
%             month_save = imonth;
%             
%             if plotem; iFig = plot_orbits(iFig, nlon, nlat, orbit_info); end
%         else
% %             if save_long
%                 matlab_time = [];
%                 
%                 slat = [];
%                 slon = [];
%                 
%                 elat = [];
%                 elon = [];
% %             end
%             
%             nlat = [];
%             nlon = [];
%             
%             detnum = [];
%             
%             nsol_z = [];
%             scan_line_in_file = [];
% 
%             filename_index = [];
%             
%             iFilename = 0;
%             
%             clear filenames missing_granules
%             
%             month_save = imonth;
%         end
%     end
    
    iFilename = iFilename + 1;
    
    % See if this file exists. If not, nans for missing data.
    
    granule_found = 1;
    
    if sw3
        % Need to put sw3 stuff here.
    else
        new_fi_list = dir([base_dir_in 'day/' iyears '/AQUA_MODIS.' iyears imonths idays 'T' ihours iminutes '*']);
        
% % %         if isempty(new_fi_list)
% % %             new_fi_list = dir([base_dir_in 'night/' iyears '/AQUA_MODIS.' iyears imonths idays 'T' ihours iminutes '*']);
% % %             
% % %             if isempty(new_fi_list)
% % %                 disp(['Could not file file: AQUA_MODIS.' iyears imonths idays 'T' ihours iminutes '*'])
% % %                 granule_found = 0;
% % %             else
% % %                 fi = [new_fi_list(1).folder '/' new_fi_list(1).name];
% % %             end
% % %         else
% % %             fi = [new_fi_list(1).folder '/' new_fi_list(1).name];
% % %         end
        
        granule_found = 1;
        
        if isempty(dir([base_dir_in 'day/' iyears '/AQUA_MODIS.' iyears imonths idays 'T' ihours iminutes '*'])) == 1
            fi = [new_fi_list(1).folder '/' new_fi_list(1).name];
        elseif isempty(dir([base_dir_in 'night/' iyears '/AQUA_MODIS.' iyears imonths idays 'T' ihours iminutes '*'])) == 1
            fi = [new_fi_list(1).folder '/' new_fi_list(1).name];
        else
            fprintf('Could not file file: AQUA_MODIS. %s%s%sT%i%i*\n', iyears, imonths, idays, ihours, iminutes)
            granule_found = 0;
        end
    end
    
    % Get info about this granule.
    
    if granule_found
        
        if nc_read
            info = ncinfo(fi);
            
            if strcmp(info.Dimensions(1).Name, 'number_of_lines') ~= 1
                fprintf('\n********\nWrong dimension: %s\n********\n', info.Dimensions(1).Name)
                break
            end
            nscans = info.Dimensions(1).Length;
            
            % Does this granule contain the start of a new orbit?
            
            nlat_t = single(ncread(fi, '/scan_line_attributes/clat'));
            nlon_t = single(ncread(fi, '/scan_line_attributes/clon'));

            detnum = [detnum; int8(ncread(fi, '/scan_line_attributes/detnum'))];

            diff_nlat = diff(nlat_t);
            nn = find( (abs(nlat_t(1:end)-latlim)<0.1) & (detnum(1:end-1)==5) & (diff_nlat<0));
            
            if isempty(nn) == 0
                
                % New orbit, save the previous orbit and initialize all variables. 
                
                if first_orbit
                    first_orbit = 0;
                    
                    if save_long
                        save( filename_out, ...
                            'filenames', 'orbit_number', 'filename_index', 'matlab_time', '*lon', '*lat', 'detnum', ...
                            'nsol_z', 'scan_line_in_file', 'orbit_info', 'latlim');
                    else
                        save( filename_out, ...
                            'filenames', 'filename_index', 'scan_line_in_file', 'nsol_z', 'orbit_info');
                    end
                else
                    
                    filename_out = [base_dir_out, 'Orbits/Orbit_' num2str(pcc_orbit_number) '_nadir_info_' year_for_name '_' return_a_string( 2, month_save) '_long'];
                    
                end
                
            else
            end
            
            diff_nn = diff(nn);
            mm = find(diff_nn > 50);
            
            nn_start = [1 nn(mm)'];
            nn_end = nn_start + 40271;
            nn_end(end) =length(nlon);
            
            filenames{iFilename} = fi;
            
            filename_index = [filename_index; int32(ones(nscans,1)*iFilename)];
            
            if strcmp(info.Attributes(5).Name, 'orbit_number') ~= 1
                fprintf('\n********\nWrong attribute: %s\n********\n', info.Dimensions(2).Name)
                break
            end
            orbit_number(iFilename) = int32(info.Attributes(5).Value);
            
%             if save_long
                sl_year = ncread(fi, '/scan_line_attributes/year');
                sl_day = ncread(fi, '/scan_line_attributes/day');
                sl_msec = floor(ncread(fi, '/scan_line_attributes/msec'));
                matlab_time = [matlab_time; datenum(sl_year, 1, sl_day) + sl_msec/86400000];
                
                % Track of swath edges.
                
                slat = [slat; single(ncread(fi, '/scan_line_attributes/slat'))];
                slon = [slon; single(ncread(fi, '/scan_line_attributes/slon'))];
                
                elat = [elat; single(ncread(fi, '/scan_line_attributes/elat'))];
                elon = [elon; single(ncread(fi, '/scan_line_attributes/elon'))];
%             end
            
            % Nadir track.
            
            nlat = [nlat; single(ncread(fi, '/scan_line_attributes/clat'))];
            nlon = [nlon; single(ncread(fi, '/scan_line_attributes/clon'))];
                
            detnum = [detnum; int8(ncread(fi, '/scan_line_attributes/detnum'))];
            
            nsol_z = [nsol_z; int16(ncread(fi, '/scan_line_attributes/csol_z'))];
            scan_line_in_file = [scan_line_in_file int16([1:nscans])];
        else
            info = h5info(fi);
            
            if strcmp(info(1).Datasets(3).Name, 'number_of_lines') ~= 1
                fprintf('\n********\nWrong dimension: %s\n********\n', info.Dimensions(1).Name)
                break
            end
            nscans = info(1).Datasets(3).Dataspace.Size;
            
            filenames{iFilename} = fi;
            
            filename_index = [filename_index; int32(ones(nscans,1)*iFilename)];
            
%             if save_long
                orbit_number(iFilename) = int32(h5readatt( fi, '/', 'orbit_number'));
                
                sl_year = double(h5read(fi, '/scan_line_attributes/year'));
                sl_day = double(h5read(fi, '/scan_line_attributes/day'));
                sl_msec = double(floor(h5read(fi, '/scan_line_attributes/msec')));
                matlab_time = [matlab_time; datenum(sl_year, 1, sl_day) + sl_msec/86400000];
                
                % Track of swath edges.
                
                slat = [slat; single(h5read(fi, '/scan_line_attributes/slat'))];
                slon = [slon; single(h5read(fi, '/scan_line_attributes/slon'))];
                
                elat = [elat; single(h5read(fi, '/scan_line_attributes/elat'))];
                elon = [elon; single(h5read(fi, '/scan_line_attributes/elon'))];
%             end
            
            % Nadir track.
            
            nlat = [nlat; single(h5read(fi, '/scan_line_attributes/clat'))];
            nlon = [nlon; single(h5read(fi, '/scan_line_attributes/clon'))];
                
            detnum = [detnum; int8(h5read(fi, '/scan_line_attributes/detnum'))];
            
            nsol_z = [nsol_z; int16(h5read(fi, '/scan_line_attributes/csol_z'))];

            scan_line_in_file = [scan_line_in_file int16([1:nscans])];
        end
    else
        iMissing = iMissing + 1;
        missing_granules{iMissing} = [base_dir_in 'night/' iyears '/AQUA_MODIS.' iyears imonths idays 'T' ihours iminutes];
        
        filenames{iFilename} = missing_granules{iMissing};
        
        filename_index = [filename_index; int32(nan(nscans,1))];
        
%         if save_long
            orbit_number(iFilename) = int32(nan);
            
            matlab_time = [matlab_time; double(nan(nscans,1))];
                        
            slat = [slat; single(nan(nscans,1))];
            slon = [slon; single(nan(nscans,1))];
            
            elat = [elat; single(nan(nscans,1))];
            elon = [elon; single(nan(nscans,1))];
%         end
        
        nlat = [nlat; single(nan(nscans,1))];
        nlon = [nlon; single(nan(nscans,1))];
            
        detnum = [detnum; int8(nan(nscans,1))];
        
        nsol_z = [nsol_z; int16(nan(nscans,1))];

        scan_line_in_file = [scan_line_in_file int16(1:nscans)];
    end
end

% Save the last month's worth of data. Start by getting the beginning and
% end info for each orbit.

diff_nlat = diff(nlat);
nn = find(abs(nlat(1:end-1)-latlim)<0.1 & detnum(1:end-1)==5 & diff_nlat>0);

diff_nn = diff(nn);
mm = find(diff_nn > 50);
if isempty(mm)
    disp(['The data for this month does not include the beginning of an orbit.'])
    orbit_info = [];
else
    
    nn_start = [nn(mm)' nn(end)];
    nn_end = [nn_start(2:end)-1 length(nlat)-100] + 100;
    
    nn_start(1) = max(nn_start(1), 1);
    nn_end(end) = min(nn_end(end), length(nlon));
    
    orbit_info.scan_line_start = nn_start;
    orbit_info.scan_line_end = nn_end;
    
    orbit_info.matlab_times = matlab_time(nn_start);
    orbit_info.matlab_timee = matlab_time(nn_end);
    
    if save_long
        orbit_info.det_nums = detnum(nn_start);
        orbit_info.det_nume = detnum(nn_end);
        
        orbit_info.filenames = filenames(filename_index(nn_start));
        orbit_info.filenamee = filenames(filename_index(nn_end));
        
        orbit_info.filenames_index = filename_index(nn_start);
        orbit_info.filenamee_index = filename_index(nn_end);
        
        orbit_info.nlons = nlon(nn_start);
        orbit_info.nlats = nlat(nn_start);
        
        orbit_info.nlone = nlon(nn_end);
        orbit_info.nlate = nlat(nn_end);
    end
end

% Subtract a year from the value used in the filename if the
% previous month, month_save=12, since the year would have been
% incremented when going from month 12 to month 1.

year_for_name = iyears;
if month_save == 12
    year_for_name = convertStringsToChars(num2str(iyear - 1));
end

if save_long
    save( [base_dir_out, 'Orbits/nadir_info_' year_for_name '_' return_a_string( 2, month_save) '_long'], ...
        'filenames', 'orbit_number', 'filename_index', 'matlab_time', '*lon', '*lat', 'detnum', ...
        'nsol_z', 'scan_line_in_file', 'orbit_info', 'latlim');
else
    save( [base_dir_out, 'Orbits/nadir_info_' year_for_name '_' return_a_string( 2, month_save)], ...
        'filenames', 'filename_index', 'scan_line_in_file', 'nsol_z', 'orbit_info');
end

toc

if plotem; iFig = plot_orbits(iFig, nlon, nlat, orbit_info); end

%% Functions.

function iFig = plot_orbits(iFig, nlon, nlat, orbit_info)
figure(iFig)
iFig = iFig + 1;
clf

% xx = nlon;
% xx(xx<0) = xx(xx<0) +360;
% plot(xx,nlat,'.k')
plot(nlon,nlat,'.k')
hold on

load coastlines.mat
% yy = coastlon;
% yy(yy>0) = yy(yy>0) - 360;
% diffyy = diff(yy);
% nn = find(abs(diffyy)>50);
% yy(nn+1) = nan;
% plot(yy,coastlat, 'r', linewidth=2)
plot(coastlon,coastlat,'c',linewidth=2)

plot(orbit_info.nlons, orbit_info.nlats, 'ok', markersize=10, markerfacecolor='g')
plot(orbit_info.nlone, orbit_info.nlate, 'ok', markersize=10, markerfacecolor='r')
plot(nlon(orbit_info.scan_line_start(1):orbit_info.scan_line_end(1)), nlat(orbit_info.scan_line_start(1):orbit_info.scan_line_end(1)), 'r.', linewidth=3)
for i=1:length(orbit_info.scan_line_start)
    plot(nlon(orbit_info.scan_line_start(i):orbit_info.scan_line_end(i)), nlat(orbit_info.scan_line_start(i):orbit_info.scan_line_end(i)), '.', linewidth=3)
end
