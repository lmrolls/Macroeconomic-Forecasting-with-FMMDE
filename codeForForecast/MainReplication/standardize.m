function [y, M, s, MM, ss] = standardize(x, w)
% This function standardizes each column of the input matrix x.
% Optionally, a weighting vector w can be provided to adjust the standard deviation.
%
% Inputs:
%   x - Data matrix (T observations x N variables)
%   w - Optional weighting vector (1 x N); if not provided, defaults to a vector of ones
%
% Outputs:
%   y  - Standardized data matrix
%   M  - Row vector of means of each column of x
%   s  - Row vector of standard deviations (adjusted by w)
%   MM - Matrix of repeated means (T x N), same dimension as x
%   ss - Matrix of repeated standard deviations (T x N), same dimension as x

% If the weighting vector w is not provided, set it to a vector of ones
if nargin == 1
    w = ones(1, size(x,2));
end

% Compute the adjusted standard deviation for each variable
s = std(x) ./ w;  % Standard deviation divided by weight

% Compute the mean for each variable
M = mean(x);

% Expand the mean and standard deviation to full matrices (T x N) for element-wise operations
ss = ones(size(x,1), 1) * s;  % Matrix with each row equal to s
MM = ones(size(x,1), 1) * M;  % Matrix with each row equal to M

% Standardize the data
y = (x - MM) ./ ss;  % Subtract mean and divide by adjusted standard deviation

end
