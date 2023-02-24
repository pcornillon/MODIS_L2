function solar_elevation = get_solar_elevation( YearDay, Hour, Minute, Lat, Lon)
% get_solar_elevation - calculates the elevation of the sun above the horizon.
%
% Provided with date, GMT, latitude and longitude, this function calculates
% the angle in degrees of the Sun above the horizon. Not surprisingly,
% negative numbers mean that the Sun is, you guessed it, below the horizon.
%
% INPUT
%   YearDay - day of year from 1 to 366.
%   Hour - hour of day, GMT, NOT local sun time.
%   Minute - minute of the hour.
%   Lat - latitude for 10 W you can enter either -10 or 350.
%   Lon - longitude.
%
% OUTPUT
%   solar_elevation - just what it says, in degrees.
%
% EXAMPLE
%   YearDay = 182;
%   Hour = 15;
%   Minute = 0;
%   Lat = -70;
%   Lon = 30;
%   solar_elevation = get_solar_elevation( YearDay, Hour, Minute, Lat, Lon); fprintf('solar_elevation: %f\n', solar_elevation)
%
% Outputs: solar_elevation: -16.422127
%
% Same parameters input to the calculator at this site:
%   https://keisan.casio.com/exec/system/1224682277 yields: -16.40
%

RadiansPerDay = 2 * pi / 365.25;

Declination = asin( 0.398 * sin( RadiansPerDay * ( YearDay - 81.0 + 2.0 * ...
    sin(RadiansPerDay * (YearDay - 2.0) ) ) ) );

eqtm = 0.128 * sin(RadiansPerDay * (YearDay - 2.0) ) + ...
    0.164 * sin(2.0 * RadiansPerDay * (YearDay + 10.0) );

LonTime = Hour + single(Minute) / 60 - eqtm + Lon / 15.0;
AngleTime = pi * (LonTime - 12.0) / 12.0;
LatRad = Lat * pi / 180.0;

sla = sin(LatRad);
cla = cos(LatRad);
sde = sin(Declination);
cde = cos(Declination);
cah = cos(AngleTime);

solar_elevation = 90 - acos( sla .* sde + cla .* cde .* cah) * 180 / pi;
