%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SIMULFUN: Simulate and Estimate Factor Models
%
% Purpose:
%   Simulates high-dimensional data from a prespecified factor model DGP and 
%   estimates the number of factors using Sequential Testing and Eigenvalue Ratio 
%   methods. Supports DGPs 1 to 3 as described in the paper.
%
% Inputs:
%   - T: Time-series dimension (scalar)
%   - n: Cross-sectional dimension (scalar)
%   - k0: Parameter for MDDM estimation (scalar)
%   - r: True number of factors to simulate (scalar)
%   - theta: Signal-to-noise ratio parameter type (scalar, 1 to 4)
%       - 1: theta = 0.5*r
%       - 2: theta = r
%       - 3: theta = 3*r
%       - 4: theta = 5*r
%   - DGP: Data Generating Process type (scalar, 1 to 3)
%   - pval: Critical value for sequential testing (scalar)
%   - bootIter: Number of bootstrap replications for sequential testing 
%   - cut: logical value, true in the case we only consider a fraction (one
%     third of n) of the estimated factors in the bootstrap mechanism of the sequential testing procedure. 
%     It decreases computing times drastically at the cost of lowered precision of the factor selection procedure 
%     as detailed in the Appendix.
%
%
% Outputs:
%   - mNfactors: 1x2 vector containing estimated number of factors
%       - mNfactors(1): From Sequential Testing
%       - mNfactors(2): From Eigenvalue Ratio (icstar)
%   - vPvals: Vector of p-values from sequential testing
%
% Dependencies:
%   - BarigozziSim.m: For data simulation
%   - factorMDDM.m: For factor estimation
%   - seqTest.m: For sequential testing
%   - standardize.m: For data standardization
%
% Notes:
%   - Maximum number of factors to estimate using eigenvalue ratio (rmax) is fixed at 10.
%   - Data is standardized before estimation.
%   - Used within Monte Carlo simulations for factor model evaluation.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function[mNfactors,vPvals] = SimulFun(T,n,k0,r,theta,DGP,pval, bootIter, cut) 

mX = factorSim(T,n,r,theta,DGP);
mX = standardize(mX);
rmax = 10;


[~,~,~,~,icstar] = factorMDDM(mX, k0, rmax);
vPvals           = seqTest(mX,bootIter,pval,k0,"radem",cut); %  
vNfactorsK0      = sum(vPvals<=pval);
vNfactorsRatio   = icstar;


mNfactors = [vNfactorsK0,vNfactorsRatio];

end

