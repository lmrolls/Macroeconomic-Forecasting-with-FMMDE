
function[fhat,Ahat,chat,ss,icstar] = factorLAM(Y,k0,r)


[n, p] = size(Y);
S = zeros(p,p);

for k=1:k0                                    % k0:lags cumul. MDDM(pag 219)
    %mat = (1/(n-k)) * (Y((1+k):n,:)'* Y(1:(n-k),:) );
    mat = covMat(Y,n,p,k);
    
    S   = S + mat*mat';                            %cumulative MDDM(k0)
end

[eVec,eVal] = eig(S);                      %eigendec. cumulative MDDM(k0)
eVal = diag(eVal);
if eVal(1) <= eVal(2) && eVal(2) <= eVal(3) && eVal(end - 1) <= eVal(end)
    
    eVal = sort(eVal,"descend");
    
    eVec2 = eVec;
    for j = 1:p
        
        eVec(:,j) = eVec2(:,p - (j-1));
        
    end
end
if p < 100
    R  = p-1;
else
    R = floor((p/3));
end
lambda = zeros(R,1);

for i=1:R
    lambda(i) = eVal(i+1)/eVal(i);         %lambda= ratios subsequent eigenVals
end


[~,argMin] =  min(lambda(1:R));                 % argmin of ratios 
    icstar = argMin;


if nargin == 2

    r = icstar;

end



Ahat = eVec(:,(1:r));   


% Components
    fhat=Y*Ahat;
    
    chat=fhat*Ahat';
    %ic1 = argMin;
    ss = eVal;
end




function X = covMat(Y,n,p,k)
Y = Y';
sum=zeros(p,p);
for t = 1:(n-k)
    sum = sum + Y(:,t+k)*Y(:,t)' ;
end
X = (1/(n-k))*sum ;

end

