% factorMDDMtab4 - Estimates Factor Model using Martingale Difference Divergence Matrix
%
% Description:
%   Estimates a factor model for a stationary multivariate time series using
%   the cumulative Martingale Difference Divergence Matrix (CMDDM), as
%   described in Lee & Shao (2018). The function computes the CMDDM over
%   k0 lags, performs spectral decomposition, and estimates the factor
%   loadings, factors, and common component. It also estimates the number of
%   factors using an eigenvalue ratio method tailored for the Monte Carlo
%   simulation in Table 4 of the paper.
%
% Inputs:
%   Y     - T x n matrix, time series data with T observations and n variables
%   k0    - Positive integer, number of lags for cumulative MDDM
%   r     - Positive integer, maximum number of factors to estimate
%
% Outputs:
%   fhat   - T x icstar matrix, estimated factors (F_hat)
%   Ahat   - n x icstar matrix, estimated factor loadings (Lambda_hat)
%   chat   - T x n matrix, estimated common component (F_hat * Lambda_hat')
%   ss     - n x 1 vector, eigenvalues of the cumulative MDDM
%   icstar - Integer, estimated number of factors based on eigenvalue ratios
%
% References:
%   Lee, E., & Shao, X. (2018). Martingale Difference Divergence Matrix and
%   Its Application to Dimension Reduction for Stationary Multivariate Time
%   Series. Journal of the American Statistical Association, 113(521),
%   216–229. DOI: 10.1080/01621459.2016.1240082
%
% Notes:
%   - Requires the MDDM function to compute the sample Martingale Difference
%     Divergence Matrix for each lag.
%   - The number of factors is estimated using the eigenvalue ratio method,
%     specifically designed to produce results for Table 4 in the paper.
%   - The parameter R = floor(p/4) is necessary to ensure the proper functioning
%     of the eigenvalue ratio method, limiting the search space for the number
%     of factors and ensuring a valid comparison with other factor selection
%     methods (e.g., Sequential Testing) in the simulation.
%   - The estimated number of factors (icstar) is capped at the input r to prevent
%     overestimation, aligning with controlled simulation settings.
%   - Assumes Y is properly formatted and k0 is less than T.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fhat, Ahat, chat, ss, icstar] = factorMDDMtab4(Y, k0, r)

[n, p] = size(Y);
S = zeros(p,p);                   

for k=1:k0
    S = S + MDDM(Y(1:(n-k),:), Y((1+k):n,:));
end

[eVec, eVal] = eig(S);
eVal = diag(eVal);
[eVal, idx] = sort(eVal, 'descend'); % Sort eigenvalues in descending order
eVec = eVec(:, idx); % Reorder eigenvectors accordingly

R = floor((p/4));
lambda = zeros(R,1);

for i=1:R
    lambda(i) = eVal(i)/eVal(i+1); % Ratio for largest eigenvalues
end

[~, argMin] = max(lambda(1:R)); % Maximize ratio
icstar = argMin;

% === Cap on the maximum number of estimated factors ===
if icstar > r
    icstar = r;
end
% ======================================================

Ahat = eVec(:, (1:icstar));

% Components
fhat = Y*Ahat;
chat = fhat*Ahat';
ss = eVal;
end