function [outRes,vV] = fMeanClean(x,vt,cp)
% This function removes the influence of specified covariates (e.g., COVID-related variables)
% from a dataset by regressing each column of x onto vt and its lags, and saving the residuals.
%
% Inputs:
%   x   - Matrix of regressors (e.g., macroeconomic variables from FRED)
%   vt  - Matrix of special covariates (e.g., COVID indicators)
%   cp  - Number of lags of vt to include (fixed to 3 lags, following Ng 2021)
%
% Outputs:
%   outRes - Residuals of x after regressing on vt and its lags (T1 x NN matrix)
%   vV     - Matrix containing vt and its lags used in the regression

%% Step 1: Construct lagged versions of vt
vL = lagmatrix(vt,1:cp);       % Create lagged versions of vt from lag 1 to cp
vL = vL((cp+1):end,:);          % Drop initial cp observations with missing values

% Compute mean of each lagged regressor
mVL = mean(vL,1);

%% Step 2: Remove zero columns (optional cleaning)
for j = 1:cp
    if mVL(j) == 0
        % If the mean of the j-th lag is zero, discard all subsequent lags
        vL = vL(:,1:(j-1));
        break
    end
end

%% Step 3: Align the original data (drop initial cp observations)
v1 = vt((cp+1):end,:);           % Align vt
x1 = x((cp+1):end,:);            % Align x

% Create the full matrix of regressors (original vt plus lags)
vV = [v1 vL];

% Dimensions
[T1, NN] = size(x1);             % T1 observations, NN variables

%% Step 4: Perform regression and compute residuals
outRes = zeros(T1, NN);          % Initialize residuals matrix

for k = 1:NN
    X = vV;                      % Regressors: vt and its lags
    Y = x1(:,k);                 % Current column of x to be cleaned
    
    % Estimate OLS coefficients
    beta = (X'*X) \ (X'*Y);
    
    % Compute residuals: cleaned series for variable k
    outRes(:,k) = Y - X*beta;
end

end
