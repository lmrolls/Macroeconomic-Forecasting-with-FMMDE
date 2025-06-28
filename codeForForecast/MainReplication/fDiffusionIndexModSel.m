function [bestModBIC,sBic] = fDiffusionIndexModSel(F,yf,y,vV,pmax,h)
% This function selects the optimal number of lags for a diffusion index model
% based on the Bayesian Information Criterion (BIC).
% Inputs:
%   F      - Factors (e.g., principal components)
%   yf     - Forecast target variable
%   y      - Dependent variable for lag construction
%   vV     - Additional predictors (can be empty)
%   pmax   - Maximum number of lags to consider
%   h      - Forecast horizon
% Outputs:
%   bestModBIC - Selected number of lags minimizing the BIC
%   sBic       - Minimum BIC value achieved

%------------------------ OLS ESTIMATOR -----------------------------------

% Adjust yf, lagged y, and F to match after maximum lag
yf  = yf(pmax + 1 : end, :);
Ly  = lagmatrix(y,1:pmax);
Ly  = Ly(pmax + 1 : end, :);
F   = F(pmax + 1 : end, :);

% Initialize index counter and BIC storage
ind = 0;
bic = NaN(pmax,1);

% Adjust additional regressors if they are provided
if ~isempty(vV)
    vV = vV(pmax + 1:end,:);
end

% Loop over possible lag orders (from 0 to pmax)
for nv = 1:pmax+1
    ind = ind+1;
    
    % Construct regressor matrix X
    if ind == 1
        X = [ones(length(yf),1) F]; % Intercept and factors only (no lags)
    else
        X = [ones(length(yf),1) F Ly(:,1:ind-1)]; % Intercept, factors, and lagged y
    end
    
    % Define the number of observations and parameters
    numObs   = length(yf(1+h:end,1));
    numParam = size(X,2);
    
    % Estimate model coefficients including additional predictors
    beta_hat = [X(1:end-h,:) vV(1+h:end,:)]\yf(1+h:end,1);
    
    % Compute residuals
    vRes = yf(1+h:end,1) - [X(1:end-h,:) vV(1+h:end,:)]*beta_hat;
    
    % Estimate variance of residuals
    U = var(vRes);
    
    % Compute log-likelihood under Gaussian errors
    LogL = -(numObs./2)*log(2*pi) - (numObs./2)*log(U) - (numObs./2);
    
    % Compute BIC value
    bic(ind,1) = -2*LogL + log(numObs).*(numParam+1);
end

% Find the lag order that minimizes the BIC
[sBic,sPos] = min(bic);
bestModBIC  = sPos-1;

end