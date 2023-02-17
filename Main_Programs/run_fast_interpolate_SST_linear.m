function run_fast_interpolate_SST_linear(weights_range, start_time_to_process, end_time_to_process)
% run_fast_interpolate_SST_linear - just what it says - PCC
%
% INPUT
%   weights_range - the weights to use in this analysis. There are 66
%    weights to use for the fast processing. They start at 3,501 and end at
%    33,001. These numbers are the scan lines of the 11 line sections used
%    in the reconstruction. There are missing scan lines so be careful.
%    weights_range would be something like [1:18] to do the first 18
%    weights.
%   start_time_to_process - [year, month, day, hour, minute, second] for
%    the starting range of times to search for the start of full orbits.
%   end_time_to_process - [year, month, day, hour, minute, second] for
%    the starting range of times to search for the start of full orbits.
%
% OUTPUT
%   none
%
% EXAMPLE
%   run_fast_interpolate_SST_linear([17:32], [2010, 10, 31, 20, 0, 0], [2010, 11, 2, 10, 0, 0])
%    To process the orbits with starting times between 20:00:00 31 Oct 2010
%    and 10:00:00 2 Nov 2010.

% type_of_weights = 'merged';
type_of_weights = 'individual';

check_results = 1;
PrintPlot = 1;

TitleFontSize = 12;
AxisFontSize = 10;

% Convert input times to Matlab time

start_matlab_time = datenum(start_time_to_process);
end_matlab_time = datenum(end_time_to_process);

fprintf('\n\nWill process orbits with starting times between %s and %s \n', datestr(start_matlab_time), datestr(end_matlab_time))

% % % weights_range = input('Enter the indices for the range of weights to use as [start_index:end_index]: ');

% % % orbit_name = 'AQUA_MODIS.20100619T051522';

plot_stuff = 1;
do_debug_plots = 0;

% % % region_to_process = 3;
% % % first_weights = 1;

%% Loop over years/months in which their are orbits to process.

for iYear=start_time_to_process(1):end_time_to_process(1)
    
    % Zero out arrays to be used and clear first image.
    
    clear mean_graddiff_griddata* sigma_graddiff_griddata*
    if plot_stuff
        hfig(1) = figure(1);
        clf
        hfig(1).Visible = 'off';
    end
    
    year_s = num2str(iYear);
    
    if iYear > start_time_to_process(1)
        month_start = 1;
    else
        month_start = start_time_to_process(2);
    end
    
    if iYear == end_time_to_process(1)
        month_end = end_time_to_process(2);
    else
        month_end = 12;
    end
    
    for iMonth=month_start:month_end
        
        month_s = num2str(iMonth);
        if iMonth < 10
            month_s = ['0' month_s];
        end
        
        orbit_list = dir(['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/' year_s '/' month_s '/AQUA_MODI*']);
        
        % Loop over orbits for this month
        
        for iOrbit=1:length(orbit_list)
            
            % Set or reset the flag to read in the orbit data for this orbit.
            
            first_good_subplot = 1;
            
            tt = orbit_list(iOrbit).name;
            nn = strfind(tt, '.L2.SST');
            orbit_name = tt(1:nn-1);
            
            nn = strfind(orbit_name, '.');
            orbit_year = str2num(orbit_name(nn+1:nn+4));
            orbit_month = str2num(orbit_name(nn+5:nn+6));
            orbit_day = str2num(orbit_name(nn+7:nn+8));
            orbit_hour = str2num(orbit_name(nn+10:nn+11));
            orbit_min = str2num(orbit_name(nn+12:nn+13));
            orbit_sec = str2num(orbit_name(nn+14:nn+15));
            
            orbit_matlab_time = datenum( orbit_year, orbit_month, orbit_day, orbit_hour, orbit_min, orbit_sec);
            
            if (orbit_matlab_time >= start_matlab_time) & (orbit_matlab_time <= end_matlab_time)
                
                % Generate the gradient fields for the input SST fielf for
                % this orbit and for the SST field generated with griddata
                % and save these fields along with the input SST field
                % masked with the quality field.
                
                fileout_base = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights_test/' orbit_name '_base.mat'];
                
                if exist(fileout_base) ~= 2 & check_results
                    fi_orbit = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SST/' year_s '/' month_s '/' orbit_name '.L2.SST.nc4'];
                    
                    [lon_orbit, lat_orbit, qual, sst_in_good, region_start, region_end, dist_at, dist_as, ...
                        g_in_m, g_griddata_m] = generate_base_info_for_orbit( fi_orbit, fileout_base);
                else
                    load(fileout_base)
                end
                
                plot_counter = 1;
                subplot_counter = 1;
                
                % Get the list of fast weights and loop over them, skipping the ones that
                % seem to have a problem.
                
                weights_filelist = dir('/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weight*');
                
                switch type_of_weights
                    
                    case 'individual'
                        % for weight_to_use = [21501 31001]
                        %     weight_to_use_string = num2str(weight_to_use);
                        
                        %                 weights_to_exclude = [1 32];
                        weights_to_exclude = [];
                        for iWeight=weights_range
                            
                            if sum(weights_to_exclude == iWeight) == 0
                                
                                Name = weights_filelist(iWeight).name;
                                nn_ = strfind(Name, '_');
                                nn_period = strfind(Name, '.');
                                weight_to_use_string = Name(nn_+1:nn_period-1);
                                weight_to_use(iWeight) = str2num(weight_to_use_string);
                                                                
                                % Get the output name and skip processing if the file has already been created.
                                
                                fileout = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights_test/' orbit_name '_' weight_to_use_string '.mat'];
                                if exist(fileout) == 2
                                    
                                    % Get data previously saved if you want to check results.
                                    
                                    if check_results
                                        load(fileout)
                                    end
                                else
                                    
                                    fi_weights = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/Orbit_Weights_and_Locations_' weight_to_use_string '.mat'];
                                    if exist(fi_weights) == 0
                                        base_scan_line = weight_to_use_string;
                                        Build_weight_and_location_arrays
                                    else
                                        load(fi_weights)
                                    end
                                    
                                    fprintf('\nWorking on %s. Using weights from lines %i \n', fi_orbit, weight_to_use(iWeight))
                                    
                                    if exist('fileout')==2
                                        load(fileout)
                                    else
                                        sst_fast_interp = fast_interpolate_SST_linear( augmented_weights, augmented_locations, sst_in_good);
                                    end
                                    
                                    %% Check the results
                                    
                                    if check_results
                                        
                                        if exist('fileout')==2
                                            load(fileout)
                                        else
                                            sst_fast_interp = fast_interpolate_SST_linear( augmented_weights, augmented_locations, sst_in_good);
                                        end
                                        
                                        % SST Fast Interpolate Regridded
                                        
                                        [g_fast_x, g_fast_y, g_fast_m] = sobel_gradient_degrees_per_kilometer( sst_fast_interp, dist_at(:,1:size(sst_fast_interp,2)), dist_as(:,1:size(sst_fast_interp,2)));
                                        
                                        % Save fast interpolated results.
                                        
                                        save(fileout, 'sst_fast_interp', 'g_fast_*')
                                    end
                                end
                                
                                % Plot if requested.
                                
                                if plot_stuff
                                    
                                    subplot_counter = subplot_counter + 1;
                                    if subplot_counter == 17
                                        if PrintPlot
                                            FigOutName_print = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Figures/' orbit_name '_' ...
                                                num2str(plot_counter) '_Histograms.jpeg'];
                                            print(FigOutName_print, '-djpeg')
                                        end
                                        
                                        plot_counter = plot_counter + 1;
                                        subplot_counter = 1;
                                        
                                        hfig(plot_counter) = figure(plot_counter);
                                        clf
                                        hfig(plot_counter).Visible = 'off';
                                    end
                                    
                                    g_fast_m_good = g_fast_m;
                                    g_fast_m_good(qual>2) = nan;
                                    
                                    [Values_fast, BinEdges_fast] = histcounts(g_fast_m_good, [0:0.001:0.7]);
                                    
                                    g_griddata_m_good = g_griddata_m;
                                    g_griddata_m_good(qual>2) = nan;
                                    
                                    [Values_griddata, BinEdges_griddata] = histcounts(g_griddata_m_good, [0:0.001:0.7]);
                                    bin_centers = BinEdges_griddata(1:end-1) + diff(BinEdges_griddata) / 2;
                                    
                                    hist_diff_griddata_minus_fast = Values_griddata - Values_fast;
                                    
                                    subplot(4,4,subplot_counter)
                                    
                                    plot(bin_centers, hist_diff_griddata_minus_fast)
                                    title(['griddata - fast: ' weight_to_use_string], fontsize=TitleFontSize)
                                    set(gca, fontsize=AxisFontSize)
                                    grid on
                                    hold on
                                    plot([0 0.7], [0 0], 'm', linewidth=3)
                                    
                                    g_in_m_good = g_in_m;
                                    g_in_m_good(qual>2) = nan;
                                    
                                    % Now get the mean and std of the difference between the
                                    % various gradient magnitude fields.
                                    
                                    if size(g_griddata_m_good,2) ~= size(g_fast_m_good,2)
                                        if size(g_griddata_m_good,2) > size(g_fast_m_good,2)
                                            graddiff_griddata_fast = g_griddata_m_good(:,1:size(g_fast_m_good,2)) - g_fast_m_good;
                                        else
                                            graddiff_griddata_fast = g_griddata_m_good - g_fast_m_good(:,1:size(g_griddata_m_good,2));
                                        end
                                    else
                                        graddiff_griddata_fast = g_griddata_m_good - g_fast_m_good;
                                    end
                                    mean_graddiff_griddata_fast(iWeight) = mean(graddiff_griddata_fast, 'all', 'omitnan');
                                    sigma_graddiff_griddata_fast(iWeight) = std(graddiff_griddata_fast, 0, 'all', 'omitnan');
                                    fprintf('mean(griddata-fast): %f, sigma(griddata-fast): %f\n ', mean_graddiff_griddata_fast(iWeight), sigma_graddiff_griddata_fast(iWeight))
                                    
                                    if first_good_subplot
                                        first_good_subplot = 0;
                                        
                                        if size(g_griddata_m_good,2) ~= size(g_in_m_good,2)
                                            if size(g_griddata_m_good,2) > size(g_in_m_good,2)
                                                graddiff_griddata_in = g_griddata_m_good(:,1:size(g_in_m_good,2)) - g_in_m_good;
                                            else
                                                graddiff_griddata_in = g_griddata_m_good - g_in_m_good(:,1:size(g_griddata_m_good,2));
                                            end
                                        else
                                            graddiff_griddata_in = g_griddata_m_good - g_in_m_good;
                                        end
                                        % % %                                 graddiff_griddata_in = g_griddata_m_good - g_in_m_good;
                                        mean_graddiff_griddata_in(iWeight) = mean(graddiff_griddata_in, 'all', 'omitnan');
                                        sigma_graddiff_griddata_in(iWeight) = std(graddiff_griddata_in, 0, 'all', 'omitnan');
                                        fprintf('mean(griddata-in): %f, sigma(griddata-in): %f\n ', mean_graddiff_griddata_in(iWeight), sigma_graddiff_griddata_in(iWeight))
                                    end
                                end
                            end
                        end
                end
                if plot_stuff
                    
                    % And save the stats, which haven't been saved yet.
                    
                    fileout_stats = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights_test/' orbit_name ...
                        '_stats_' num2str(weights_range(1)) '_to_' num2str(weights_range(end)) '.mat'];
                    save( fileout_stats, 'mean_graddiff*', 'sigma_graddiff*');
                    
                    figure(501)
                    clf
                    
                    mean_graddiff_griddata_fast_t = mean_graddiff_griddata_fast;
                    mean_graddiff_griddata_fast_t(weight_to_use==0) = nan;
                    
                    plot(weight_to_use, mean_graddiff_griddata_fast_t)
                    
                    grid on
                    set(gca, fontsize=AxisFontSize)
                    xlabel('Scan number')
                    ylabel('Mean of grad(griddata) - grad(fast)')
                    
                    
                    if PrintPlot
                        FigOutName_print = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Figures/' orbit_name '_' ...
                            num2str(weights_range(1)) '_to_' num2str(weights_range(end)) '_Mean.jpeg'];
                        print(FigOutName_print, '-djpeg')
                    end
                    
                    figure(502)
                    clf
                    
                    sigma_graddiff_griddata_fast_t = sigma_graddiff_griddata_fast;
                    sigma_graddiff_griddata_fast_t(weight_to_use==0) = nan;
                    
                    plot(weight_to_use, sigma_graddiff_griddata_fast_t);
                    
                    grid on
                    set(gca, fontsize=AxisFontSize)
                    xlabel('Scan number')
                    ylabel('Sigma of grad(griddata) - grad(fast)')
                    
                    if PrintPlot
                        FigOutName_print = ['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Figures/' orbit_name '_' ...
                            num2str(weights_range(1)) '_to_' num2str(weights_range(end)) '_Sigma.jpeg'];
                        print(FigOutName_print, '-djpeg')
                    end
                end
            end
        end
    end
end
