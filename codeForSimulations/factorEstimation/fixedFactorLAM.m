
% fixedFactorLAM - Estimates Factor Model with Fixed Number of Factors using Cumulative Linear Covariance Matrix
%
% Description:
%   Estimates a factor model for a stationary multivariate time series with a
%   fixed number of factors using the cumulative linear covariance matrix, as
%   described in Lam, Yao, and Bathia (2011) and Lam and Yao (2012). The
%   function computes the cumulative covariance matrix over k0 lags, performs
%   spectral decomposition, and estimates the factor loadings, factors, and
%   common component for a specified number of factors.
%
% Inputs:
%   Y     - T x n matrix, time series data with T observations and n variables
%   k0    - Positive integer, number of lags for cumulative covariance matrix
%   r     - Positive integer, fixed number of factors to estimate
%
% Outputs:
%   fhat   - T x r matrix, estimated factors (F_hat)
%   Ahat   - n x r matrix, estimated factor loadings (Lambda_hat)
%   chat   - T x n matrix, estimated common component (F_hat * Lambda_hat')
%   ss     - n x 1 vector, eigenvalues of the cumulative covariance matrix
%
% References:
%   Lam, C., Yao, Q., and Bathia, N. (2011). Estimation of Latent Factors for
%   High-Dimensional Time Series. Biometrika, 98(4), 901–918.
%   DOI: 10.1093/biomet/asr047
%
%   Lam, C., and Yao, Q. (2012). Factor Modeling for High-Dimensional Time
%   Series: Inference for the Number of Factors. The Annals of Statistics,
%   40(2), 694–726. DOI: 10.1214/12-AOS970
%
% Notes:
%   - Assumes Y is properly formatted as a T x n matrix and k0 is less than T.
%   - The number of factors is fixed at the input r, and no estimation of the
%     number of factors is performed.
%   - Uses the covMat function to compute the sample covariance matrix for
%     each lag.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fhat, Ahat, chat, ss] = fixedFactorLAM(Y, k0, r)

[n, p] = size(Y);
S = zeros(p, p);

for k = 1:k0
    mat = covMat(Y, n, p, k);
    S = S + mat * mat'; % Cumulative covariance matrix
end

[eVec, eVal] = eig(S);
eVal = diag(eVal);
[eVal, idx] = sort(eVal, 'descend'); % Sort eigenvalues in descending order
eVec = eVec(:, idx); % Reorder eigenvectors accordingly

Ahat = eVec(:, 1:r);

% Components
fhat = Y * Ahat;
chat = fhat * Ahat';
ss = eVal;

end

function X = covMat(Y, n, p, k)
sum = zeros(p, p);
for t = 1:(n-k)
    sum = sum + Y(t+k, :)' * Y(t, :);
end
X = (1/(n-k)) * sum;
end