function [ skip_this_granule, global_attrib, nscans, npixels, datetime_start, datetime_end, problem_list] = get_global_attrib( fi_granule, problem_list)
% get_global_attrib - read the global attributes from the metadata file - PCC 
%   

skip_this_granule = 0;

global_attrib = ncinfo(fi_granule);

if isempty(strcmp(global_attrib.Dimensions(1).Name, 'number_of_lines')) ~= 1
    nscans = global_attrib.Dimensions(1).Length;
    npixels = global_attrib.Dimensions(2).Length;
    
    % Get the start and end times for this granule. Make sure
    % that time_coverage_start exists in the attributes.
    
    found_attribute = 0;
    for iAtt=1:length(global_attrib)
        if strfind(global_attrib.Attributes(iAtt).Name, 'time_coverage_start')
            xx = global_attrib.Attributes(iAtt).Value;
            found_attribute = 1;
            datetime_start = datenum( str2num(xx(1:4)), str2num(xx(6:7)), ...
                str2num(xx(9:10)), str2num(xx(12:13)), str2num(xx(15:16)), str2num(xx(18:23)));
        end
        
        if strfind(global_attrib.Attributes(iAtt).Name, 'time_coverage_end')
            xx = global_attrib.Attributes(iAtt).Value;
            datetime_end = datenum( str2num(xx(1:4)), str2num(xx(6:7)), ...
                str2num(xx(9:10)), str2num(xx(12:13)), str2num(xx(15:16)), str2num(xx(18:23)));
        end
    end
    
    if found_attribute == 0
        
        % Get the time separating scans. Actually, this isn't quite
        % right since scans are done in groups of ten so the times
        % for the start of each of the 10 scan lines is the same
        % but, for the purposes of this script, we will assume that
        % the scans are sequential in time separated by the time
        % below.
        
        time_separating_scans = (datetime_end-datetime_start) * 24 * 60 * 60 / nscans;
        
        if ifilename == 1
            sscan = scan_line_in_file(orbit_global_attrib.scan_line_start(iOrbit));
            lscan = nscans - sscan + 1;
            
            % Get the start time for this orbit. This is the start
            % time of this granule plus the time to get to the
            % first scan line used for the orbit.
            
            GlobalAttributes = ncinfo(fi_granule);
            time_coverage_start = ncreadatt( fi_granule, '/', 'time_coverage_start');
            
            time_orbit_start = datetime_start + sscan * time_separating_scans;
            
        elseif ifilename == length(file_list)
            sscan = 1;
            lscan = scan_line_in_file(orbit_info.scan_line_end(iOrbit)) + 1;
        else
            sscan = 1;
            lscan = nscans;
        end        
    else
        fprintf('Whoa, didn''t find time_coverage_start in the attributes. This should never happen. Skipping this granule %s', fi_granule)
        skip_this_granule = 1;
        
        if isempty(problem_list(1).problem_code)
            iProblemFile = 1;
        else
            iProblemFile = length(problem_list.problem_code) + 1;
        end
        
        problem_list.fi_metadata{iProblemFile} = fi_granule;
        problem_list.problem_code(iProblemFile) = 2;
    end
else
    fprintf('Wrong dimension: %s. Skipping to this granule %s.\n', global_attrib.Dimensions(1).Name, fi_granule)
    skip_this_granule = 1;
    
    if isempty(problem_list(1).problem_code)
        iProblemFile = 1;
    else
        iProblemFile = length(problem_list.problem_code) + 1;
    end
    
    problem_list.fi_metadata{iProblemFile} = fi_granule;
    problem_list.problem_code(iProblemFile) = 2;    
end

end

