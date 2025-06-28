% fLeeShaoNonLinear - Simulates nonlinear factor model data from Lee & Shao (2018)
%
% Description:
%   Generates simulated data for a three-dimensional factor model as described
%   in Example 6 of Lee & Shao (2018). The factor series follows a nonlinear
%   process, and the covariance matrix of the error term is constructed with a
%   Hurst exponent H=0.9. The factor loading matrix has non-zero elements for
%   the first half of each column, drawn from a uniform distribution.
%
% Inputs:
%   T - Number of time periods (positive integer)
%   N - Number of cross-sectional units (positive integer)
%
% Outputs:
%   Yt - T x N matrix of simulated data
%
% References:
%     Lee, J., & Shao, X. (2018). Martingale Difference divergence matrix and its application
%     to dimension reduction for stationary multivariate time series. Journal of the
%     American Statistical Association.
% Notes:
%   - The function includes a burn-in period of 500 observations to stabilize
%     the nonlinear factor process.
%   - The factor loading matrix A is fixed once generated, with the first N/2
%     rows drawn from U(-2,2) and the rest set to zero.
%   - The error term is drawn from a multivariate normal distribution with
%     covariance 0.25*Sigma, where Sigma is defined by the Hurst exponent H=0.9.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function Yt = fLeeShaoNonLinear(T,N)

if nargin == 2
    r    = 3;
    A          = zeros(N,3);
    A(1:round(N/2),:) = -2 + (2+2)*rand(round(N/2),r);
    
end

burn    = 500;
T       = T+burn;
zt      = randn(T,1);
wt(1)   = 0;
for i = 2:T
    if wt(i-1,1) < 5
        wt(i,1) = 0.5 + (0.05*exp(-0.01*wt(i-1,1).^2) +0.9)*wt(i-1,1) + zt(i,:);
    else
        wt(i,1) = (0.9*exp(-10*wt(i-1,1).^2))*wt(i-1,1) + zt(i,:); 
    end
end

xt      = lagmatrix(wt,1:(r-1));
xt      = [wt,xt];
xt      = xt(burn+1:end,:);
sigma   = zeros(N,N);
H       = 0.9;
for i = 1:N
    for j = 1:N
        ind = i-j;
        if ind == 0
            sigma(i,j) = 1;
        else
        sigma(i,j) = 0.5*((abs(i-j)+1).^(2*H)-2*abs(i-j).^(2*H)+(abs(i-j)-1).^(2*H));
        end
    end
end
%et         = mvnrnd(zeros(N,1),eye(N),T);
et         = mvnrnd(zeros(N,1),0.25*sigma,T);
et         = et(burn+1:end,:);

Yt         = xt*A' + et;