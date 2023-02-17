function [array_out] = augment_arrays( direction, array_in, smooth_threshold, smooth_over)
% augment_arrays - pad arrays with appropriate values - PCC
%
% This function has been designed to cleanup separation arrays for individual
% orbits. It has been designed to be used with generate_separations_angles. 
% It does this using several thresholds an ageraged array--averaged over a 
% number of orbits--and a vector of thresholds. 
%
% Will add 5 elements in the along-scan (direction=1) or along-track
% (direction=0) directions to the beginning and end of each line. If a scan
% line, then extrapolate from the lat two values of the input array on both
% ends of the line. If a track line, then replicate the last value on each
% end.
%
% INPUT
%   direction - 1 for along-scan direction, 2 for along track direction
%   array_in - the input array to be augmented.
%   smooth_threshold - a 2 element vecotr. Element 1 is the threshold to
%    use when initially eliminating really bad points. Element 2 is the
%    threshold to use when eliminating points that are farther from this
%    value than the smoothed fit of the first pass. Only used if the first
%    value of the next variable is >0.
%   smooth_over - a 2 element vector. Element 1 is the number of pixels
%    over which to do the first smoothing. Element 2 is the number of
%    pixels over which to do the second smoothing. If the first value is 
%    less than zero the function will not smooth in augmented arrays.
%
% OUTPUT
%   array_out - the augmented array_in smoothed in smoothed_over is
%    greather than 0 and divided by 10--it assumes that the data in are
%    separations over 10 pixels in the specified direction.

tt = array_in;

if direction == 1
    ttt = tt(1,:) - tt(2,:);
    tt1 = tt(1,:) + ([5:-1:1]' * ttt);
    
    ttt = tt(end,:) - tt(end-1,:);
    tt2 = tt(end,:) + ([1:5]' * ttt);
    
    array_out_temp = single([tt1; tt; tt2]);
else
    array_out_temp = single([repmat(tt(:,1), 1, 5), tt, repmat(tt(:,end), 1, 5)]);
end

if smooth_over(1) > 0
    % Smooth these arrays to address problems introduced by separations being
    % between the two intersection points of the ray from the satellite to the
    % surface of Earth. If there are mountains this distance is different than
    % if it is the ocean surface.
    
    ass = array_out_temp;
    nn = find(abs(ass) > smooth_threshold(1));
    ass(nn) = nan;
    
    assp = smoothdata( ass, direction, 'gaussian', smooth_over(1));
    
    % Remove values more than a few hundred meters from the smoothed version
    % and smooth the new array. Note that the value saved is the
    % smoothed value divided by pixel_step since we were doing this for
    % steps of pixel_step pixels.
    
    nn = find(abs(assp - ass)>smooth_threshold(2));
    ass(nn) = nan;
    array_out = smoothdata( ass, direction, 'gaussian', smooth_over(2)) / 10;
else
    array_out = array_out_temp / 10;
end

end