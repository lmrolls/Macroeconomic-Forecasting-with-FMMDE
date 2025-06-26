function pred = fAutoRegressiveForecast(yf,y,vV,nlag,h)

% This function generates out-of-sample forecasts using an autoregressive (AR) model.
% Inputs:
%   yf              - Transformed variable accordig to Stock and Watson
%   2002
%   y               - Originsal Variable
%   nlag            - Number of lags included in the AR model
%   constant        - Option to include a constant term ('constant' or 'nocons')
% Outputs:
%   forecast        - Predicted values for the test set
%   prediction_error - Difference between actual and predicted values (forecast errors)

%% LAG VALUES OF Y

if isempty(vV)
    if nlag == 0
        Y       = yf;
        Z       = ones(size(y(:,1)));
        gamma   = Z(1:end-h,:) \ Y(1+h:end,:);
        pred    = 1 * gamma;
    else
        pbic    = nlag;
        X       = lagmatrix(y,1:pbic);
        X       = X(pbic+1:end,:);
        yf      = yf(pbic+1:end,:);
        Y       = yf;
        Z       = [ones(size(X(:,1))) X];
        gamma   = Z(1:end-h,:)  \ Y(1+h:end,:);
        pred    = [1 flip(y(end-pbic+1:end,1))'] * gamma;
    end
else
    vV = vV(nlag+1:end,:);
    if nlag == 0
        Y       = yf;
        Z       = ones(size(y(:,1)));
        gamma   = [Z(1:end-h,:) vV(1+h:end,:)]\ Y(1+h:end,:);
        pred    = [1 vV(end,:)] * gamma;
    else
        pbic    = nlag;
        X       = lagmatrix(y,1:pbic);
        X       = X(pbic+1:end,:);
        yf      = yf(pbic+1:end,:);
        Y       = yf;
        Z       = [ones(size(X(:,1))) X];
        gamma   = [Z(1:end-h,:) vV(1+h:end,:)] \ Y(1+h:end,:);
        pred    = [1 flip(y(end-pbic+1:end,1))' vV(end,:)] * gamma;
    end
end





