function debug_print_fist_orbit_problem( granule_start_time, scan_seconds_from_start, latitude, indices, nnToUse)
%
% This script prints out variables used to diagnose problem finding the
% first good orbit.

global oinfo iOrbit iGranule
global scan_line_times start_line_index num_scan_lines_in_granule nlat_t 
global granuleList iGranuleList filenamePrefix filenameEnding numGranules

if ~isempty(granule_start_time)
    if ~isempty(iGranuleList)
        fprintf('\niGranuleList: %i. granule_start_time: %s\n', iGranuleList, datestr(granule_start_time))
    else
        fprintf('\niGranuleList: []. granule_start_time: %s\n', datestr(granule_start_time))
    end
else
    if isempty(iGranuleList)
        fprintf('\niGranuleList: %i. No granule_start_time\n', iGranuleList)
    else
        fprintf('\nNo iGranuleList or granule_start_time.\n')
    end
end

fprintf('\niOrbit: %i. iGranule: %i\n', iOrbit, iGranule)

fprintf('oinfo(iOrbit).name: %s\n', oinfo(iOrbit).name)
fprintf('oinfo(iOrbit).start_time: %s\n', datestr(oinfo(iOrbit).start_time))
fprintf('oinfo(iOrbit).end_time: %s\n', datestr(oinfo(iOrbit).end_time))

if ~isempty(oinfo(iOrbit))
    if iGranule > 0
        oinfoFieldnames = fieldnames(oinfo(iOrbit).ginfo(iGranule));

        osscan_1_Index = oinfo(iOrbit).ginfo(iGranule).osscan;
        osscan_m1_Index = max(1,oinfo(iOrbit).ginfo(iGranule).osscan-1);

        delta_lat = (latitude(677,osscan_1_Index) - latitude(677,osscan_m1_Index)) * 111; 
        fprintf('\niGranule %i, granuleList(%i).first_scan_line_time: %s, granule_start_time(osscan) %s and delta_lat=%5.2f km \n\n', iGranule, iGranuleList, datestr(granuleList(iGranuleList).first_scan_line_time), datestr(double(scan_seconds_from_start(osscan_1_Index)/86400) + oinfo(iOrbit).start_time), delta_lat)

        % And plot the latitude with starting and ending scanlines for this
        % granule.

        hold off
        imagesc(latitude')
        hold on
        plot([1 1354], [1 1]*oinfo(iOrbit).ginfo(iGranule).osscan, 'g', linewidth=2)
        plot([1 1354], [1 1]*oinfo(iOrbit).ginfo(iGranule).oescan, 'r', linewidth=1)

        % Now print out osscan, oescan, gsscan and gescan if available.

        for iField=1:length(oinfoFieldnames)
            switch oinfoFieldnames{iField}

                case 'osscan'
                    fprintf('oinfo(iOrbit).ginfo(iGranule).osscan: %i\n', oinfo(iOrbit).ginfo(iGranule).osscan)

                case 'oescan'
                    fprintf('oinfo(iOrbit).ginfo(iGranule).osecan: %i\n', oinfo(iOrbit).ginfo(iGranule).oescan)

                case 'gsscan'
                    fprintf('oinfo(iOrbit).ginfo(iGranule).gsscan: %i\n', oinfo(iOrbit).ginfo(iGranule).gsscan)

                case 'gescan'
                    fprintf('oinfo(iOrbit).ginfo(iGranule).gescan: %i\n', oinfo(iOrbit).ginfo(iGranule).gescan)
                    fprintf('\n')

                otherwise

            end
        end
    end
end

% Now for additional variables.


if exist('nnToUse')
    fprintf('# elements in nnToUse: %i\n', length(nnToUse))
else
    fprintf('nnToUse not yet defined.\n')
end

if ~isempty(start_line_index)
    fprintf('start_line_index: %i\n', start_line_index)
else
    fprintf('start_line_index not yet defined.\n')
end

if exist('indices')
    if ~isempty(indices)
        indicesFieldnames = fieldnames(indices);

        for iField=1:length(indicesFieldnames)
            switch indicesFieldnames{iField}

                case 'current'
                    indicesCurrent = fieldnames(indices.current);
                    for jField=1:length(indicesCurrent)
                        switch indicesCurrent{jField}
                            case 'osscan'
                                fprintf('indices.current.osscan: %i\n', indices.current.osscan)

                            case 'oescan'
                                fprintf('indices.current.osecan: %i\n', indices.current.oescan)

                            case 'gsscan'
                                fprintf('indices.current.gsscan: %i\n', indices.current.gsscan)

                            case 'gescan'
                                fprintf('indices.current.gescan: %i\n', indices.current.gescan)
                        end
                    end
                    fprintf('\n')

                case 'next'
                    indicesNext = fieldnames(indices.next);
                    for jField=1:length(indicesNext)
                        switch indicesNext{jField}
                            case 'osscan'
                                fprintf('indices.next.osscan: %i\n', indices.next.osscan)

                            case 'oescan'
                                fprintf('indices.next.osecan: %i\n', indices.next.oescan)

                            case 'gsscan'
                                fprintf('indices.next.gsscan: %i\n', indices.next.gsscan)

                            case 'gescan'
                                fprintf('indices.next.gescan: %i\n', indices.next.gescan)
                        end
                    end
                    fprintf('\n')

                case 'pirate'
                    indicesPirate = fieldnames(indices.pirate);
                    for jField=1:length(indicesPirate)
                        switch indicesPirate{jField}
                            case 'osscan'
                                fprintf('indices.pirate.osscan: %i\n', indices.pirate.osscan)

                            case 'oescan'
                                fprintf('indices.pirate.osecan: %i\n', indices.pirate.oescan)

                            case 'gsscan'
                                fprintf('indices.pirate.gsscan: %i\n', indices.pirate.gsscan)

                            case 'gescan'
                                fprintf('indices.pirate.gescan: %i\n', indices.pirate.gescan)
                        end
                    end
                    fprintf('\n')

                otherwise
                    fprintf('\n')

            end
        end
    end
end


