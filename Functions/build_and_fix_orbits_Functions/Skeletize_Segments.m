function Segments = Skeletize_Segments( iObject, Array_In, MinBranchLength)

Debug_1 = 0;
Debug_2 = Debug_1;
Debug_3 = Debug_1;
Debug_4 = Debug_1;

% % % load '~/Dropbox/ComputerPrograms/Satellite_Model_SST_Processing/AI-SST/Data/Debug_Abbreviated.mat'
% % % global AxisFontSize TitleFontSize Trailer_Info
% % % AxisFontSize = 20;
% % % TitleFontSize = 30;
% % % Trailer_Info = '_Original';
% % % global Thresholds
% % % Thresholds.segment_length = 3;

Segments(1).Pixels = [];

global Thresholds

% If Segments has been passed in get its length; we will increment it.

% % % if exist('Segments')
% % %     iSegment = length(Segments);
% % % else
% % %     iSegment = 0;
% % % end

if ~exist('MinBranchLength')
    MinBranchLength = 0;
end

% Get the skeleton array

% % % tic
% initial_skel = bwskel(logical(Array_In),'MinBranchLength', MinBranchLength);
initial_skel = bwmorph(logical(Array_In),'skel', Inf);
% % % disp(['Object: ' num2str(iObject) ' - time: ' num2str(toc)])

% Get rid of spurs. Each skeketon pixel after applying bwskel will have at most
% 3 other skeleton pixels touching it. A spur is a skeleton pixel touching
% 1 other skeleton pixel, which touches at least 2 other pixels. The 'o'
% skeleton pixel below is a spur.
%
%   x
%    x
%     xo
%    x
%     x
%     x

% % %     skel_no_spur = bwmorph(initial_skel, 'spur');
skel_no_spur = initial_skel;
Array_In = single(skel_no_spur);

% process as long as there are still some points in Array_In. Points are
% removed as segments are found.

First = 1;

iSegment = 0;

last_nn = find(skel_no_spur==1);
while ~isempty(last_nn)
    
    % If this is the first pass through this object, iSegment = 0, skip the
    % next section. If not, the next section is used to remove new objects
    % that may have been produced in a previous pass through the object.
    % This occurs because the object may be broken up as portion of it are
    % removed. The objects introduced are often small and we want to remove 
    % if they do not meet the area treshold.
    
    if iSegment > 0
        
        CC = bwconncomp(logical(skel_no_spur));
        Object_Labels = labelmatrix(CC);
                
        % Remove objects consisting of less than 
        
        stats = regionprops( Object_Labels, 'Area');
        
        objects_found = 0;
        for iStats=1:length(stats)
            if stats(iStats).Area > Thresholds.segment_length
                objects_found = objects_found + 1;
            end
        end
        
        if objects_found == 0
            break
        end
    end
    
    % Get the pixel locations in the skeleton array.
    
    [iS, jS] = find(skel_no_spur == 1);
    
    if First == 1
        First = 0;
        iSsave = iS;
        jSsave = jS;
    end
    
    if length(iS)<=1  % Only one masked pixel at this point, exit.
        return
    end
    
    % Find branch points. A branch point is a skeleton pixel connected to 3
    % other skeleton pixels, each of which is connected to 2 pixels. The 'o'
    % skeleton pixel below is a branch point.  bwmorph returns an array of
    % the same size as the input array with all pixel values set to 0 except
    % for the branch points.
    %
    %   x   x
    %    oxx
    %    x
    %    x
    %     x
    %     x
    
    skel_branch_point_array = bwmorph( skel_no_spur, 'branchpoints');
    iB = [];
    jB = [];
    if ~isempty(find(skel_branch_point_array==1))
        [iB, jB] = find(skel_branch_point_array == 1);
    end
    
    % Finally get the end points of the skeleton. These are skeleton points
    % connected to only 1 other skeleton point. Note that there will be one
    % point at the end of each branch.
    
    skel_end_point_array = bwmorph( skel_no_spur, 'endpoints');
    [iE, jE] = find(skel_end_point_array == 1);
    Num_Ends = length(iE);
    
    if length(iE)<=1  % Only one masked pixel at this point; return.
        return
    end
    
    % % % % If no branch points, only one segment, save it and go to end of while.
    % % %
    % % % if length(iB) == 0
    % % %     Boundary = bwtraceboundary(skel_no_spur, [iE(1) jE(1)], 'W');
    % % %     Segments(iSeg).Pixels = Boundary(1:floor(length(Boundary/2)),:);
    % % %     return
    % % % end
    % % %
    % % % % Here if nore than one break point.
    
    iEB = [iE; iB];
    jEB = [jE; jB];
    Num_EB = length(iEB);
    
    if Debug_1
        clf
        tt = Plot_Masks( 1, 2, 1, Array_In, 'Array_In');
        pccpal=colormap;
        pccpal(1,:) = [0.5 0.5 0.5];
        pccpal(256,:) = [0 0 0];
        colormap(pccpal)
        
        hold on
        plot(iS, jS,'w.','markersize',10)
        plot(iB, jB, 'ko', 'markersize', 10,'markerfacecolor','r')
        plot(iE, jE, 'ko', 'markersize', 10, 'markerfacecolor','g')
        
        for i=1:Num_EB
            tt = text(iEB(i)-1, jEB(i)-1, num2str(i)); tt.Color = 'w';
        end
    end
        
    % Now start at one end point and get the boudaries, which for a line 1
    % pixel wide follows the line twice. Be careful on one side it will go down
    % one branch and on the other side it will go down the other branch when
    % the line splits.
    
    % Get all boundary points starting at this end point.
    
    Boundary = bwtraceboundary(skel_no_spur, [iE(1) jE(1)], 'W');
    
    % Loop over end points and branch points.
    
    clear Num_Found Loc_on_Boundary_Temp End_Branch_Pt_Num_Temp
    
    iPtsOnBoundary = 0;
    for iBdPt=1:Num_EB
        
        % If this is a break point or an end point, end this segment and start
        % another one otherwise save this pixel location to the current segment.
        
        Boundary_Points_Temp = find( (iEB(iBdPt) == Boundary(:,1)) & (jEB(iBdPt) == Boundary(:,2)));
        
        Num_Found(iBdPt) = length(Boundary_Points_Temp);
        
        for i=1:Num_Found(iBdPt)
            iPtsOnBoundary = iPtsOnBoundary + 1;
% % %             Loc_in_Mask_Temp(iPtsOnBoundary,:) = [iEB(iBdPt) jEB(iBdPt)];
            Loc_on_Boundary_Temp(iPtsOnBoundary,:) = Boundary_Points_Temp(i);
            End_Branch_Pt_Num_Temp(iPtsOnBoundary,:) = iBdPt;
        end
    end
    
    % Reorder boundary points.
    
    [Loc_on_Boundary, iLocSorted] = sort(Loc_on_Boundary_Temp);
% % %     Loc_in_Mask = Loc_in_Mask_Temp(iLocSorted,:);
    End_Branch_Pt_Num = End_Branch_Pt_Num_Temp(iLocSorted);
    
    if Debug_2
        disp(1:length(Num_Found))
        disp(Num_Found)
        Loc_on_Boundary'
        End_Branch_Pt_Num'
    end
    
    % Get segments
    
    clear pairs_processed
    
    for iEBPt=1:Num_EB
        pairs_processed(iEBPt).pairs = [0 0];
    end
    
    for iEBPt=2:length(Loc_on_Boundary)
        
        % Get the points between this end or branch point and the previous one.
        
        pts = Boundary(Loc_on_Boundary(iEBPt-1):Loc_on_Boundary(iEBPt),:);
        
        nPts = size(pts,1);
        
        if Debug_3
            figure(2)
            plot(pts(:,1), pts(:,2), 'linewidth',5)
        end
        
        % Save this pair in processed pairs structure to make sure we don't do
        % it again.
        
        first_pt = End_Branch_Pt_Num(iEBPt-1);
        last_pt     = End_Branch_Pt_Num(iEBPt);
        
        % Has this pair been processed already?
        
        [pairs_processed, found_pair] =  Check_This_Segment(first_pt, last_pt, pairs_processed);
                
        % Skip this one if this pair has already been processed.
        
        if found_pair == 0
            
            % Only work on this segment if it is long enough.
            
            nPts = length(pts);
            if nPts < Thresholds.segment_length
                skel_no_spur(pts(:,1), pts(:,2)) = 0;
            else
                
                % Get the list of end/branch points excluding the first and
                % last points on this segment and any others that are
                % within 2 pixels of the first or last ones.
                
                [new_iEB, new_jEB] = Remove_Elements_from_List( iEB, jEB, first_pt, last_pt);
                                
                iStart = 1;
                iEnd = nPts;
                last_pair_found = 0;
                
                for ipts=1:nPts-1
                    nn = find( (abs(pts(ipts,1)-new_iEB) < 2) & (abs(pts(ipts,2)-new_jEB) < 2) );
                    
                    found_EB = 0;
                    if ~isempty(nn)
                        
                        % Reset the last point for the segment to be
                        % processed to this point. 
                        
                        new_last_pt = find( (iEB == new_iEB(nn(1))) & (jEB == new_jEB(nn(1))));

                        % Has this segment already been processed?
                        
                        [pairs_processed, found_pair] =  Check_This_Segment(first_pt, new_last_pt, pairs_processed);
                        
                        if found_pair == 1
                            first_pt = new_last_pt;
                            iStart = ipts;
                            
                            % If the new segment has already been processed
                            % break out of for loop since this segment goes
                            % to the end of this set of points.
                            
                            [pairs_processed, found_pair] =  Check_This_Segment(first_pt, last_pt, pairs_processed);
                            
                            if found_pair
                                last_pair_found = 1;
                                break
                            end
                            
                            % Need to reset the list of end/break points to
                            % search for, excluding the one just found.
                            
                            [new_iEB, new_jEB] = Remove_Elements_from_List( iEB, jEB, first_pt, last_pt);
                        else
                            
                            % Save this segment.
                            
                            iEnd = ipts;
                            if (iEnd-iStart) > Thresholds.segment_length
                                iSegment = iSegment + 1;
                                Segments(iSegment).Pixels = pts(iStart:iEnd,:);
                                
                                if Debug_4
                                    Plot_Masks( 1, 3, 1, skel_no_spur);
                                    ANSWER = input(['Segement #: ' num2str(iSegment) '. k for keyboard, <cr> to continue: '],'s');
                                    
                                    if strfind( ANSWER, 'k'); keyboard; end
                                    if strfind( ANSWER, 'q'); return; end
                                end
                            end
                            
                            % Zero out these points on the skeleton array.
                                                        
                            skel_no_spur(pts(iStart:iEnd,:), pts(iStart:iEnd,:)) = 0;
                            
                            % Reset start point and end/branch point.
                            
                            iStart = iEnd + 1;
                                                       
                            first_pt = new_last_pt;
                            
                            [new_iEB, new_jEB] = Remove_Elements_from_List( iEB, jEB, first_pt, last_pt);
                        end
                    end
                end
                
                if last_pair_found == 0
                    
                    % Save this segment if it has not already saved.
                    
                    iEnd = ipts;
                    if (iEnd-iStart) >= Thresholds.segment_length
                        iSegment = iSegment + 1;
                        Segments(iSegment).Pixels = pts(iStart:iEnd,:);
                        
                        if Debug_4
                            Plot_Masks( 1, 3, 1, skel_no_spur);
                            ANSWER = input(['Segement #: ' num2str(iSegment) '. k for keyboard, <cr> to continue: '],'s');
                            
                            if strfind( ANSWER, 'k'); keyboard; end
                            if strfind( ANSWER, 'q'); return; end
                        end
                    end
                    
                    % Zero out these points on the skeleton array.
                    
                    skel_no_spur(pts(iStart:iEnd,:), pts(iStart:iEnd,:)) = 0;
                    
                    % Update the list of processed pairs.

                    [pairs_processed, found_pair] =  Check_This_Segment(first_pt, last_pt, pairs_processed);
                end
                
            end
        end
    end
end

end

%% Functions called.

function [pairs_processed, found_pair] = Check_This_Segment(first_pt, last_pt, pairs_processed)
% Check_This_Segment - check to see if this segment has been processed.
%
% Called from Skeletize_Segments
%
% INPUT
%   first_pt - the number of the first point on the segment in the list
%    of end and branch points.
%   last_pt - the number of the last (second) point on the segment in the
%    list of end and branch points.
%   pairs_processed - structure function of the pairs of points processed
%    to date.
%
% OUTPUT
%   pairs_processed - updated structure of the pairs of points processed
%    to date if these points have not been processed yet.
%   found_pair - 0 if this pair of point has not been processed yet, 1 if
%    it has.
%

new_pair = [first_pt last_pt];
new_pair_reversed = [last_pt first_pt];

% Has this pair already been processed? Concatenate the pairs found
% thus far from this point and the previous point to cover all bases.
% Probably could do just one of the end points but I kept finding
% special cases where that didn't work so doing both ends now.

pairs = [pairs_processed(last_pt).pairs; pairs_processed(first_pt).pairs];

found_pair = 0;
for iProcessed=1:size(pairs,1)
    if ( (pairs(iProcessed,1) == new_pair_reversed(1)) & (pairs(iProcessed,2) == new_pair_reversed(2)) ) | ...
            ( (pairs(iProcessed,1) == new_pair(1)) & (pairs(iProcessed,2) == new_pair(2)) )
% % %     if (pairs(iProcessed,:) == new_pair_reversed) | (pairs(iProcessed,:) == new_pair)
        found_pair = 1;
        break
    end
end

if found_pair == 0
% % %     pairs_processed(first_pt).pairs = [pairs_processed(first_pt).pairs; new_pair_reversed; new_pair];
% % %     pairs_processed(last_pt).pairs = [pairs_processed(last_pt).pairs; new_pair_reversed; new_pair];
    pairs_processed(first_pt).pairs = [pairs_processed(first_pt).pairs; new_pair];
    pairs_processed(last_pt).pairs = [pairs_processed(last_pt).pairs; new_pair];
end

end


function [new_iEB, new_jEB] = Remove_Elements_from_List( iEB, jEB, first_pt, last_pt, old_last_pt)
% Remove_Elements_from_List - generate a list of end and branch points
% excluding the endpoints passed in and all end/branch points within 2
% pixels of either end point.
%
% Called from Skeletize_Segments
%
% INPUT
%   iEB - values of the first dimension of the location of the end/branch
%    point corresponding to this element in the vector.
%   iEB - values of the second dimension of the location of the end/branch
%    point corresponding to this element in the vector.
%   first_pt - the number of the first point on the segment in the list
%    of end and branch points.
%   last_pt - the number of the last (second) point on the segment in the
%    list of end and branch points.
%
% OUTPUT
%   new_iEB - values of the first dimension of the location of all end/branch
%    points excluding the ones passed in and any others within 2 pixels of
%    the ones passed in.
%   new_iEB - values of the second dimension of the location of all end/branch
%    points excluding the ones passed in and any others within 2 pixels of
%    the ones passed in.
%
% Are there any end or branch points within one point of
% this line. Make a new list of end/branch points excluding
% the two just found.

index_vector = 1:length(iEB);

new_iEB = iEB(index_vector~=last_pt & index_vector~=first_pt);
new_jEB = jEB(index_vector~=last_pt & index_vector~=first_pt);

% Also remove any other end/branch points that are within
% one pixel of the two points at the end of this segment.
% This happens sometimes when there are two or more adjacent
% branch points.

nn = find( (abs(new_iEB-iEB(last_pt)) < 2) & (abs(new_jEB-jEB(last_pt)) < 2));
if isempty(nn) == 0
    for inn=1:length(nn)
        new_index_vector = [1:length(new_iEB)];
        new_iEB = new_iEB(new_index_vector~=nn(inn));
        new_jEB = new_jEB(new_index_vector~=nn(inn));
    end
end

nn = find( (abs(new_iEB-iEB(first_pt)) < 2) & (abs(new_jEB-jEB(first_pt)) < 2));
if isempty(nn) == 0
    for inn=1:length(nn)
        new_index_vector = [1:length(new_iEB)];
        new_iEB = new_iEB(new_index_vector~=nn(inn));
        new_jEB = new_jEB(new_index_vector~=nn(inn));
    end
end

% Finally, if a 3rd point was passed in, remove it from the list as well.

if exist('old_last_pt')
    nn = find( (abs(new_iEB-iEB(old_last_pt)) < 2) & (abs(new_jEB-jEB(old_last_pt)) < 2));
    if isempty(nn) == 0
        for inn=1:length(nn)
            new_index_vector = [1:length(new_iEB)];
            new_iEB = new_iEB(new_index_vector~=nn(inn));
            new_jEB = new_jEB(new_index_vector~=nn(inn));
        end
    end
end

end