
function[fhat,Ahat,chat,ss,icstar] = factorMDDM4(Y,k0,r)

[n, p] = size(Y);
S = zeros(p,p);                   
                                  
for k=1:k0                                    % k0:lags cumul. MDDM(pag 219)
    S = S + MDDM( Y(1:(n-k),:), Y((1+k):n,:) );       %cumulative MDDM(k0)
end

[eVec,eVal] = eig(S);                      %eigendec. cumulative MDDM(k0)
eVal = diag(eVal);
R = floor((p/4));
lambda = zeros(R,1);

for i=1:R
    lambda(i) = eVal(i+1)/eVal(i);         %lambda= ratios subsequent eigenVals
end


[~,argMin] =  min(lambda(1:R));                 % argmin of ratios 
   icstar = (argMin);   

% [~,argMin] =  min(lambda(2:R));                 % argmin of ratios 
%    icstar = (argMin+1);                      %for estimating size factor process                              
Ahat = eVec(:,(1:icstar));   


% Components
    fhat=Y*Ahat;
    
    chat=fhat*Ahat';
    %ic1 = argMin;
    ss = eVal;
    %icstar = (argMin+2);
end