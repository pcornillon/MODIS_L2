% Get the input data.

fi = '/Volumes/MODIS_L2_Modified/OBPG/SST/2003/10/AQUA_MODIS_orbit_007506_20031001T145017_L2_SST.nc4';
SSTtemp = ncread(fi, 'Regrid_to_L2eqa/L2eqa_MODIS_SST');

figure
clf 
imagesc(SSTtemp')
colorbar
caxis([16 32])
axis([111 190 701 1200])
colormap(jet)

% Find nans and make a new SST with -100 wherever there was an nan.

nn = find(isnan(SSTtemp)==1);

SST = SSTtemp;
SST(nn) = -3;

newSST = medfilt2(SST, [5 5]);
SST(nn) = newSST(nn);

clear SSTtemp
% Make a mask of all 'bad' pixels.

mask = zeros(size(SST));
mask(nn) = 1;

figure
clf 
imagesc(mask')

colorbar
axis([111 190 701 1200])
colormap(jet)

cloud_objects = bwconncomp( mask);
object_Labels = labelmatrix(cloud_objects);

properties = regionprops( object_Labels, 'Area', 'PixelIdxList');

iSave = 0;
for iObject=1:length(properties)
    if properties(iObject).Area < 10
        iSave = iSave + 1;
        objectID(iSave) = iObject;
    end
end
whos objectID

% Check that this object is really less than 10 pixels. For 371, it should
% be 1 pixel at 183637. Also check that it is really just 1 pixel

properties(371)

[iIndex, jIndex] = ind2sub( size(mask), 183637);

mask(iIndex-1:iIndex+1, jIndex-1:jIndex+1)

% Now make a new mask with only objects that are less than the given
% threshold. 

threshold = 10;

newmask = zeros(size(mask));
for iObject=1:iSave
    xx = properties(objectID(iObject)).PixelIdxList;
    for i=1:length(xx)
        newmask(xx(i)) = 1;
    end
end

newmasklogical = logical(newmask);

% Plot the new mask.

figure
clf 
imagesc(newmask')

colorbar
axis([111 190 701 1200])
colormap(jet)

% Inpaint

tic
fixedSST = inpaintExemplar( SST, logical(newmask)); 
toc

nn = find(fixedSST<=-2);
fixedSST(nn) = nan;
% And plot

figure
clf 
imagesc(fixedSST')

colorbar
caxis([16 32])
axis([111 190 701 1200])
colormap(jet)

