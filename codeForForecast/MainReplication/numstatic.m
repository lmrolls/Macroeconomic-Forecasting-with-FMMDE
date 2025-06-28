function r = numstatic(x,rmax,static)
% This function selects the number of static factors in a dataset
% using either a fixed number or a model selection criterion.
%
% References:
% - Bai, J., and Ng, S. (2002). "Determining the Number of Factors in 
%   Approximate Factor Models." *Econometrica*, 70(1), 191–221.
% - Onatski, A. (2010). "Determining the Number of Factors from 
%   Empirical Distribution of Eigenvalues." *The Review of Economics and Statistics*, 92(4), 1004–1016.
%
% Inputs:
%   x      - Data matrix (T observations x N variables)
%   rmax   - Maximum number of factors to consider
%   static - Selection method ('baing' for Bai-Ng criterion or a fixed number)
%
% Output:
%   r      - Selected number of static factors
    if strcmp(static,'baing')
        [~, IC] = baingcriterion2002(x, rmax); % Compute Bai-Ng information criteria
        [~, r]  = min(IC(:,2)); % Select the number of factors that minimizes the second information criterion
    elseif isnumeric(static)
        r = static; % Use the fixed number of factors provided
    end

end

