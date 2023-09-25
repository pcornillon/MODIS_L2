function toggle_images(Figures)
% toggle_images - toggles from one image to the next on the list on user clicks - PCC
%
% INPUT
%   Figures - a vector of image numbers over which to toggle.
%
% OUTPUT - none
%

image_in_sequence = 0;
while 1==1
    image_in_sequence = image_in_sequence + 1;
    figure(Figures(image_in_sequence))
    
    if Figures(image_in_sequence) == Figures(end)
        image_in_sequence = 0;
    end
    
    what_next = input('<cr> or q: ', 's');
    if strfind(what_next, 'q'),
        break
    end
end

end

