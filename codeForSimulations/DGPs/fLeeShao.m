% fLeeShao - Simulates linear factor model data from Lee & Shao (2018)
%
% Description:
%   Generates simulated data for a three-dimensional factor model as described
%   in Example 5 of Lee & Shao (2018). The factor series is generated from a
%   linear MA(1) process, and the error term has a covariance matrix defined
%   with a Hurst exponent H=0.9. The factor loading matrix has non-zero
%   elements for the first half of each column, drawn from a uniform distribution.
%
% Inputs:
%   T - Number of time periods (positive integer)
%   N - Number of cross-sectional units (positive integer)
%   r - Number of factors (positive integer, typically 3)
%
% Outputs:
%   Yt - T x N matrix of simulated data
%
% References:
%     Lee, J., & Shao, X. (2018). Martingale Difference divergence matrix and its application
%     to dimension reduction for stationary multivariate time series. Journal of the
%     American Statistical Association.
%
% Notes:
%   - The factor series is generated from an MA(1) process: w_t = z_t + 0.2*z_{t-1},
%     where z_t ~ N(0,1).
%   - A burn-in period of 500 observations is used to stabilize the factor process.
%   - The factor loading matrix A has the first N/2 rows drawn from U(-2,2), with
%     the remaining rows set to zero, and is fixed once generated.
%   - The error term is drawn from N(0, Sigma), where Sigma is defined with
%     Hurst exponent H=0.9.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Yt = fLeeShao(T,N,r)
burn    = 500;
T       = T+burn;
%zt      = randn(T,1);
%b       = 1;
%a       = [1 -0.2];
%wt      = filter(b,a,zt);


Mdl = arima('Constant',0,'MA',{0.2},'Variance',1);
wt = simulate(Mdl,T);

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
et         = mvnrnd(zeros(N,1),sigma,T);
et         = et(burn+1:end,:);
A          = zeros(N,3);
A(1:round(N/2),:) = -2 + (2+2)*rand(round(N/2),r);
%A=  -2 + (2+2)*rand(N,r);
Yt         = xt*A' + et;