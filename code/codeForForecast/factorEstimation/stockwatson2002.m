function [F,ehat,lambda,chat] = stockwatson2002(x,nfac)

% Implements the factor estimation procedure from:
% 1) Stock, J. H., & Watson, M. W. (2002a). Forecasting using principal components from a large number of predictors.
% 2) Stock, J. H., & Watson, M. W. (2002b). Macroeconomic forecasting using diffusion indexes.
%
% Inputs:
%   x     - T x N matrix of observed data (T time periods, N variables)
%   nfac  - Number of factors to estimate via PCA
%
% Outputs:
%   F     - T x r matrix of estimated factors
%   ehat  - T x N matrix of residuals
%   lambda - N x r matrix of estimated factor loadings
%   chat  - T x N matrix of estimated common component (F * lambda')
%
% Notes:
%   - Based on principal component analysis (PCA) of the covariance matrix.
%   - Assumes x is standardized (if required) before input.


[~,bign]              =  size(x);
xx                    =  x'*x;
[Fhat0,eigval,Fhat1]  =  svd(xx);
lambda                =  Fhat0(:,1:nfac)*sqrt(bign);
F                     =  x*lambda/bign;
ehat                  =  x-F*lambda';
chat                  =  F*lambda';
ve2                   =  sum(ehat'.*ehat')'/bign;
ss                    =  diag(eigval);

end