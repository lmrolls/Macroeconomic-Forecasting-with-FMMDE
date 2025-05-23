% factorLAM - Estimates Factor Model using Cumulative Linear Covariance Matrix
%
% Description:
%   Estimates a factor model for a stationary multivariate time series using
%   the cumulative linear covariance matrix, as described in Lam, Yao, and
%   Bathia (2011) and Lam and Yao (2012). The function computes the cumulative
%   covariance matrix over k0 lags, performs spectral decomposition, and
%   estimates the factor loadings, factors, and common component. The number
%   of factors is estimated using an eigenvalue ratio method.
%
% Inputs:
%   Y     - T x n matrix, time series data with T observations and n variables
%   k0    - Positive integer, number of lags for cumulative covariance matrix
%   r     - Positive integer, number of factors to estimate
%
% Outputs:
%   fhat   - T x r matrix, estimated factors (F_hat)
%   Ahat   - n x r matrix, estimated factor loadings (Lambda_hat)
%   chat   - T x n matrix, estimated common component (F_hat * Lambda_hat')
%   ss     - n x 1 vector, eigenvalues of the cumulative covariance matrix
%   icstar - Integer, estimated number of factors based on eigenvalue ratios
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
%   - The number of factors is estimated using the eigenvalue ratio method but
%     capped at the input r.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fhat, Ahat, chat, ss, icstar] = factorLAM(Y, k0, r)

[n, p] = size(Y);
S = zeros(p, p);

for k = 1:k0
    mat = (1/(n-k)) * (Y((1+k):n, :)' * Y(1:(n-k), :));
    S = S + mat * mat'; % Cumulative covariance matrix
end

[eVec, eVal] = eig(S);
eVal = diag(eVal);
[eVal, idx] = sort(eVal, 'descend'); % Sort eigenvalues in descending order
eVec = eVec(:, idx); % Reorder eigenvectors accordingly

R = floor((p/3));
lambda = zeros(R, 1);
for i = 1:R
    lambda(i) = eVal(i+1) / eVal(i); % Ratio for smallest eigenvalues
end

[~, argMin] = min(lambda(1:R)); % Minimize ratio
icstar = argMin;

Ahat = eVec(:, 1:r);

% Components
fhat = Y * Ahat;
chat = fhat * Ahat';
ss = eVal;

end
