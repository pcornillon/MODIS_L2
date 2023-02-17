function weight_error = generate_weights_for_fast_regridding( ancillary_data_dir, base_dir_logs, base_dir_out, start_date_time, scan_line)
% build_and_fix_orbits - read in all granules for each orbit in the time range and fix the mask and bowtie - PCC
%
% This function will read all of the
%
% INPUT
%   ancillary_data_dir - data used to fix reference temperature problem and
%    bow-tie problem.
%   base_dir_out - the base directory for the output files. Note that this
%    must be the full directory name,netCDF doesn't like ~/.
%   start_date_time - build orbits with the first orbit to be built including
%    this time specified as: [YYYY, MM, DD, HH, Min, 00]. The script will
%    build the first complete orbit starting after this time and use this
%    orbit to determine the weights and locations.
%   scan_line - first scan line in group of 11 to use.
%
% OUTPUT
%   weight_error - 0 if successful processing, 1 if error.
%
% EXAMPLE
%   AQUA_MODIS.20100701T022209.L2.SST.nc4
%   ancillary_data_dir = '/Users/petercornillon/Dropbox/ComputerPrograms/MATLAB/Projects/Preliminary_Operations/Data/';
%   base_dir_out = '/Users/petercornillon/Dropbox/ComputerPrograms/MATLAB/Projects/Build_Fixed_Orbital_Files/Data/';
%   base_dir_logs = '/Users/petercornillon/Dropbox/ComputerPrograms/MATLAB/Projects/Preliminary_Operations/Logs/';
%   weight_error = generate_weights_for_fast_regridding(ancillary_data_dir, base_dir_logs, base_dir_out, [2010 7 1 2 20 0], 11151);
%

date

weight_error = 0;

generate_separations_and_angles

%% Initialize some variables.

acceptable_start_time = datenum(2002, 7, 1);
acceptable_end_time = datenum(2022, 12, 31);

%% Check input parameters to make sure they are OK.

if length(start_date_time) ~= 6
    disp(['Input start time vector must be 6 elements long. start_date_time: ' num2str(start_date_time) ' to ' num2str(end_date_time)])
    build_error = 1;
    return
end

matlab_start_time = datenum(start_date_time);

if (matlab_start_time < acceptable_start_time) | (matlab_start_time > acceptable_end_time)
    disp(['Specified start time ' datestr(matlab_start_time) ' not between ' datestr(acceptable_start_time) ' and ' datestr(acceptable_end_time)])
    build_error = 1;
    return
end

if strcmp(base_dir_out(1:2), '~/')
    disp(['The output base directory must be fully specified; cannot start with ~/. Won''t work with netCDF. You entered: ' base_dir_out])
    build_error = 1;
    return
end

if rem(scan_line-1,10) ~= 0
    disp(['The starting scan line must end in 1. The values you entered resulted in: ' num2str(scan_line)])
    keyboard
end

%% Passed checks on input parameters. Open a diary file for this run.

Diary_File = [base_dir_logs 'build_weights_' strrep(num2str(now), '.', '_') '.txt'];
diary(Diary_File)

tic_build_start = tic;

%% Get the nadir track information for the month containing the start time.

orbit_filename = [ancillary_data_dir 'nadir_info_' return_a_string(start_date_time(1)) '_' return_a_string(start_date_time(2)) '.mat'];

if exist(orbit_filename) == 2
    load(orbit_filename, 'filenames', 'filename_index', 'orbit_info', 'scan_line_in_file');
else
    fprintf('No nadir track info for this start time.\n\n')
    return
end

%% Get the first and last orbits to build and fix.

% Subtract a minute from the beginning. This, just in case, the user was 
%  going for a beginning time equal to the specified time but was a hair off. 

start_orbit_no_temp = find(matlab_start_time <= orbit_info.matlab_times-1/(60*24));

if isempty(start_orbit_no_temp) == 1
    disp(['There is not one starting orbit at time ' datestr(matlab_start_time)])
    keyboard
end
start_orbit_no = start_orbit_no_temp(1);

%%

disp(['Will process from orbit # ' num2str(start_orbit_no) ' (' datestr(matlab_start_time) ').'])

for iOrbit=start_orbit_no
    
    start_time_this_orbit = tic;
    
    file_list = filenames(filename_index(orbit_info.scan_line_start(iOrbit)):filename_index(orbit_info.scan_line_end(iOrbit)));
    
    % Build the output filename for this file and check to see if it
    % exists. If so, go to the next orbit.
    
    formatOut = 'yyyymmddTHHMMSS';
    orbit_file_name = ['AQUA_MODIS.' datestr(orbit_info.matlab_times(iOrbit), formatOut) '.L2.SST'];
    
    formatOut = 'yyyy';
    years = datestr(orbit_info.matlab_times(iOrbit), formatOut);
    
    formatOut = 'mm';
    months = datestr(orbit_info.matlab_times(iOrbit), formatOut);
    
    name_out_sst = [base_dir_out 'SST/' years '/' months '/' orbit_file_name '.nc4'];
    
    if exist(name_out_sst) ~= 2
        
        disp(['Working on orbit # ' num2str(iOrbit) '. Output will be written to: ' orbit_file_name ])
        
        %% Now build this orbit from its granules.
        
        latitude = [];
        longitude = [];
        SST_In = [];
        qual_sst = [];
        flags_sst = [];
        sstref = [];
        
        tic
        mscans = 0;
        for ifilename=1:length(file_list)
            toc
            fi = file_list{ifilename};
            
            % Get the scans to read for this granule.
            
            info = ncinfo(fi);
            if strcmp(info.Dimensions(1).Name, 'number_of_lines') ~= 1
                disp(['Wrong dimension: ' info.Dimensions(1).Name])
                keyboard
            end
            nscans = info.Dimensions(1).Length;
            mscans = mscans + nscans;
            npixels = info.Dimensions(2).Length;
            
            if ifilename == 1
                %         sscan = scan_line_in_file(new_iOrbit(1)-100);
                %         lscan = nscans - sscan + 1;
                sscan = scan_line_in_file(orbit_info.scan_line_start(iOrbit));
                lscan = nscans - sscan + 1;
                
                % Get the global attributes for this file to use in the
                % fronts/gradients workflow output files
                
                GlobalAttributes = ncinfo(file_list{1});
                time_coverage_start = ncreadatt(file_list{1}, '/', 'time_coverage_start');
                
            elseif ifilename == length(file_list)
                sscan = 1;
                % Add one more line to facilitate bowtie fix.
                %         lscan = scan_line_in_file(new_start_orbit_no(2)) + 1;
                lscan = scan_line_in_file(orbit_info.scan_line_end(iOrbit)) + 1;
            else
                sscan = 1;
                lscan = nscans;
            end
            
            % OK, now read Lat, Lon, SST,...
            
            latitude = [latitude, single(ncread(fi, '/navigation_data/latitude', [1 sscan], [npixels lscan]))];
            longitude = [longitude, single(ncread(fi, '/navigation_data/longitude', [1 sscan], [npixels lscan]))];
            
            SST_In = [SST_In, single(ncread(fi, '/geophysical_data/sst', [1 sscan], [npixels lscan]))];
            qual_sst = [qual_sst, int8(ncread(fi, '/geophysical_data/qual_sst', [1 sscan], [npixels lscan]))];
            flags_sst = [flags_sst, int16(ncread(fi, '/geophysical_data/flags_sst', [1 sscan], [npixels lscan]))];
            sstref = [sstref, single(ncread(fi, '/geophysical_data/sstref', [1 sscan], [npixels lscan]))];
            
        end
        
        disp(['*** Time to build this orbit: ' num2str(toc(start_time_this_orbit),5) ' seconds.'])
        
        %% Next find the four sections of this orbit.
        
        start_weights_tic = tic;
        
        % Assume that the orbits start descending at 75 S. The orbit will be broken
        % up into 4 sections:
        %   1) scan lines with nadir values south of 75 S east-to-west,
        %   2) lines with nadir values ascending from 75 S to 75 N,
        %   3) lines with nadir values north of 75 N east-to-west and
        %   4) lines with nadir values from 75 N descending to 75 S.
        
        latn = latitude(677,:);  % Latitude of the nadir track.
        
        % First the part near the beginning of the orbit.
        
        north_lat_limit = 75;
        south_lat_limit = -75;
        
        nn = find(latn(1:floor(mscans/4)) < south_lat_limit);
        
        region_start(1) = 1;
        region_end(1) = floor(nn(end)/10) * 10;
        
        nn = find(latn(1:end) > north_lat_limit);
        
        region_start(2) = region_end(1) + 1;
        region_end(2) = floor(nn(1) / 10) * 10;
        
        region_start(3) = region_end(2) + 1;
        region_end(3) = floor(nn(end) / 10) * 10;
        
        region_start(4) = region_end(3) + 1;
        region_end(4) = size(longitude,2);
        
        %% Get the new lats and lons for the specified 11 detector region.
        
        fprintf('Working on offset %i\n', scan_line)
        
        kScan = scan_line + 10;
        iScanVec = [scan_line:kScan-1];
        
% % %         lat_separation = latitude(:,kScan) - latitude(:,scan_line);
% % %         lon_separation = longitude(:,kScan) - longitude(:,scan_line);
% % %         
% % %         mult = [0:kScan-scan_line-1] / (kScan - scan_line);
% % %         
% % %         new_lat(:,iScanVec) = latitude(:,scan_line) + lat_separation * mult;
% % %         new_lon(:,iScanVec) = longitude(:,scan_line) + lon_separation * mult;
% % %         
% % %         new_lat(:,iScanVec(end)+1) = latitude(:,iScanVec(end)+1);
% % %         new_lon(:,iScanVec(end)+1) = longitude(:,iScanVec(end)+1);
        
        %% Now get the weights and locations for the selected scan line.
        
        ilower = 1;
        iupper = size(longitude,1);
        
        jmid = (scan_line + kScan) / 2;
        if ( (jmid > region_start(2)) & (jmid < region_end(2)) ) | ( (jmid > region_start(4)) & (jmid < region_end(4)) )
            % Region 2 or 4 - neither Arctic nor Antarctic region.
            
            lat_separation = latitude(:,kScan) - latitude(:,scan_line);
            lon_separation = longitude(:,kScan) - longitude(:,scan_line);
            
            mult = [0:kScan-scan_line-1] / (kScan - scan_line);
            
            new_lat(:,iScanVec) = latitude(:,scan_line) + lat_separation * mult;
            new_lon(:,iScanVec) = longitude(:,scan_line) + lon_separation * mult;
            
            new_lat(:,iScanVec(end)+1) = latitude(:,iScanVec(end)+1);
            new_lon(:,iScanVec(end)+1) = longitude(:,iScanVec(end)+1);
            
            x_coor = double(longitude(:,scan_line:kScan));
            y_coor = double(latitude(:,scan_line:kScan));
            
            new_x_coor = double(new_lon(:,scan_line:kScan));
            new_y_coor = double(new_lat(:,scan_line:kScan));
        elseif (jmid > region_start(1)) & (jmid < region_end(1)) 
            % Region 1 - Antarctic region
            fprintf('Not setup to process an orbit in the arctic or antarctic.')
            keyboard

        else (jmid > region_start(3)) & (jmid < region_end(3)) 
            % Region 3 - Arctic region

            scans_to_do = [region_start(1):region_end(1)+1];
            [easting(:,scans_to_do), northing(:,scans_to_do)] = ll2ps(latitude(:,scans_to_do), longitude(:,scans_to_do));
            
            fprintf('Not setup to process an orbit in the arctic or antarctic.')
            keyboard
        end
        
        %% Generate weights
        
        % Set the value of the point in the input array on which we are
        % working to 1.
        
        vin = zeros(size(x_coor));
        [in, jn] = size(vin);
        
        % Initialize the temporary weights and locations matrices.
        
        temp_weights = cell(in, jn);
        temp_locations = cell(in, jn);
        temp_locations_ind = cell(in, jn);
        temp_locations_i = cell(in, jn);
        temp_locations_j = cell(in, jn);
        max_num = 0;
        
        % Get matrices to regrid
        
        starttic = tic;
        for j_in=1:jn
            
            disp(['Working on line ' num2str(j_in) ' ' num2str(toc(starttic)) ' seconds.'])
                        
            for i_in=1:in
                
                vin(i_in,j_in) = 1;
                
                nn_in = sub2ind(size(vin), i_in, j_in);
                
                vout = griddata( x_coor, y_coor, vin, new_x_coor, new_y_coor, 'linear');
                
                [i_out, j_out] = find( (vout~=0) & (isnan(vout)==0) );
                nn_out = sub2ind(size(vout), i_out, j_out);
                
                for k_out=1:length(nn_out)
                    temp_weights(i_out(k_out),j_out(k_out)) = {[temp_weights{i_out(k_out),j_out(k_out)} vout(i_out(k_out),j_out(k_out))]};
                    temp_locations(i_out(k_out),j_out(k_out)) = {[temp_locations{i_out(k_out),j_out(k_out)} nn_in]};
                    
                    if max_num < length(temp_locations{i_out(k_out),j_out(k_out)})
                        max_num = length(temp_locations{i_out(k_out),j_out(k_out)});
                    end
                    
                    temp_locations_ind(i_out(k_out),j_out(k_out)) = {[temp_locations_ind{i_out(k_out),j_out(k_out)} [i_in j_in]]};
                    temp_locations_i(i_out(k_out),j_out(k_out)) = {[temp_locations_i{i_out(k_out),j_out(k_out)} i_in]};
                    temp_locations_j(i_out(k_out),j_out(k_out)) = {[temp_locations_j{i_out(k_out),j_out(k_out)} j_in]};
                end
                
                vin(i_in,j_in) = 0;
            end
        end
        
        % Repack weights and locations in max_num (the maximum number
        % of input points contributing to output points) of arrays one
        % for each location. Sort the values first so that the largest
        % values at each location are in the first array,... The
        % sorting is not necessary but may be useful in the future.
        
        % Start by creating the weights and locations arrays.
        
        weights = single(zeros(max_num, in, jn));
        locations = int32(zeros(max_num, in, jn));
        locations_i = int16(zeros(max_num, in, jn));
        locations_j = int16(zeros(max_num, in, jn));
        
        fprintf('Maximum number of input elements contributing to an output element for this region: %i \n', max_num)
        
        % Loop over all points in the region being processed.
        
        for i_out=1:in
            for j_out=1:jn
                
                % Sort the weights for this point, remembering where in
                % the temp_weights each of the new weights was.
                
                [wtemp, iwtemp] = sort(temp_weights{i_out,j_out}, 'descend');
                
                % Loop over the number of input points contributing to
                % this new output point and save the weights and
                % locations in the appropriate array elements.
                
                for k_out=1:length(wtemp)
                    weights(k_out,i_out,j_out) = wtemp(k_out);
                    locations(k_out,i_out,j_out) = temp_locations{i_out,j_out}(iwtemp(k_out));
                    
                    locations_ind(k_out,i_out,j_out) = temp_locations_ind{i_out,j_out}(iwtemp(k_out));
                    locations_i(k_out,i_out,j_out) = temp_locations_i{i_out,j_out}(iwtemp(k_out));
                    locations_j(k_out,i_out,j_out) = temp_locations_j{i_out,j_out}(iwtemp(k_out));
                end
            end
        end
        
        disp(['*** Time to generate weights and locations for this scan line: ' num2str(toc(start_weights_tic),5) ' seconds.'])
        
        %% Finally save.
        
        filename_out = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weights_' num2str(scan_line) '.mat'];
        first_granule_used = file_list{1};
        save( filename_out, 'weights*', '*_separation', 'locations*', 'max_num', 'scan_line', 'first_granule_used');
        
    end
end
