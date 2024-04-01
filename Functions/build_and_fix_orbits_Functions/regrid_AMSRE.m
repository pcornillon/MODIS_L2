function [ AMSR_E_lon, AMSR_E_lat, AMSR_E_SST, L2eqa_AMSR_E_SST, MODIS_SST_on_AMSR_E_grid] = ...
    regrid_AMSRE( L2eqaLon, L2eqaLat, L2eqa_MODIS_SST)

% regrid_AMSRE and MODIS to L3 and L2 coordinates corresponding to AMSR-E - PCC
%
% This function will first determine which AMSR-E orbit corresponds to the
% current MODIS orbit and read the AMSR-E lat, lon and SST. It will then
% average MODIS to a 10x10 km grid and regrid the MODIS data to the AMSR-E
% data between 65 S and 65N after which it will determine the longitudinal
% range of the two portions of the AMSR-E orbit between 65 S and 65 N and
% regrid both AMSR-E and MODIS to this grid.
%
% INPUT
%   AMSR_E_baseDir - location of the AMSR-E data.
%   L2eqaLon: longitude for the new 10x10 km grid averaged from all
%    latitudes falling in the the original grid,
%   L2eqaLat: latitude for the new 10x10 km grid, averaged as for Lon.
%   L2eqa_MODIS_SST: 1 km MODIS SST averaged to L2eqa grid.
%
% OUTPUT
%   AMSR_E_lon: AMSR-E longitudes read in from the AMSR-E orbit.
%   AMSR_E_lat: AMSR-E latitudes read in from the AMSR-E orbit.
%   AMSR_E_aat: AMSR-E SSTs read in from the AMSR-E orbit.
%   L2eqa_AMSR_E_SST: AMSR-E SST regridded to the L2eqa grid.
%   MODIS_SST_on_AMSR_E_grid: MODIS SST regridded to the AMSR-E grid.

global pixStartm pixEndm pixStartp pixEndp
global oinfo iOrbit iGranule iProblem problem_list
global AMSR_E_baseDir

MODIS_fi = oinfo(iOrbit).name;

% Get the AMSR-E data. Start by determining the correct AMSR-E orbit.

% The first AMSR-E orbit with data, orbit #416, starts at 01-Jun-2002
% 19:05:19 or Matlab time 731368.7953587963. The average time for one orbit
% is: 98.863071 minutes. Given the NASA orbit number of this MODIS orbit--
% oinfo.ginfo(end).NASA_orbit_number--we can guess at the name of the
% corresponding AMSR-E orbit and we can check that the start times of the
% AMSR-E and MODIS orbits are similar.
tic
% % % if ~isempty(MODIS_fi)
% % %     temp_time = ncread( MODIS_fi, 'DateTime');
% % %     matlab_time_MODIS_start = datenum([1970,1,1]) + double(temp_time)/86400;
% % %
% % %     kk = strfind( MODIS_fi, '_orbit_');
% % %     NASA_orbit_t = str2num(MODIS_fi(kk+7:kk+12));
% % %
% % %     [MODIS_yr, MODIS_mn, MODIS_day, MODIS_hr, MODIS_min, MODIS_sec] = datevec(matlab_time_MODIS_start);
% % % else
NASA_orbit_t = oinfo(iOrbit).orbit_number;

[MODIS_yr, MODIS_mn, MODIS_day, MODIS_hr, MODIS_min, MODIS_sec] = datevec(oinfo(iOrbit).start_time);
% % % end

% Build the AMSR-E orbit filename.

NASA_orbit = return_a_string( 6, NASA_orbit_t);

year_s = return_a_string( 4, MODIS_yr);
month_s = return_a_string( 2, MODIS_mn);
day_s = return_a_string( 2, MODIS_day);

AMSR_E_fi = [AMSR_E_baseDir year_s '/' year_s month_s day_s '-amsre-remss-l2p-l2b_v07_r' NASA_orbit(2:end) '.dat-v01.nc'];

if exist(AMSR_E_fi) == 2

    lat_lon_step_threshold = 190;

    fprintf('Pairing this MODIS orbit with %s\n', AMSR_E_fi)

    % Note that the AMSR_E data are transposed, i<==>j, in the following to be
    % compatible with MODIS data.

    AMSR_E_lat = ncread( AMSR_E_fi, 'lat')';
    AMSR_E_lon = ncread( AMSR_E_fi, 'lon')';
    AMSR_E_SST = ncread( AMSR_E_fi, 'sea_surface_temperature')' - 273.15;

    % The beginning and end of the orbit appears to be nan values. Get rid of them.

    nn = find(isnan(AMSR_E_lon(10,:)) == 0);
    AMSR_E_SST = AMSR_E_SST(:,nn);
    AMSR_E_lat = AMSR_E_lat(:,nn);
    AMSR_E_lon = AMSR_E_lon(:,nn);

    % First get rid of jumps in the first scan line, since these carry to
    % all subsequent scan lines.
    
    xx = AMSR_E_lon(:,1);
    diffrow = diff(xx);
    jpix = find( abs(diffrow) > lat_lon_step_threshold);

    if ~isempty(jpix)

        % Get the step where there is a large jump and set to 360 times the
        % sign of the step.

        for kPix=1:length(jpix)
            lonStep(kPix) = -sign(xx(jpix(kPix)+1) - xx(jpix(kPix))) * 360;
        end

        % If there is only one step set a second step at the end of the
        % scan line.

        if rem(length(jpix),2)
            jpix(length(jpix)+1) = length(xx);
        end

        % Now offset for each step.

        for ifix=1:2:length(jpix)
            locs2fix = [jpix(ifix)+1:jpix(ifix+1)];
            xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
        end

        % Finally shift the longitude values so that most are between -180
        % and 180.

        while mean(xx,'omitnan') < -180
            xx = xx + 360;
        end

        while mean(xx,'omitnan') > 180
            xx = xx - 360;
        end

        AMSR_E_lon(:,1) = xx;
    end

    % Get rid of big jumps in longitude for AMSR-E. Do this for each pixel
    % (column) location in the along-scan direction for the length of the
    % orbit. Start by getting the step in longitude in the along-track
    % direction at each pixel location. (Will use the same threshold for the
    % longitudinal step as used for MODIS.

    diffcol = diff(AMSR_E_lon, 1, 2);

    for iCol=1:size(AMSR_E_lon,1)
        xx = AMSR_E_lon(iCol,:);

        % Find large longitude jumps for this column

        [~, jpix] = find( abs(diffcol(iCol,:)) > lat_lon_step_threshold);

        if ~isempty(jpix)

            % Get the step where there is a large jump and set to 360 times the
            % sign of the step.

            for kPix=1:length(jpix)
                lonStep(kPix) = -sign(xx(jpix(kPix)+1) - xx(jpix(kPix))) * 360;
            end

            % If there is only one step set a second step at the end of the
            % orbit.

            if rem(length(jpix),2)
                jpix(length(jpix)+1) = length(xx);
            end

            % Now offset for each step.

            for ifix=1:2:length(jpix)
                locs2fix = [jpix(ifix)+1:jpix(ifix+1)];
                xx(locs2fix) = xx(locs2fix) + lonStep(ifix);
            end

            AMSR_E_lon(iCol,:) = xx;
        end
    end

    % Next make sure that the AMSR-E longitudes are similar to those of the
    % L2eqa grid. Will do this by histogramming the longitude values and
    % compariong histograms.

    histEdges = [-250:1:250];
    [hist_L2eqa, ~] = histcounts(L2eqaLon, histEdges);

    MinHistMeanDiff = 1000000;

    for LonShift=[-720:360:720];
        [hist_amsre, ~] = histcounts(AMSR_E_lon + LonShift, histEdges);
        histMeanDiff = abs(mean(hist_L2eqa - hist_amsre, 'omitnan'));

        if histMeanDiff < MinHistMeanDiff
            MinHistMeanDiff = histMeanDiff;
            bestLonShift = LonShift;
        end
    end
    
    if bestLonShift ~= 0
        fprintf('Shifting longitudes by %f degrees.\n', bestLonShift)

        AMSR_E_lon = AMSR_E_lon + bestLonShift;
    end

    %% Finally regrid AMSR-E to the L2eqa grid and L2eqa_MODIS_SST to the AMSR-E grid

    L2eqa_AMSR_E_SST = griddata( AMSR_E_lon, AMSR_E_lat, AMSR_E_SST, L2eqaLon, L2eqaLat, 'natural');

    xx = double(L2eqaLon);
    yy = double(L2eqaLat);
    ss = double(L2eqa_MODIS_SST);

    pp = find(isnan(xx) == 0);

    if (length(pp) == 0) | (isempty(find(isnan(ss) == 0)))
        fprintf('...All SST_In values in Section 2 or 4 are nan for orbit %s.\n', oinfo(iOrbit).name)

        status = populate_problem_list( 1002, ['All SST_In values in Section 2 or 4 are nan for orbit ' oinfo(iOrbit).name], '');
    else
        MODIS_SST_on_AMSR_E_grid = griddata( xx(pp), yy(pp), ss(pp), AMSR_E_lon, AMSR_E_lat,'natural');
    end

else
    % Here if no AMSR-E orbit

    fprintf('***** Could not find AMSR-E orbit %s corresponding to MODIS orbit %s\n', AMSR_E_fi, MODIS_fi)

    status = populate_problem_list( 305, ['***** Could not find AMSR-E orbit ' AMSR_E_fi ' corresponding to MODIS orbit ' MODIS_fi]);

    AMSR_E_SST = [];
    AMSR_E_lat = [];
    AMSR_E_lon = [];

    L2eqa_AMSR_E_SST = [];
    MODIS_SST_on_AMSR_E_grid = [];
end

