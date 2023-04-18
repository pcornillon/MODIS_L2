% generate_weights_and_locations

% First, pull out the first 50 pixels of each scan line.

tic
left_lat = o1.latitude(1:51,:);
left_lon = o1.longitude(1:51,:);

left_regridded_lat = o1.regridded_latitude(1:51,:);
left_regridded_lon = o1.regridded_longitude(1:51,:);

vin = zeros(size(left_lat));
vin(1:5:end,1:5:end) = 1;

weights = nan(5,size(left_lat,1),size(left_lat,2));
locations = nan(5,size(left_lat,1),size(left_lat,2));
numVals = zeros(size(left_lat));

vout = griddata( left_lon, left_lat, vin, left_regridded_lon, left_regridded_lat);

[wt, wit] = sort(vout(:), 'desc');

nn = find((wt~=0) & (isnan(wt) == 0));

w = wt(nn);
wi = wit(nn);

[iPt, jPt] = ind2sub(size(vout), nn);
iGrid = (iPt + 2) - rem(iPt+1,5);
jGrid = (jPt + 2) - rem(jPt+1,5);

for k=1:length(nn)
    numVals(iGrid(k), jGrid(k)) = numVals(iGrid(k), jGrid(k)) + 1;
    if numVals(iGrid(k), jGrid(k)) <= 5
        weights(numVals(iGrid(k),jGrid(k)), iGrid(k), jGrid(k)) = w(k);
        locations(numVals(iGrid(k),jGrid(k)), iGrid(k), jGrid(k)) = wi(k);
    end
end

    
% % % for i=6:5:size(vin,1)-5
% % %     for j=6:5:size(vin,2)-5
% % %         
% % %         region = vout(i-2:i+2,j-2:j+2);
% % %         [w, wi] = sort(region(:), 'desc');
% % %         
% % %         nn = find(w~=0);
% % %         if ~isempty(nn)
% % %             if nn>5
% % %                 mm = nn;
% % %                 clear nn
% % %                 nn = mm(1:5);
% % %             end
% % %             
% % %             for k=nn
% % %                 weights(k,i,j) = w(k);
% % %                 locations(k,i,j) = wi(k);
% % %             end
% % %         end
% % %     end
% % % end

toc

