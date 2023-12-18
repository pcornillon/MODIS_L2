function [mm,dd] = doy2mmdd(year, ddd) 
% doy2mmdd - day of year to month, day -PCC

v = datevec(datenum( double(year), ones(size(year)), double(ddd))); 
mm = v(:,2); dd = v(:,3);
    