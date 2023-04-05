function status = generate_output_filename(build_type)
% generate_output_filename - build the output filename for MODIS_L2 orbits - PCC
%
% This function will build the output filename for either the current orbit
% or the next orbit based on the value of build_type. If 'no_sli', then
% it assumes that this granule is the first granule found in an orbit that
% does not contain latlim, the designated start of the orbit. If sli,
% start_line_index, does have a value, then the orbit the granule does
% contain the start of an orbit BUT, all of the granules in the previous
% part of orbit were missing so the name for this orbit is constructed and
% put in oinfo(iOrbit) and the name for the next orbit is constructed and
% put in oinfo(iOrbit+1).
%
% If 'sli' is passed in, then the name for the next orbit is constructed
% and put in oinfo(iOrbit+1).
%
% INPUT
%   build_type - 'no_sli' if an orbit name does not exist for the current
%    orbit; i.e., the granule comes following a missing granule at the end
%    of the previous orbit. 'sli', will build the output filename for the
%    next orbit.
%
% OUTPUT
%   status - if two ways of calculating the end of orbit time for a granule
%    that is at the end of an orbit but the first granule on the current
%    orbit.
%

global granules_directory metadata_directory fixit_directory logs_directory output_file_directory
global oinfo iOrbit iGranule iProblem problem_list
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t sltimes_avg nlat_avg
global Matlab_start_time Matlab_end_time
global secs_per_day secs_per_orbit secs_per_scan_line orbit_length time_of_NASA_orbit_change
global latlim
global print_diagnostics save_just_the_facts debug
global formatOut

status = 0;

switch build_type
        
    case 'no_sli'
        % Here if new orbit with missing granule at start of orbit.
        
        % Get the possible location of this granule in the orbit. If it starts in
        % the 101 scanline overlap region, two possibilities will be returned. We
        % will choose the earlier, smaller scanline, of the two; choosing the later
        % of the two would mean that we would only use the last few scanlines in
        % the orbit, which should have already been done if nadir track of the
        % previous granule crossed 78 S.
        
        target_lat_1 = nlat_t(5);
        target_lat_2 = nlat_t(11);
        
        nnToUse = get_scanline_index( target_lat_1, target_lat_2);
        
        oinfo(iOrbit).start_time = scan_line_times(1) - sltimes_avg(nnToUse(1)) / secs_per_day;
        oinfo(iOrbit).end_time = oinfo(iOrbit).start_time + secs_per_orbit / secs_per_day;
        
        if sltimes_avg(nnToUse(1)) > time_of_NASA_orbit_change
             oinfo(iOrbit).orbit_number = oinfo(iOrbit).ginfo(iGranule).NASA_orbit_number;
        else
             oinfo(iOrbit).orbit_number = oinfo(iOrbit).ginfo(iGranule).NASA_orbit_number - 1;
        end
        
        orbit_file_name = ['AQUA_MODIS_orbit_' return_a_string(oinfo(iOrbit).orbit_number) ...
            '_' datestr(oinfo(iOrbit).start_time, formatOut.yyyymmddThhmmss) '_L2_SST'];
        
        oinfo(iOrbit).name = [output_file_directory datestr(oinfo(iOrbit).start_time, formatOut.yyyy) '/' ...
            datestr(oinfo(iOrbit).start_time, formatOut.mm) '/' orbit_file_name '.nc4'];
        
        % If this granule also contains the start of an orbit all of the
        % reamining granules in the orbit are missing. 
        
        if ~isempty(start_line_index)
            
            % Calculate end_time aother way and check.
            
            temp_end_time_2 = scan_line_times(start_line_index) - secs_per_scan_line;
            
            if abs(temp_end_time_2 - oinfo(iOrbit).end_time) > 10 * secs_per_scan_line
                fprintf('Calculated orbit end times differ by %f s. Choosing time based on start_line_index.\n', temp_end_time_2 - oinfo(iOrbit).end_time)
                
                oinfo(iOrbit).end_time = temp_end_time_2;
                
                status = populate_problem_list( 131, oinfo(iOrbit).name);
            end
            
            oinfo(iOrbit+1).start_time = scan_line_times(start_line_index);
            oinfo(iOrbit+1).end_time = oinfo(iOrbit+1).start_time + secs_per_orbit / secs_per_day;
            
            oinfo(iOrbit+1).orbit_number = oinfo(iOrbit+1).ginfo(1).NASA_orbit_number;
            
            orbit_file_name = ['AQUA_MODIS_orbit_' return_a_string(oinfo(iOrbit+1).orbit_number) ...
                '_' datestr(oinfo(iOrbit).start_time, formatOut.yyyymmddThhmmss) '_L2_SST'];
            
            oinfo(iOrbit+1).name = [output_file_directory datestr(oinfo(iOrbit+1).start_time, formatOut.yyyy) '/' ...
                datestr(oinfo(iOrbit+1).start_time, formatOut.mm) '/' orbit_file_name '.nc4'];            

            % And the metadata for this granule at the start of the next orbit.
            
            oinfo(iOrbit+1).ginfo(1).data_name = oinfo(iOrbit).ginfo(end).data_name;
            oinfo(iOrbit+1).ginfo(1).metadata_name = oinfo(iOrbit).ginfo(end).metadata_name;
            oinfo(iOrbit+1).ginfo(1).metadata_global_attrib = oinfo(iOrbit).ginfo(end).metadata_global_attrib;
            oinfo(iOrbit+1).ginfo(1).NASA_orbit_number = oinfo(iOrbit).ginfo(end).NASA_orbit_number;
            
            oinfo(iOrbit+1).ginfo(1).start_time = oinfo(iOrbit).ginfo(end).start_time;
            oinfo(iOrbit+1).ginfo(1).end_time = oinfo(iOrbit).ginfo(end).end_time;
        end
            
    case 'sli'
        % Here for granule found at the start of an orbit.
    
        oinfo(iOrbit+1).start_time = scan_line_times(start_line_index);
        oinfo(iOrbit+1).end_time = oinfo(iOrbit+1).start_time + secs_per_orbit / secs_per_day;
        oinfo(iOrbit+1).orbit_number = oinfo(iOrbit).ginfo(end).NASA_orbit_number;
        
        orbit_file_name = ['AQUA_MODIS_orbit_' return_a_string(oinfo(iOrbit+1).orbit_number) ...
            '_' datestr(oinfo(iOrbit+1).start_time, formatOut.yyyymmddThhmmss) '_L2_SST'];
        
        oinfo(iOrbit+1).name = [output_file_directory datestr(oinfo(iOrbit+1).start_time, formatOut.yyyy) '/' ...
            datestr(oinfo(iOrbit+1).start_time, formatOut.mm) '/' orbit_file_name '.nc4'];
        
        % And the metadata for this granule at the start of the next orbit.
        
        oinfo(iOrbit+1).ginfo(1).data_name = oinfo(iOrbit).ginfo(end).data_name;
        oinfo(iOrbit+1).ginfo(1).metadata_name = oinfo(iOrbit).ginfo(end).metadata_name;
        oinfo(iOrbit+1).ginfo(1).metadata_global_attrib = oinfo(iOrbit).ginfo(end).metadata_global_attrib;
        oinfo(iOrbit+1).ginfo(1).NASA_orbit_number = oinfo(iOrbit).ginfo(end).NASA_orbit_number;
        
        oinfo(iOrbit+1).ginfo(1).start_time = oinfo(iOrbit).ginfo(end).start_time;
        oinfo(iOrbit+1).ginfo(1).end_time = oinfo(iOrbit).ginfo(end).end_time;
        
    otherwise
        fprintf('build_type passed in as %s, must be either ''sli'', or ''no_sli''.\n', build_type)
        
        status = populate_problem_list( 231, oinfo(iOrbit).name);
end

