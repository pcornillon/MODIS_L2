% stats_on_weights_and_locations

filelist = dir('~/Dropbox/Data/Support_data_for_MODIS_L2_Corrections_1/weights/*L2_SST.mat');

for iFile=1:length(filelist)
    fi = [filelist(iFile).folder '/' filelist(iFile).name];
    
    load(fi)
    
    if iFile==1
        weights_sum = weights(1:6,:,:);
        locations_sum = locations(1:6,:,:);

        weights_sumsq = weights(1:6,:,:).^2;
        locations_sumsq = locations(1:6,:,:).^2;
        
        num = zeros(size(weights(1:6,:,:)));
        num(weights_sum~=0 & isnan(weights_sum)==0) = 1;
    else
        weights_sum = weights_sum + weights(1:6,:,:);
        locations_sum = locations_sum + locations(1:6,:,:);
        
        weights_sumsq = weights_sumsq + weights(1:6,:,:).^2;
        locations_sumsq = locations_sumsq + locations(1:6,:,:).^2;
        
        nn = find(weights_sum~=0 & isnan(weights_sum)==0);
        num(nn) = num(nn) + 1;
    end
end

weights_mean = weights_sum ./ num;
weights_sigma = weights_sumsq ./ num - weights_mean.^2;
