
function [fhat, Ahat, chat, ss] = fixedFactorsMDDM(Y, k0, r)
% estimateFactorsMDDM - Estimates Factor Model with Prespecified Factors
%
% Description:
%   Estimates a factor model for a stationary multivariate time series using
%   the cumulative Martingale Difference Divergence Matrix (CMDDM), as
%   described in Lee & Shao (2018). The function computes the CMDDM over
%   k0 lags, performs spectral decomposition, and estimates the factor
%   loadings, factors, and common component for a prespecified number of
%   factors r. Focuses on factor estimation rather than determining the number
%   of factors.
%
% Inputs:
%   Y     - T x n matrix, time series data with T observations and n variables
%   k0    - Positive integer, number of lags for cumulative MDDM
%   r     - Positive integer, prespecified number of factors to estimate
%
% Outputs:
%   fhat  - T x r matrix, estimated factors (F_hat)
%   Ahat  - n x r matrix, estimated factor loadings (Lambda_hat)
%   chat  - T x n matrix, estimated common component (F_hat * Lambda_hat')
%   ss    - n x 1 vector, eigenvalues of the cumulative MDDM
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
%   - Eigenvalues are sorted in descending order to select the r eigenvectors
%     corresponding to the largest eigenvalues, representing non-MDS factors.
%   - Assumes Y is properly formatted, k0 is less than T, and r is not greater
%     than n.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[n, p] = size(Y);
S = zeros(p, p);

% Compute cumulative MDDM over k0 lags
for k = 1:k0
    S = S + MDDM(Y(1:(n-k), :), Y((1+k):n, :));
end

% Eigendecomposition of cumulative MDDM
[eVec, eVal] = eig(S);
eVal = diag(eVal);
[eVal, idx] = sort(eVal, 'descend'); % Sort eigenvalues in descending order
eVec = eVec(:, idx); % Reorder eigenvectors accordingly

% Estimate factor loadings (r eigenvectors for largest eigenvalues)
Ahat = eVec(:, 1:r);

% Compute components
fhat = Y * Ahat; % Estimated factors
chat = fhat * Ahat'; % Common component
ss = eVal; % Eigenvalues

end