function [longitude, latitude, SST_in, qual_sst, flags_sst, sstref] = add_nan_scan_lines( longitude, latitude, SST_in, qual_sst, flags_sst, sstref, num_nan_scan_lines)
% add_nan_scan_lines - if no data for a granule, populate this section of the orbit with nans for the various fields - PCC
% 
% INPUT
%   longitude - the longitude array thus far.
%   latitude - the latitude array thus far.
%   SST_in - the SST_in array thus far.
%   qual_sst - the qual_sst array thus far.
%   flags_sst - the flags_sst array thus far.
%   sstref - the sstref array thus far.
%   num_nan_scan_lines - augment the above arrays with this number of nan scan lines.
%
% OUTPUT
%   longitude - the augmented longitude array.
%   latitude - the augmented latitude array.
%   SST_in - the augmented SST_in array.
%   qual_sst - the augmented qual_sst array.
%   flags_sst - the augmented flags_sst array.
%   sstref - the augmented sstref array.
%

longitude = [longitude, single(nan(1354,num_nan_scan_lines))];
latitude = [latitude, single(nan(1354,num_nan_scan_lines))];
SST_in = [SST_in, single(nan(1354,num_nan_scan_lines))];
sstref = [sstref, single(nan(1354,num_nan_scan_lines))];

qual_sst = [qual_sst, int8(nan(1354,num_nan_scan_lines))];
flags_sst = [flags_sst, int16(nan(1354,num_nan_scan_lines))];
end

