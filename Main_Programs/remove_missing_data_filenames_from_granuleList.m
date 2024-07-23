function [status, granule_start_time] = remove_missing_data_filenames_from_granuleList(yearStart, yearEnd)
% remove_missing_data_filenames_from_granule_list - PCC
%
% This function will step through granuleList and removes entries with no
% corresponding data files at AWS.
%
% INPUT
%   yearStart: Process from this year to yearEnd.
%   yearEnd: Last year to process
%
% OUTPUT
%   newList - updated version of granuleList.
%
% Granule file names:
%
% Local     data granule: ~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/combined/2010/AQUA_MODIS.20100619T052000.L2.SST.nc'
% Local metadata granule: ~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections/MODIS_R2019/Data_from_OBPG_for_PO-DAAC/2010/AQUA_MODIS_20100619T052000_L2_SST_OBPG_extras.nc4
%
% s3 data granule: s3://podaac-ops-cumulus-protected/MODIS_A-JPL-L2P-v2019.0/20100619052000-JPL-L2P_GHRSST-SSTskin-MODIS_A-D-v02.0-fv01.0.nc
%
%  CHANGE LOG
%   v. #  -  data    - description     - who
%
%   1.0.0 - 7/23/2024 - Initial version - PCC

global version_struct
version_struct.remove_missing_data_filenames_from_granuleList = '1.0.0';

global s3_expiration_time

% globals for the run as a whole.

global print_diagnostics

% globals for build_orbit part.

global amazon_s3_run

global granuleList iGranuleList filenamePrefix filenameEnding numGranules

global oinfo iOrbit iGranule
global scan_line_times start_line_index num_scan_lines_in_granule
global Matlab_end_time

global skip_to_start_of_orbit

% globals used in the other major functions of build_and_fix_orbits.

global iProblem problem_list 

% Get AWS credentials.

[status, s3Credentials] = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', 'eiMTJr6yeuD6');

% if status == 921
if status >= 900
    return
end

% Initialize variables.

metadata_directory = '/mnt/s3-uri-gso-pcornillon/Data_from_OBPG_for_PO-DAAC/';

% Loop over years to process

jGranule = 0;
for iYear=yearStart:yearEnd
    
    GranuleListIn = load([metadata_directory 'metadata_granule_lists/GoodGranuleList_' num2str(iYear) '.mat']);
    
    for iGranule=1:length(GranuleListIn.granuleList)
        granuleTime = GranuleListIn.granuleList(iGranule).first_scan_line_time;

        if (granuleTime >= matStart) & (granuleTime < matEnd)
            
            jGranule = jGranule + 1;
            
            granuleList(jGranule).filename = GranuleListIn.granuleList(iGranule).filename(12:26);
            granuleList(jGranule).filename_time = GranuleListIn.granuleList(iGranule).filename_time;
            granuleList(jGranule).first_scan_line_time = GranuleListIn.granuleList(iGranule).first_scan_line_time;
        end
    end

    clear GranuleListIn

    iGranuleList = 0;
end

numGranules = length(granuleList);


jGranuleList = 0;
for iGranuleList=1:numGranules

    if (now - s3_expiration_time) > 30 / (60 * 24)
        [status, s3Credentials] = loadAWSCredentials('https://archive.podaac.earthdata.nasa.gov/s3credentials', 'pcornillon', 'eiMTJr6yeuD6');

        if status >= 900
            fprintf('Problem getting AWS credentials. iGranuleList=%i\n.', iGranuleList)
            return
        end
    end







    
    search_start_time = granuleList(iGranuleList).first_scan_line_time;




    fiveMinutesMatTime = 5 / (24 * 60);

% Initialize return variables.

status = 0;
indices = [];
data_file_list = [];
% % % metadata_file_list = [];

% Start of loop searching for next granule.

while 1==1

    start_line_index = [];

    % Increment the granule number on the list of granules to use for this
    % run and check to make sure it isn't beyond the end of the list or
    % that the corresponding time is passed the end of the run.

    iGranuleList = iGranuleList + 1;

    if iGranuleList > numGranules
        status = populate_problem_list( 910, ['Ran out of granules. Only ' num2str(numGranules) ' on the list and the granule count has reached ' num2str(iGranuleList) '.'], granuleList(iGranuleList-1).first_scan_line_time+fiveMinutesMatTime); % old status 903
        return
    else
        granule_start_time = granuleList(iGranuleList).first_scan_line_time;
    end

    if granule_start_time > Matlab_end_time
        status = populate_problem_list( 915, ['Current time, ' datestr(granule_start_time) ', beyond end of run time ' datestr(Matlab_end_time) '.'], granule_start_time); % old status 901
        return
    end

    % Is this time passed the end time of the orbit? Only check if an orbit
    % already exists from which the time has been calculated; i.e., do not
    % check if the script is looking for the first granule that crosses 79
    % S. If the orbit does exist but this time is beyond the end of an end
    % of the orbit, flag and return; it means that at least one granule at
    % the end of the orbit was missing. I'm not comfortable with this so
    % need to check how often it happens and fix manually if it happens on
    % occasion, otherwise will have to code a fix.

    if (length(oinfo) == iOrbit) & ~skip_to_start_of_orbit
        if ~isempty(oinfo(iOrbit).end_time)
            if granule_start_time > (oinfo(iOrbit).end_time - 2 * secs_per_scan_line / secs_per_day)
                status = populate_problem_list( 705, ['Granule past predicted end of orbit time: ' datestr(oinfo(iOrbit).end_time)], granule_start_time); % old status 201

                skip_to_start_of_orbit = true;
                return
            end
        end
    end

    % Get the next metadata granule.

    [status, found_one, metadata_granule_folder_name, metadata_granule_file_name, granule_start_time] = get_filename('metadata');

    if status >= 900
        return
    end
    
    % Was a metadata file found at this time? If so proceed, if not
    % increment time to search by 5 minutes and search for the next
    % metadata file.

    if found_one == 1
        % Get the metadata filename.

        metadata_temp_filename = [metadata_granule_folder_name metadata_granule_file_name];

        % Before proceeding, make sure that there are either 2030 or 2040
        % scan lines in this granule. When this is not the case, things
        % seem to get out of whack, so skip the granule.

        granule_info = ncinfo(metadata_temp_filename);

        good_granule = 0;

        for iDim=1:length(granule_info.Dimensions)
            if strcmp(granule_info.Dimensions(iDim).Name, 'number_of_lines') == 1
                if (granule_info.Dimensions(iDim).Length == 2030) | (granule_info.Dimensions(iDim).Length == 2040)
                    good_granule = 1;
                end
                break
            end
        end

        if good_granule == 0
            status = populate_problem_list( 625, ['Bad granule (' num2str(iGranule) ') ' metadata_temp_filename '. Number of scan lines, ' num2str(granule_info.Dimensions(iDim).Length) ', is neither 2030 nor 2040. Skipping granule.']); % old status 111
        else
            % Is the data granule for this time present? If so, get the range
            % of locations of scanlines in the orbit and the granule to use.
            % Otherwise, add to problem list and continue search for a data
            % granule; remember, a metadata granule was found so this should
            % not occur. BUT FIRST, search for a granule within a minute of
            % the time passed in.

            [status, found_one, data_granule_folder_name, data_granule_file_name, ~] = get_filename('sst_data');

            if found_one
                data_temp_filename = [data_granule_folder_name data_granule_file_name];
                
                % Does this granule ascend past 79 S. 

                [status, granule_start_time] = check_for_latlim_crossing( metadata_granule_folder_name, metadata_granule_file_name, granule_start_time);

                % If status not equal to zero, either problems with start times
                % or 1st detector, not 1st detector in group of 10. Neither of
                % these should happen so we will assume that this granule is
                % bad and go to the next one.

                if status < 600

                    %**************************************************************** Straightforward to this point ********************************************************************** 

                    if skip_to_start_of_orbit & isempty(start_line_index)

                        % Will looking for the first granule with an ascending crossing of 79 S.

                        fprintf('\nGranule at %s does not ascend across 79 S. Will continue searching.\n\n', datestr(granule_start_time))
                    else

                        iGranule = iGranule + 1;

                        % Populate oinfo for this granule for info. oinfo(iOrbit).name
                        % has not been defined yet but will be shortly using some
                        % of these values.

                        oinfo(iOrbit).ginfo(iGranule).data_name = data_temp_filename;

                        oinfo(iOrbit).ginfo(iGranule).metadata_name = metadata_temp_filename;
                        oinfo(iOrbit).ginfo(iGranule).NASA_orbit_number = ncreadatt( oinfo(iOrbit).ginfo(iGranule).metadata_name,'/','orbit_number');

                        oinfo(iOrbit).ginfo(iGranule).start_time = scan_line_times(1);
                        oinfo(iOrbit).ginfo(iGranule).end_time = scan_line_times(end);

                        % Initially, only read the first granule here but
                        % this caused problems when the orbit was already
                        % found so will load metadata for all granules here
                        % and then remove the metadata for all but the
                        % first granule when we write the metadata to the
                        % output file.

                        oinfo(iOrbit).ginfo(iGranule).metadata_global_attrib = ncinfo(oinfo(iOrbit).ginfo(iGranule).metadata_name);

                        oinfo(iOrbit).ginfo(iGranule).scans_in_this_granule = num_scan_lines_in_granule;

                        % Make sure that mirror side changes from granule
                        % to granule. To do this, read the mirror sides for
                        % all scan lines in this and the previous granule.
                        % Then check that the mirror side on the last scan
                        % line in the previous granule is not the same as
                        % the mirror side for the first scan line in this
                        % granule.

                        % This is a diagnostic test, skip for AWS until I
                        % determine whether or not mside is in the AWS NASA
                        % granules
                        
                        already_flagged_310 = 0;
                        if amazon_s3_run == 0
                            
                            if iGranule ~= 1
                                mside_current = single(ncread( oinfo(iOrbit).ginfo(iGranule).data_name, '/scan_line_attributes/mside'));
                                mside_previous = single(ncread( oinfo(iOrbit).ginfo(iGranule-1).data_name, '/scan_line_attributes/mside'));

                                if mside_previous(end) == mside_current(1)
                                    [~, granuleName, ~] = fileparts(oinfo(iOrbit).ginfo(iGranule).data_name);
                                    dont_use_status = populate_problem_list( 310, ['Mirror side ' num2str(mside_current(1)) ' for the first scan line on granule ' num2str(iGranule) ' (' granuleName ') of orbit ' num2str(iOrbit) ' is the same as that of the last scan of the prevous granule. Will add 10 nan scan lines'], granule_start_time); % old status 151
                                    already_flagged_310 = 1;
                                end
                            elseif iOrbit > 1
                                mside_current = single(ncread( oinfo(iOrbit).ginfo(1).data_name, '/scan_line_attributes/mside'));
                                mside_previous = single(ncread( oinfo(iOrbit-1).ginfo(end).data_name, '/scan_line_attributes/mside'));

                                if mside_previous(end) == mside_current(1)
                                    dont_use_status = populate_problem_list( 315, ['Mirror side ' num2str(mside_current(1)) ' for the 1st scan line of the 1st granule ' num2str(iGranule) ' of orbit ' num2str(iOrbit) ' is the same as that of the last scan line of the last granule in the previous orbit.'], granule_start_time); % old status 152
                                    already_flagged_310 = 1;
                                end
                            end
                        end

                        if iGranule == 1
                            if ~skip_to_start_of_orbit
                                
                                % The flow gets here if this is the first granule in an orbit and the
                                % ascending nadir track crosses -79 S. This can happen if all of the
                                % other granules in the orbit are missing.
                                %
                                % Get the possible location of this granule in the orbit. If it starts in
                                % the 101 scanline overlap region, two possibilities will be returned. The
                                % earlier one of the two, smaller scanline, will be chosen; choosing the
                                % later of the two would mean that only the last few scanlines of the orbit
                                % would be used in the orbit, which should have already been done if nadir
                                % track of the previous granule crossed 79 S.

                                nnToUse = get_scanline_index;

                                if isempty(nnToUse)
                                    indices.current.osscan = [];
                                else
                                    % It should be a number ending in 6,
                                    % since the orbit starts from the
                                    % middle of a 10 group detector array.
                                    % The following will find the closest
                                    % value to a number ending in 6. Most
                                    % of the time it should be the same
                                    % number of when working with an orbit
                                    % that does not start with a granule
                                    % that crosses 79 S on the southward
                                    % portion of the orbit.

                                    indices.current.osscan = nnToUse(1) - rem(nnToUse(1)-1, 10) + 5;
                                end
                            else
                                indices.current.osscan = 1;
                            end
                        else
                            % Get the number of scan lines to skip and make sure that it is an
                            % acceptable value.

                            lines_to_skip = floor( (abs(scan_line_times(1) - oinfo(iOrbit).ginfo(iGranule-1).end_time) * secs_per_day - secs_per_scan_line + 0.05) / secs_per_scan_line);
                            [~, nn] = find(min(abs(lines_to_skip - possible_num_scan_lines_skip(3,:))) == abs(lines_to_skip - possible_num_scan_lines_skip(3,:)));

                            if (lines_to_skip - possible_num_scan_lines_skip(3,nn)) ~= 0

                                kk = strfind(oinfo(iOrbit).ginfo(iGranule).metadata_name, 'AQUA_MODIS_'); % Used in error statements below.

                                if lines_to_skip == 10

                                    % Should not get here but every once in a while
                                    % the first scan of the mirror is missing;
                                    % i.e., 10 scan lines are missing. If the
                                    % number of missing lines is thought to be 10,
                                    % then check to see if this is one of those
                                    % cases by calculating the separation of the
                                    % last nadir pixel on the previous granule and
                                    % the first nadir pixel for this granule. If
                                    % they are separated by between 9 and 11.5 kms,
                                    % then the scan of the mirror is missing, so
                                    % it's OK to add 10 nan scan lines at this
                                    % point.

                                    clon_1 = ncread(oinfo(iOrbit).ginfo(iGranule-1).metadata_name, '/scan_line_attributes/clon');
                                    clat_1 = ncread(oinfo(iOrbit).ginfo(iGranule-1).metadata_name, '/scan_line_attributes/clat');

                                    clon_2 = ncread(oinfo(iOrbit).ginfo(iGranule).metadata_name, '/scan_line_attributes/clon');
                                    clat_2 = ncread(oinfo(iOrbit).ginfo(iGranule).metadata_name, '/scan_line_attributes/clat');

                                    dd_1_2 = sqrt( ((clon_2(1)-clon_1(end)) * cosd(clat_1(end))).^2 + (clat_2(1)-clat_1(end)).^2) * 111;

                                    if dd_1_2 > 9 & dd_1_2 < 11.5 
                                        if already_flagged_310 == 0
                                            [~, granuleName, ~] = fileparts(oinfo(iOrbit).ginfo(iGranule).data_name);
                                            dont_use_status = populate_problem_list( 320, ['1st 1/2 mirror rotation missing for ' oinfo(iOrbit).ginfo(iGranule).metadata_name(kk+11:end-23) ...
                                                ' for granule #' num2str(iGranule) ' (' granuleName '). Skipping ' num2str(lines_to_skip) ' scan lines at lon ' num2str(clon_2(1)) ', lat ' num2str(clat_2(1))], granule_start_time); % old status 116
                                        end
                                    else
                                        dont_use_status = populate_problem_list( 325, ['Says to skip 10 lines for ' oinfo(iOrbit).ginfo(iGranule).metadata_name(kk+11:end-23) ...
                                            ', but the distance, ' num2str(lines_to_skip) ' km, isn''t right. Will not skip any lines.'], granule_start_time); % old status 117

                                        lines_to_skip = 0;
                                    end
                                else
                                    dont_use_status = populate_problem_list( 330, ['Number of lines to skip for ' oinfo(iOrbit).ginfo(iGranule).metadata_name(kk+11:end-23) ...
                                        ', ' num2str(lines_to_skip) ', is not an acceptable value. Forcing to ' num2str(possible_num_scan_lines_skip(3,nn)) '.'], granule_start_time); % old status 115

                                    lines_to_skip = possible_num_scan_lines_skip(3,nn);
                                end
                            end

                            indices.current.osscan = oinfo(iOrbit).ginfo(iGranule-1).oescan + 1 + lines_to_skip;
                        end

                        % If there was a problem determining if the ascending
                        % nadir track crosses latlim in this granule, skip the
                        % granule and go to the next one.

                        if ~isempty(indices.current.osscan)

                            % Get the location of this granule in the orbit and
                            % the start and end of orbit if not already known.

                            if isempty(start_line_index)
                                [indices] = get_osscan_etc_NO_sli(indices);

                                if isempty(oinfo(iOrbit).name)
                                    status = generate_output_filename('no_sli');
                                end

                                oinfo(iOrbit).ginfo(iGranule).osscan = indices.current.osscan;
                                oinfo(iOrbit).ginfo(iGranule).oescan = indices.current.oescan;

                                oinfo(iOrbit).ginfo(iGranule).gsscan = indices.current.gsscan;
                                oinfo(iOrbit).ginfo(iGranule).gescan = indices.current.gescan;
                            else
                                [indices] = get_osscan_etc_with_sli(indices);

                                if ~skip_to_start_of_orbit
                                    status = generate_output_filename('sli');

                                    oinfo(iOrbit).ginfo(iGranule).osscan = indices.current.osscan;
                                    oinfo(iOrbit).ginfo(iGranule).oescan = indices.current.oescan;

                                    oinfo(iOrbit).ginfo(iGranule).gsscan = indices.current.gsscan;
                                    oinfo(iOrbit).ginfo(iGranule).gescan = indices.current.gescan;

                                    if isfield(indices, 'pirate')
                                        if skip_to_start_of_orbit
                                            oinfo(iOrbit).ginfo = rmfield(oinfo(iOrbit).ginfo, {'pirate_osscan' 'pirate_oescan' 'pirate_gsscan' 'pirate_gescan' });
                                        else
                                            oinfo(iOrbit).ginfo(iGranule).pirate_osscan = indices.pirate.osscan;
                                            oinfo(iOrbit).ginfo(iGranule).pirate_oescan = indices.pirate.oescan;

                                            oinfo(iOrbit).ginfo(iGranule).pirate_gsscan = indices.pirate.gsscan;
                                            oinfo(iOrbit).ginfo(iGranule).pirate_gescan = indices.pirate.gescan;
                                        end
                                    end

                                    if isfield(indices, 'next')
                                        oinfo(iOrbit+1).ginfo(1).osscan = indices.next.osscan;
                                        oinfo(iOrbit+1).ginfo(1).oescan = indices.next.oescan;

                                        oinfo(iOrbit+1).ginfo(1).gsscan = indices.next.gsscan;
                                        oinfo(iOrbit+1).ginfo(1).gescan = indices.next.gescan;
                                    end
                                else
                                    status = generate_output_filename('sliFirst');

                                    if isfield(indices, 'next')
                                        oinfo(iOrbit).ginfo(iGranule).osscan = indices.next.osscan;
                                        oinfo(iOrbit).ginfo(iGranule).oescan = indices.next.oescan;

                                        oinfo(iOrbit).ginfo(iGranule).gsscan = indices.next.gsscan;
                                        oinfo(iOrbit).ginfo(iGranule).gescan = indices.next.gescan;
                                    else
                                        status = populate_problem_list( 965, 'Bummer no next indices. This really shouldn''t happen.');
                                    end
                                end
                            end

                            if status >= 900
                                return
                            end

                            return
                        else
                            [~, orbitName, ~] = fileparts(oinfo(iOrbit).name);
                            dont_use_status = populate_problem_list( 335, ['Problem determining if ascending track crosses ' num2str(latlim) ' in ' orbitName ' for [iOrbit, iGranule]=[' num2str(iOrbit) ', ' num2str(iGranule) '].'], granule_start_time); % old status 263

                            iGranule = iGranule - 1;
                        end % Has osscan been defined?
                    end % Is this a search for a 79 S crossing and was one found?
                end % Test for problems either with scan line times or finding a 79S crossing.
            end % Does a data file exist for this metadata file?
        end % Test for 2030 or 2040 scan lines in this granule.
    end % Does a metadata file exist for iGranuleList value?
end  % Loop over granules.

