function [mMDDM] = MDDM(mX, mY)  

% Computes the Martingale Difference Divergence Matrix (MDDM) between two
% vector time series X and Y, as defined in:
% Lee, C. E., & Shao, X. (2018). Martingale Difference Divergence Matrix and
% Its Application to Dimension Reduction for Stationary Multivariate Time Series.

 [cn, cp] = size(mX);
[~, cq] = size(mY);
mMDDM = zeros(cq,cq);
cYbar = mean(mY, 1);
mY = mY - ones(cn,1)*(cYbar);


if cp == 1
    for i=1:cn
        cXdist = abs(mX(i) - mX);
        mMDDM = mMDDM + mY(i,:) * (transpose(cXdist) * mY);
    end
    
else
    for i=1:cn
        
        cXdist = transpose(transpose(mX(i,:)) - transpose(mX));
        cXdist = cXdist.^2;
        cXdist = sqrt(sum(cXdist,2));
        mMDDM = mMDDM + transpose(mY(i,:)) * (transpose(cXdist) * mY);
    end
    
    
end
    mMDDM = -mMDDM/(cn^2);
    
end