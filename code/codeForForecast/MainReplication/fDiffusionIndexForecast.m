function [pred,py,pf] = fDiffusionIndexForecast(yf,y,F,vV,py,pf,h)
% This function produces h-step-ahead forecasts based on a diffusion index model
% where the dependent variable is regressed on factors and their lags.
% Inputs:
%   yf    - Forecast target variable
%   y     - Dependent variable for lag construction
%   F     - Factors (e.g., principal components)
%   vV    - Additional predictors (can be empty)
%   py    - Number of lags of y included
%   pf    - Number of lags of F included
%   h     - Forecast horizon
% Outputs:
%   pred  - h-step ahead forecast
%   py    - Number of lags of y used
%   pf    - Number of lags of F used

% Determine the number of factors
r = size(F,2);

% Compute the maximum lag required
pmax = max([py pf]);

% Create lag matrices for factors and dependent variable if needed
if pmax
    L   = lagmatrix(F, 1:pf); % Lags of factors
    L   = L(pmax + 1 : end, :); % Adjust for maximum lag
    X   = lagmatrix(y,1:py); % Lags of dependent variable
    X   = X(pmax+1:end,:);
    yf  = yf(pmax + 1 : end, :);
    F   = F(pmax + 1 : end, :);
else
    % No lags specified
    L = [];
    X = [];
end

% Set dependent variable for regression
Y = yf;

% Construct the regressor matrix Z
if pf
    Z = [ones(size(L(:,1))) L X]; % Intercept, lagged factors, lagged y
else
    Z = [ones(size(F(:,1))) F L X]; % Intercept, factors, lagged factors, lagged y
end

% Check if additional predictors are included
if isempty(vV)
    % Estimate model coefficients without additional predictors
    gamma = [Z(1:end-h,:)]\ Y(1+h:end,:);

    % Construct the regressor vector for forecasting
    if py == 0 && pf == 0
        ZP = [1 F(end,:)];

    elseif py > 0 && pf == 0
        ZP = [1 F(end,:) flip(y(end-py+1:end,1)')];

    elseif py == 0 && pf > 0
        ZP = [1 F(end,:) L(end,1:end-r)];

    elseif py > 0 && pf >0
        ZP = [1 F(end,:) L(end,1:end-r) flip(y(end-py+1:end,1)') ];
    end

    % Generate the forecast
    pred = ZP * gamma;

else
    % Additional predictors are included
    vV = vV(pmax + 1:end,:);
    
    % Estimate model coefficients including additional predictors
    gamma = [Z(1:end-h,:) vV(1+h:end,:)]\ Y(1+h:end,:);
    
    % Construct the regressor vector for forecasting including vV
    if py == 0 && pf == 0
        ZP = [1 F(end,:) vV(end,:)];

    elseif py > 0 && pf == 0
        ZP = [1 F(end,:) flip(y(end-py+1:end,1)') vV(end,:)];

    elseif py == 0 && pf > 0
        ZP = [1 F(end,:) L(end,1:end-r) vV(end,:)];

    elseif py > 0 && pf >0
        ZP = [1 F(end,:) L(end,1:end-r) flip(y(end-py+1:end,1)') vV(end,:)];
    end

    % Generate the forecast
    pred = ZP * gamma;
end

end