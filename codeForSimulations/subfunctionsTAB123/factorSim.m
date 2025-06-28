%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FACTORSIM: Simulate Data from Factor Models
%
% Purpose:
%   Simulates high-dimensional data from a factor model with specified data-
%   generating processes (DGPs 1-3) as described in the paper. Generates data 
%   with autoregressive factors, random loadings, and idiosyncratic components 
%   with homoskedastic, heteroskedastic, or cross-sectionally correlated structures.
%
% Inputs:
%   - T: Time-series dimension (scalar)
%   - n: Cross-sectional dimension (scalar)
%   - r: True number of factors (scalar)
%   - thetaMethod: Signal-to-noise ratio parameter type (scalar, 1 to 4)
%       - 1: theta = 0.5*r
%       - 2: theta = r
%       - 3: theta = 3*r
%       - 4: theta = 5*r
%   - DGP: Data Generating Process type (scalar, 1 to 3)
%       - 1: Homoskedastic idiosyncratic components
%       - 2: Heteroskedastic idiosyncratic components
%       - 3: Cross-sectionally correlated idiosyncratic components
%
% Outputs:
%   - mX: Simulated data matrix (T x n)
%
% Model:
%   x_it = sum_{j=1}^r Lambda_ij F_tj + sqrt(theta) zeta_it
%   - F_t: AR(1) factors with coefficients ~ U(0.5, 0.9)
%   - Lambda: Factor loadings ~ N(0, 1)
%   - zeta_it: Idiosyncratic components (defined by DGP)
%
% Dependencies:
%   - MATLAB Statistics and Machine Learning Toolbox (for randn, unifrnd)
%
% Notes:
%   - DGPs follow specifications in Bai & Ng (2002) and Alessi et al. (2010).
%   - Factor process follows Gao & Tsay (2021).
%
% References:
%   - Bai, J., & Ng, S. (2002). Determining the number of factors in approximate 
%     factor models. Econometrica, 70(1), 191-221.
%   - Alessi, L., Barigozzi, M., & Capasso, M. (2010). Improved penalization for 
%     determining the number of factors in approximate factor models. Statistics 
%     & Probability Letters, 80(23-24), 1806-1813.
%   - Gao, Z., & Tsay, R. (2021). Modeling high-dimensional time series with 
%     factor models. Journal of Business & Economic Statistics, 39(4), 1056-1067.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function[mX] = factorSim(T,n,r,thetaMethod,DGP)

if thetaMethod == 1
    theta = 0.5 * r;

elseif thetaMethod == 2
    theta = r;

elseif thetaMethod == 3
    theta = 3 * r;

elseif thetaMethod == 4
    theta = 5 * r;

end



if DGP == 1

    %Homoskedastic idiosyncratic components
    mEpsi = randn(T,n);

elseif DGP == 2

    %Heteroskedastic idiosyncratic components
    mEpsi = zeros(T,n);
    for t = 1:T
        mEpsi(t,:) = (mod(t,2)~=0)*(randn(1,n)) +  (mod(t,2)==0)*(randn(1,n) + randn(1,n));
    end

elseif DGP == 3

    %Cross-sectional correlations among idiosyncratic components

    J     = max(n/20,10); beta = 0.2;
    vV    = randn(T, n+2*J);
    mBeta = zeros(n+2*J, n);
    vBeta = [beta*ones(J,1);1;beta*ones(J,1)];
    span  = length(vBeta);

    for k = 1:n
        mBeta(k:(span+k-1),k) = vBeta;
    end

    mEpsi = vV * mBeta;



end

mLambda = randn(r,n);
mF = zeros(T,r);



for i = 1:r
    par=unifrnd(0.5,0.9);
    e=randn(T,1);
    b = 1;
    a = [1 -par];
    mF(:,i) = filter(b,a,e);

end



mX = mF * mLambda + sqrt(theta) * mEpsi;
end

