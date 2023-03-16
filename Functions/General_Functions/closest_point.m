function [ Indices ] = closest_point( vector, point, threshold )
% Index_of_Closest_Point - find the points on a line to the given point - PCC
%
% This function will first search for ponts on vector within threshold of
% the given point. It may find more than one. It will then find the closest
% point(s) if there are two separated regions on the vector close to the
% given point.
%
% INPUT
%   vector - to search.
%   points - values to search for.
%   threshold - to use to narrow down the search.
%
% OUTPUT
%   indices - of the closest points.
%

nn = find(abs(vector - point) < threshold);

if length(nn) == 1
    Indices = nn;
else
    % Find regions. They must be separated by more than 2 points.
    
    diffnn = diff(nn);
    
    mm = find(diffnn > 2);
    
    % If only one region, return nn(1). else find the closest points in
    % each of the regions.
    
    if isempty(mm)
        Indices = nn(1);
    else
        kk = [1 nn(mm) length(vector)];
        for iK=1:length(mm)+1
            TempIndex = find(min(abs(vector(kk(iK):kk(iK+1))-point)) == abs(vector(kk(iK):kk(iK+1))-point)) + kk(iK) - 1;
            Indices(iK) = TempIndex(1);
        end
    end
end

