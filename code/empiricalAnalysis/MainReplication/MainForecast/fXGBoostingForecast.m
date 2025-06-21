function [pred,py,pf] = fXGBoostingForecast(yf,y,F,vV,py,pf,learningRate,numLearningCycles,h)
%==========================================================================
% [pred,py,pf] = fXGBoostingForecast(yf,y,F,vV,py,pf,learningRate,numLearningCycles,h)
%
% This function computes h-step ahead forecasts using XGBoost (Least Squares Boosting)
% in a regression setting with dynamic regressors (lags of the dependent variable
% and factors), optionally including additional controls (vV, e.g., structural dummies).
%
% INPUT:
% yf                  - Target series to be forecasted (training version)
% y                   - Original target series (used to build lags)
% F                   - Matrix of predictors (usually factors or macro indicators)
% vV                  - Additional control variables (e.g., COVID dummies or shocks)
% py                  - Number of lags of the dependent variable y
% pf                  - Number of lags of the factors F
% learningRate        - Shrinkage parameter (boosting step size)
% numLearningCycles   - Number of boosting iterations
% h                   - Forecast horizon
%
% OUTPUT:
% pred                - Forecast for y at time T+h
%
% NOTE: This function is used in pseudo real-time simulation to estimate
%       boosting-based forecasts for macroeconomic applications
%==========================================================================

r = size(F,2);  % Number of predictors (e.g., factors)

%% Create lagged regressors for y and F
pmax = max([py pf]);

if pmax
    L       = lagmatrix(F, 1:pf);                        % Lags of the factors
    L       = L(pmax + 1 : end, :);
    X       = lagmatrix(y, 1:py);                        % Lags of the target variable
    X       = X(pmax + 1 : end, :);
    yf      = yf(pmax + 1 : end, :);                     % Align target variable
    F       = F(pmax + 1 : end, :);                      % Align factors
else
    L = [];
    X = [];
end

%% Construct the regressor matrix Z
Y = yf; % Response variable
if pf
    Z = [ones(size(L,1),1) L X]; % Include intercept, factor lags and y lags
else
    Z = [ones(size(F,1),1) F L X]; % Include intercept, raw factors, and lags
end

% Boosting options (parallel training can be enabled with statset)
options = statset('UseParallel', true);

%% Model estimation and forecasting
if isempty(vV)
    % Estimate boosting model without additional controls
    model = fitensemble([Z(1:end-h,:)], Y(1+h:end,:), 'LSBoost', ...
        numLearningCycles, 'Tree', 'Type', 'Regression', 'LearnRate', learningRate);

    % Construct predictor for out-of-sample point depending on available lags
    if py == 0 && pf == 0
        ZP = [1 F(end,:)];

    elseif py > 0 && pf == 0
        ZP = [1 F(end,:) flip(y(end-py+1:end,1)')];

    elseif py == 0 && pf > 0
        ZP = [1 F(end,:) L(end,1:end-r)];

    elseif py > 0 && pf > 0
        ZP = [1 F(end,:) L(end,1:end-r) flip(y(end-py+1:end,1)')];
    end

    pred = predict(model, ZP); % Generate forecast

else
    % Estimate boosting model with additional regressors (e.g., structural controls)
    vV = vV(pmax + 1:end,:);
    model = fitensemble([Z(1:end-h,:) vV(1+h:end,:)], Y(1+h:end,:), ...
        'LSBoost', numLearningCycles, 'Tree', 'Type', 'Regression', 'LearnRate', learningRate);

    % Construct predictor with vV included
    if py == 0 && pf == 0
        ZP = [1 F(end,:) vV(end,:)];

    elseif py > 0 && pf == 0
        ZP = [1 F(end,:) flip(y(end-py+1:end,1)') vV(end,:)];

    elseif py == 0 && pf > 0
        ZP = [1 F(end,:) L(end,1:end-r) vV(end,:)];

    elseif py > 0 && pf > 0
        ZP = [1 F(end,:) L(end,1:end-r) flip(y(end-py+1:end,1)') vV(end,:)];
    end

    pred = predict(model, ZP); % Generate forecast
end