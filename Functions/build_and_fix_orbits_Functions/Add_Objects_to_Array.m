function Output_Array = Add_Objects_to_Array( Input_Array, Coordinates_Structure, Object_Number)
% Add_Objects_to_Matrix - Add an object defined with bwconncomp to an array - PCC
%
% Add objects found with the bwconncomp function applied to a logical arryay
%  to the specified array with the specified object numbers.
%
% INPUT
%   Input_Array - array to which the object is to be added.
%   Coordinates_Structure - cell array of the coordinatesof the object. 
%    Each element of the cell array is a vector if i, j pairs.
%   Object_Numbers - numbers to be assigned to the pixels of each object.
%    Th vector must have the same number of elemebts as the cell array of
%    coordinates.
%
% OUTPUT
%   Output_Array - input array augmented with new object.
%

siz = size(Input_Array);

Output_Array = Input_Array;

for iObject=1:length(Object_Number)
    kk = sub2ind( siz, Coordinates_Structure(iObject).Indices(:,2), Coordinates_Structure(iObject).Indices(:,1));
    Output_Array(kk) = Object_Number(iObject);
end

end

