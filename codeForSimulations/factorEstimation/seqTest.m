% SEQTEST - Sequential Testing for Factor Dimension in FMMDE Models
%
% Description:
%   This function implements a novel sequential testing procedure to determine the
%   number of latent factors in Factor Models with Martingale Difference Errors (FMMDE),
%   as introduced by Lee and Shao (2018). Under the FMMDE framework, the idiosyncratic
%   component is a martingale difference sequence (MDS), a stricter condition than white
%   noise, enabling a linear transformation of the original series to segment the
%   transformed series P_t = (P_{1,t}, ..., P_{n,t}) into two groups: conditionally
%   mean-dependent factors (F_t, common component) and MDS components (E_t, conditionally
%   mean independent). The procedure sequentially tests each transformed series P_{i,t}
%   to identify those that reject the MDS hypothesis, indicating conditional mean
%   dependence on past information, thus determining the factor dimension r.
%
%   The test statistic, proposed by Wang, Zhu, and Shao (2022), uses the Martingale
%   Difference Divergence Matrix (MDDM) to measure conditional mean dependence. While
%   this test is employed, other MDS tests could be used. Due to the non-pivotal null
%   distribution of the statistic, a fixed-design wild bootstrap (Rademacher or Mammen)
%   approximates p-values, with the factor model re-estimated for each bootstrap
%   replicate. Testing begins with components corresponding to the largest eigenvalues
%   of the cumulative MDDM matrix (Gamma_k0) and stops when the MDS hypothesis cannot
%   be rejected for P_{i,t}, setting r = i-1.
%
% Inputs:
%   Y     - T x p matrix of multivariate time series data (T observations, p variables).
%   B     - Number of bootstrap replicates for p-value approximation.
%   crit  - Critical p-value threshold (e.g., 0.05 for 5% significance level).
%   k0    - Number of lags for cumulative MDDM in factor model estimation.
%   boot  - Bootstrap type: 'radem' for Rademacher (default) or 'esc' for
%           Mammen distribution.
%   cut   - logical value, true in the case we only consider a fraction (one
%           third of n) of the estimated factors in the bootstrap mechanism of the sequential testing procedure. 
%           It decreases computing times drastically at the cost of lowered precision of the factor selection procedure 
%           as detailed in the Appendix.
%
%
% Outputs:
%   vPvals - Vector of p-values for each tested component P_{i,t}. Untested components
%            (after stopping) are assigned p-value = 1.
%   out    - T x r matrix of the first r components P_{i,t} where the MDS hypothesis
%            was rejected (i.e., conditionally mean-dependent factors).
%
% Methodology:
%   1. Estimate the FMMDE model using factorMDDM, computing the cumulative MDDM over
%      k0 lags to obtain the loading matrix M and transformed series P_t = Y*M, ordered
%      by the largest eigenvalues of Gamma_k0.
%   2. For each component i :
%      a. Compute the test statistic T_wn^F for P_{i,t} using testWZS, as per Wang, Zhu, and Shao (2022).
%      b. Generate B bootstrap samples:
%         - Set F_t = P_{1:(i-1),t} (mean-dependent factors) and E_t = P_{i:n,t} (remaining).
%         - Apply bootstrap weights (Rademacher or Mammen) to E_t to form E_t*.
%         - Construct bootstrap sample x_t* = M * [F_t', E_t*']'.
%         - Re-estimate the FMMDE model to obtain P_t* and compute T_wn^* for P_{i,t}^*.
%      c. Compute the p-value as sum(I(T_wn,b^* >= T_wn^F))/(B+1).
%      d. If p-value > crit, stop, set r = i-1, and assign p-value = 1 to remaining
%         components. Otherwise, proceed to P_{i+1,t}.
%   3. Return p-values and the mean-dependent factors.
%
% Notes:
%   - The test statistic uses M=9 lags by default, adjustable based on application needs.
%   - The maximum number of components tested is r=15, which can be modified.
%   - Rademacher bootstrap: w_t* = {1, -1}, P(w_t* = 1) = P(w_t* = -1) = 0.5.
%     Mammen bootstrap: w_t* = {(1-sqrt(5))/2, (1+sqrt(5))/2}, with
%     P(w_t* = (1-sqrt(5))/2) = (sqrt(5)+1)/(2*sqrt(5)),
%     P(w_t* = (1+sqrt(5))/2) = (sqrt(5)-1)/(2*sqrt(5)).
%   - Input data Y must be stationary, as required by the FMMDE framework.
%   - If the MDS hypothesis is not rejected for P_{1,t}, r = 0, and F_t = 0.
%
% References:
%   - Lee, C. E., & Shao, X. (2018). Martingale Difference Divergence Matrix and its
%     application to dimension reduction for stationary multivariate time series.
%   - Wang, G., Zhu, K., & W., & Shao, X. (2022). Testing for the Martingale Difference
%     Hypothesis in Multivariate Time Series Models.
%   - Lam, C., & Yao, Q. (2011). Factor modeling for high-dimensional time series.
%   - Wu, C. F. J. (1986). Jackknife, bootstrap and other resampling methods in
%     regression analysis.
%   - Liu, R. Y. (1988). Bootstrap procedures under some non-I.I.D. models.
%   - Mammen, E. (1993). Bootstrap and wild bootstrap for high dimensional linear
%     models.
%
% Author: [Luca Mattia Rolla, Università di Tor Vergata]

function[vPvals,out] = seqTest(Y,B,crit,k0,boot,cut)   

if nargin == 4
    boot = "radem";
    cut  = 0;
elseif nargin == 5
    cut = 0;
end

r=15;

[F,Ahat,~] = factorMDDM(Y,k0,r);

[T,colsF] = size(F); vPvals = NaN(colsF,1);

if cut == 1
    colsF= floor(colsF/3);
end

 F = F(:,1:colsF); Ahat = Ahat(:,1:colsF);

if boot == "radem"
  test  = @(x) testWZS(x, 'w', 9, 0); 
  bootF = @(x) bernRadem(x);
elseif boot == "esc"
  test  = @(x) testWZS(x, 'w', 9, 0);
  bootF = @(x) bernEsc(x);
end

for i = 1:r   


        stat = test(F(:,i));  
        Tstar = zeros(B,1);

        for b=1:B
            W = bootF(T); Estar  = F(:,i:end);  

            for ik = 1:T
                Estar(ik,:) = Estar(ik,:) * W(ik);
            end

            Ystar       = [F(:,1:(i-1)),Estar]*Ahat';  Fstar = factorMDDM(Ystar,k0,r);
            Tstar(b)    = test(Fstar(:,i)); 

        end

        vPvals(i) = sum(Tstar>=stat )/(B+1);


        if vPvals(i) > crit
            for q = (i+1):colsF
                vPvals(q) = 1;
            end
            break            
        end
      



end

logik = vPvals <= crit;
out = F(:,logik);


end


%%


function[fhat,Ahat,chat] = factorMDDM(Y,k0,~)

[n, p] = size(Y);
S = zeros(p,p);                   
                                  
for k=1:k0                                    % k0:lags cumul. MDDM(pag 219)
    S = S + MDDM( Y(1:(n-k),:), Y((1+k):n,:) );       %cumulative MDDM(k0)
end

[eVec,eVal] = eig(S);                           %eigendec. cumulative MDDM(k0)

eVal = diag(eVal);
[~, idx] = sort(eVal, 'descend'); % Sort eigenvalues in descending order
eVec = eVec(:, idx); % Reorder eigenvectors accordingly
Ahat = eVec(:,(1:p));   


% Components
    fhat=Y*Ahat;
    
    chat=fhat*Ahat';
    
end





%%

function [stat,pval] = testWZS(Y, type, M, B)

if nargin == 1
    type = 'w';
    B = 999;
    M = 6;
elseif nargin == 2
    B = 999;
    M = 6;
elseif nargin == 3
    B = 999;
end

%norm(X,'fro')
[N, p] = size(Y);


if type == 'w'
    T = 0;
    for j=1:M
        omegaj = (N - j + 1)/(N * (j)^2);
        T = T + omegaj * norm( MDDM( Y(1:(N-j),:), Y((1+j):N,:) ),'fro' );
    end
    stat = N * T;
    
    
    if B ~= 0
        Tstar = zeros(B,1);
        parfor b = 1:B
            T = 0;
            Ystar = Y; W = bernRadem(N);
            
            for ik = 1:N
                Ystar(ik,:) = Ystar(ik,:)*W(ik);
            end
            
            for j=1:M
                omegaj = (N - j + 1)/(N * (j)^2);
                T = T + omegaj * norm( MDDM( Ystar(1:(N-j),:), Ystar((1+j):N,:) ),'fro' );
            end
            
            Tstar(b) = N * T;
            
            
        end
        pval = sum(Tstar>=stat )/(B+1);

        
    end

end



end
%%

function out = bernRadem(n)
  p = 0.5;
  out = zeros(n,1);
  for i = 1:length(out)
    out(i) = binornd(1,p);
    out(i) = ( out(i) >= 1 ) + ( out(i) < 1 )*(-1);
  end
  
end


%%


function out = bernEsc(n)
  p = ( 1 + sqrt(5) )/( 2*sqrt(5));
  out = zeros(n,1);
  for i = 1:length(out)
    out(i) = binornd(1,p);
    out(i) = ( out(i) >= 1 )*(0.5)*(1-sqrt(5)) + ( out(i) < 1 )*(0.5)*(1+sqrt(5));
  end
  
end




%%

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







