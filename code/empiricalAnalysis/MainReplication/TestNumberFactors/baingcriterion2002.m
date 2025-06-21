function [PC, IC] = baingcriterion2002(X, rmax, rvar)
% This function implements the Bai and Ng (2002) criteria to determine the optimal
% number of factors in an approximate factor model.
%
% Reference:
% Bai, J., and Ng, S. (2002). "Determining the Number of Factors in Approximate
% Factor Models." *Econometrica*, 70(1), 191–221.
%
% Inputs:
%   X     - Data matrix (T observations x N variables)
%   rmax  - Maximum number of factors to consider
%   rvar  - Reference number of factors for penalty scaling (optional; defaults to rmax)
%
% Outputs:
%   PC    - Panel of Penalized Criteria (PC1 to PC4) for each number of factors
%   IC    - Information Criteria (IC1 to IC4) for each number of factors

% If the third input is not provided, set rvar equal to rmax
if nargin == 2
    rvar = rmax;
end

% Dimensions of the data matrix
N = size(X, 2); % Number of variables
T = size(X, 1); % Number of time observations

% Standardize X by centering and scaling by the standard deviations
W = diag(std(X));          % Standard deviations of each variable
x = center(X)*(W^-1);       % Standardized data matrix

% Compute the sample covariance matrix
Gamma0 = cov(x);

% Compute the rmax largest eigenvalues and eigenvectors
opts.disp = 0; % Suppress eigenvalue solver display
[H, ~] = eigs(Gamma0, rmax, 'LM', opts);

% Initialize the vector for residual variances V(r)
for r = 1:rmax
    % Compute the residual variance after extracting r factors
    I = x*(eye(N) - H(:,1:r)*H(:,1:r)'); % Projection of x orthogonal to the space spanned by first r eigenvectors
    V(r) = sum(sum(I.^2)) / (N*T);        % Residual variance
end

% Define scaling parameter e (used in penalty terms)
e = (N + T) / (N*T);

% Define different penalty terms according to Bai and Ng (2002)
penalty1 = (1:rmax) * e * log(1/e);        % PC1/IC1 penalty
penalty2 = (1:rmax) * e * log(min(N,T));   % PC2/IC2 penalty
penalty3 = (1:rmax) * (log(min(N,T)) / min(N,T)); % PC3/IC3 penalty
penalty4 = (1:rmax) * (log(1/e));          % PC4/IC4 penalty

% Compute the Panel Criteria (PC) for each penalty
% PC are the penalized residual variances
PC = [V + V(rvar)*penalty1; V + V(rvar)*penalty2; V + V(rvar)*penalty3; V + V(rvar)*penalty4]';

% Compute the Information Criteria (IC) for each penalty
% IC are the penalized log-residual variances
IC = [log(V) + penalty1; log(V) + penalty2; log(V) + penalty3; log(V) + penalty4]';

end
