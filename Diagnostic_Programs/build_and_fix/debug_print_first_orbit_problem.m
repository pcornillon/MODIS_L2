function debug_print_fist_orbit_problem( granule_start_time, indices, nnToUse)
% 
% This script prints out variables used to diagnose problem finding the
% first good orbit.

global oinfo iOrbit iGranule
global scan_line_times start_line_index num_scan_lines_in_granule
global newGranuleList iGranuleList filenamePrefix filenameEnding numGranules

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


