% MONTE CARLO SIMULATION FOR FACTOR MODEL ESTIMATION
%
% Purpose:
%   This script generates Table 3 in the paper by simulating factor models 
%   under varying parameters (true number of factors, DGP, signal-to-noise ratio, 
%   and sample sizes) and evaluating factor estimation accuracy using Sequential 
%   Testing and Eigenvalue Ratio methods for n=200, T=100 (upper part) and 
%   n=100, T=200 (lower part).
%
% Key Functionality:
%   - Conducts Monte Carlo simulations with nested loops over:
%     1. Sample sizes (n, T): (200, 100) and (100, 200)
%     2. True number of factors (r)
%     3. Data Generating Process (DGP)
%     4. Signal-to-noise parameter (theta)
%     5. Monte Carlo replications (via SimulFun)
%   - Stores results in tables for export, comparing estimation success rates.
%   - Displays results using disp() to match LaTeX table format.
%   - Exports results to an Excel file matching the LaTeX table structure.
%
% Parameters:
%   - n: Cross-sectional dimension ([200, 100])
%   - T: Time-series dimension ([100, 200])
%   - k0: Parameter for MDDM (default: 1)
%   - pval: Critical value for sequential testing (default: 0.05)
%   - nIters: Number of Monte Carlo replications (default: 1000)
%   - bootIter: Number of bootstrap replications for sequential testing (default 300)
%   - cut: logical value, true in the case we only consider a fraction (one
%     third of n) of the estimated factors in the bootstrap mechanism of the sequential testing procedure. 
%     It decreases computing times drastically at the cost of lowered precision of the factor selection procedure 
%     as detailed in the Appendix.
%
%   - r: True number of factors (2 to 5)
%   - DGP: Data Generating Process (1 to 3)
%   - thetaMethod: Signal-to-noise parameter multiplier
%       (1: 0. 0.5*r, r, 3*r, 5*r)
%
% Outputs:
%   - Console display of empirical probabilities matching Table 3.
%   - Excel file ('Simulation_Results_n200_n100.xlsx') with results for both sample sizes.
%
% Notes:
%   - Requires 'factorEstimation' and 'subfunctions' folders in the MATLAB path.
%   - Random number generator seeded for replicability (rng(1, 'twister')).
%   - Parallelized Monte Carlo loop (parfor) for efficiency.
%   - Matches Table 3: n=200, T=100 (upper part), n=100, T=200 (lower part).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all; clear all; clc;

addpath('../factorEstimation');
addpath('../subfunctionsTAB123')

% Set random number generator for replicability
rng(1, 'twister');

% Parameters
n_values = [200,100]; % Cross-sectional dimension
T_values = [100, 200]; % Time-series dimensions
k0 = 1; 
pval = 0.05; 
nIters = 1000; % Number of Monte Carlo replications (as per LaTeX: 1000)
bootIter = 499;
cut = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%          EXPORTABLE TABLE CREATION COMMANDS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize tables for each sample size
rvar = zeros(12, 1);
dgp = zeros(12, 1);
rx05 = zeros(12, 1);
rx1 = zeros(12, 1);
rx3 = zeros(12, 1);
rx5 = zeros(12, 1);

% Tables for each method and sample size
sequentialTest_n200_T100 = table(rvar, dgp, rx05, rx1, rx3, rx5);
eigenvalueRatio_n200_T100 = table(rvar, dgp, rx05, rx1, rx3, rx5);
sequentialTest_n100_T200 = table(rvar, dgp, rx05, rx1, rx3, rx5);
eigenvalueRatio_n100_T200 = table(rvar, dgp, rx05, rx1, rx3, rx5);

% Combined final table
finalTable = table(sequentialTest_n200_T100, eigenvalueRatio_n200_T100, ...
                   sequentialTest_n100_T200, eigenvalueRatio_n100_T200);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%           MONTE CARLO SIMULATION CODE
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
for nt = 1:length(n_values)
    n = n_values(nt);
    T = T_values(nt);
    disp(['Simulating for n = ', num2str(n), ', T = ', num2str(T)]);
    
    r = 2;
    while r <= 5 % Number of factors
        DGP = 1;
        while DGP <= 3 % DGP from 1 to 3 
            thetaMethod = 1;
            while thetaMethod <= 4 % Theta, the signal-to-noise parameter
                out = NaN(nIters, 2);

                parfor k = 1:nIters % Monte Carlo replications
                    rng_seed_offset = n * 100 + T *1000 + r * 10000 + DGP * 100000 + thetaMethod * 1000000; % Ensure different seed base for each d
                    rng(k + rng_seed_offset, 'twister'); % Set unique seed for each simulation iteration

                    out(k, :) = SimulFun(T, n, k0, r, thetaMethod, DGP, pval, bootIter, cut);
                    disp([k, thetaMethod, DGP, r, n, T]);
                end
                disp(['Mean success rate (r = ', num2str(r), ', DGP = ', num2str(DGP), ...
                      ', thetaMethod = ', num2str(thetaMethod), '): ', ...
                      num2str(mean(out == r))]);
                
                index = (r-2)*3 + DGP;
                
                % Store results based on sample size
                if n == 200 && T == 100
                    finalTable.sequentialTest_n200_T100.rvar(index) = r;
                    finalTable.sequentialTest_n200_T100.dgp(index) = DGP;
                    finalTable.eigenvalueRatio_n200_T100.rvar(index) = r;
                    finalTable.eigenvalueRatio_n200_T100.dgp(index) = DGP;
                    
                    if thetaMethod == 1
                        finalTable.sequentialTest_n200_T100.rx05(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n200_T100.rx05(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 2
                        finalTable.sequentialTest_n200_T100.rx1(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n200_T100.rx1(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 3
                        finalTable.sequentialTest_n200_T100.rx3(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n200_T100.rx3(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 4
                        finalTable.sequentialTest_n200_T100.rx5(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n200_T100.rx5(index) = mean(out(:,2)==r);
                    end
                elseif n == 100 && T == 200
                    finalTable.sequentialTest_n100_T200.rvar(index) = r;
                    finalTable.sequentialTest_n100_T200.dgp(index) = DGP;
                    finalTable.eigenvalueRatio_n100_T200.rvar(index) = r;
                    finalTable.eigenvalueRatio_n100_T200.dgp(index) = DGP;
                    
                    if thetaMethod == 1
                        finalTable.sequentialTest_n100_T200.rx05(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T200.rx05(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 2
                        finalTable.sequentialTest_n100_T200.rx1(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T200.rx1(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 3
                        finalTable.sequentialTest_n100_T200.rx3(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T200.rx3(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 4
                        finalTable.sequentialTest_n100_T200.rx5(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T200.rx5(index) = mean(out(:,2)==r);
                    end
                end
                save
                thetaMethod = thetaMethod + 1;
            end
            DGP = DGP + 1;
        end
        r = r + 1;
    end
end
toc

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%           DISPLAY RESULTS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Display results mimicking LaTeX Table 3
disp('Table 3: Empirical Probability of Estimating the True Number of Factors');
disp('-------------------------------------------------------------');
disp('n = 200, T = 100 (Upper Part)');
disp('-------------------------------------------------------------');
disp('Sequential Test');
fprintf(' r  | DGP/theta |  0.5r  |   r    |  3r    |  5r\n');
for r = 2:5
    for DGP = 1:3
        index = (r-2)*3 + DGP;
        fprintf('%2d | %8s | %.2f | %.2f | %.2f | %.2f\n', ...
                r, ['DGP', num2str(DGP)], ...
                finalTable.sequentialTest_n200_T100.rx05(index), ...
                finalTable.sequentialTest_n200_T100.rx1(index), ...
                finalTable.sequentialTest_n200_T100.rx3(index), ...
                finalTable.sequentialTest_n200_T100.rx5(index));
    end
    if r < 5
        disp('     |           |        |        |        |');
    end
end
disp('-------------------------------------------------------------');
disp('Eigenvalue Ratio');
fprintf(' r  | DGP/theta |  0.5r  |   r    |  3r    |  5r\n');
for r = 2:5
    for DGP = 1:3
        index = (r-2)*3 + DGP;
        fprintf('%2d | %8s | %.2f | %.2f | %.2f | %.2f\n', ...
                r, ['DGP', num2str(DGP)], ...
                finalTable.eigenvalueRatio_n200_T100.rx05(index), ...
                finalTable.eigenvalueRatio_n200_T100.rx1(index), ...
                finalTable.eigenvalueRatio_n200_T100.rx3(index), ...
                finalTable.eigenvalueRatio_n200_T100.rx5(index));
    end
    if r < 5
        disp('     |           |        |        |        |');
    end
end
disp('-------------------------------------------------------------');
disp('n = 100, T = 200 (Lower Part)');
disp('-------------------------------------------------------------');
disp('Sequential Test');
fprintf(' r  | DGP/theta |  0.5r  |   r    |  3r    |  5r\n');
for r = 2:5
    for DGP = 1:3
        index = (r-2)*3 + DGP;
        fprintf('%2d | %8s | %.2f | %.2f | %.2f | %.2f\n', ...
                r, ['DGP', num2str(DGP)], ...
                finalTable.sequentialTest_n100_T200.rx05(index), ...
                finalTable.sequentialTest_n100_T200.rx1(index), ...
                finalTable.sequentialTest_n100_T200.rx3(index), ...
                finalTable.sequentialTest_n100_T200.rx5(index));
    end
    if r < 5
        disp('     |           |        |        |        |');
    end
end
disp('-------------------------------------------------------------');
disp('Eigenvalue Ratio');
fprintf(' r  | DGP/theta |  0.5r  |   r    |  3r    |  5r\n');
for r = 2:5
    for DGP = 1:3
        index = (r-2)*3 + DGP;
        fprintf('%2d | %8s | %.2f | %.2f | %.2f | %.2f\n', ...
                r, ['DGP', num2str(DGP)], ...
                finalTable.eigenvalueRatio_n100_T200.rx05(index), ...
                finalTable.eigenvalueRatio_n100_T200.rx1(index), ...
                finalTable.eigenvalueRatio_n100_T200.rx3(index), ...
                finalTable.eigenvalueRatio_n100_T200.rx5(index));
    end
    if r < 5
        disp('     |           |        |        |        |');
    end
end
disp('-------------------------------------------------------------');

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%           EXCEL TABLE PRODUCTION
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filename = 'Simulation_Results_n200_n100.xlsx';
sheet = 'Table3';

% Headers
headers = {'', '', 'Sequential Test', '', '', '', '', 'Eigenvalue Ratio', '', '', ''};
subheaders = {'r', 'DGP/theta', '0.5r', 'r', '3r', '5r', '', '0.5r', 'r', '3r', '5r'};

% Write headers for n=200, T=100 (Upper Part)
writecell({'n=200, T=100'}, filename, 'Sheet', sheet, 'Range', 'A1');
writecell(headers, filename, 'Sheet', sheet, 'Range', 'A3');
writecell(subheaders, filename, 'Sheet', sheet, 'Range', 'A4');

% Write data for n=200, T=100
r_values = [2, 3, 4, 5];
dgp_labels = {'DGP1', 'DGP2', 'DGP3'};
row_start = 5;
for i = 1:length(r_values)
    r = r_values(i);
    for j = 1:length(dgp_labels)
        dgp = dgp_labels{j};
        row = row_start + (i-1)*4 + (j-1);
        index = (r-2)*3 + j;
        
        % Extract data
        seq_data = [finalTable.sequentialTest_n200_T100.rx05(index), ...
                    finalTable.sequentialTest_n200_T100.rx1(index), ...
                    finalTable.sequentialTest_n200_T100.rx3(index), ...
                    finalTable.sequentialTest_n200_T100.rx5(index)];
        eigen_data = [finalTable.eigenvalueRatio_n200_T100.rx05(index), ...
                      finalTable.eigenvalueRatio_n200_T100.rx1(index), ...
                      finalTable.eigenvalueRatio_n200_T100.rx3(index), ...
                      finalTable.eigenvalueRatio_n200_T100.rx5(index)];
        
        % Round to 2 decimals
        seq_data = round(seq_data, 2);
        eigen_data = round(eigen_data, 2);
        
        % Convert to strings with exactly 2 decimal places
        seq_data_str = arrayfun(@(x) sprintf('%.2f', x), seq_data, 'UniformOutput', false);
        eigen_data_str = arrayfun(@(x) sprintf('%.2f', x), eigen_data, 'UniformOutput', false);
        
        % Write to Excel
        writecell({r}, filename, 'Sheet', sheet, 'Range', sprintf('A%d', row));
        writecell({dgp}, filename, 'Sheet', sheet, 'Range', sprintf('B%d', row));
        writecell(seq_data_str, filename, 'Sheet', sheet, 'Range', sprintf('C%d', row));
        writecell(eigen_data_str, filename, 'Sheet', sheet, 'Range', sprintf('I%d', row));
    end
    row_start = row_start + 1; % Add empty row between r values
end

% Write headers for n=100, T=200 (Lower Part)
% Upper part ends at row 19, add a 5-row gap
row_start = 19 + 5; % Start at row 24
writecell({'n=100, T=200'}, filename, 'Sheet', sheet, 'Range', sprintf('A%d', row_start));
writecell(headers, filename, 'Sheet', sheet, 'Range', sprintf('A%d', row_start + 2));
writecell(subheaders, filename, 'Sheet', sheet, 'Range', sprintf('A%d', row_start + 3));

% Write data for n=100, T=200 (same structure as upper part)
row_start = row_start + 4; % Data starts at row 28
for i = 1:length(r_values)
    r = r_values(i);
    for j = 1:length(dgp_labels)
        dgp = dgp_labels{j};
        row = row_start + (i-1)*4 + (j-1);
        index = (r-2)*3 + j;
        
        % Extract data
        seq_data = [finalTable.sequentialTest_n100_T200.rx05(index), ...
                    finalTable.sequentialTest_n100_T200.rx1(index), ...
                    finalTable.sequentialTest_n100_T200.rx3(index), ...
                    finalTable.sequentialTest_n100_T200.rx5(index)];
        eigen_data = [finalTable.eigenvalueRatio_n100_T200.rx05(index), ...
                      finalTable.eigenvalueRatio_n100_T200.rx1(index), ...
                      finalTable.eigenvalueRatio_n100_T200.rx3(index), ...
                      finalTable.eigenvalueRatio_n100_T200.rx5(index)];
        
        % Round to 2 decimals
        seq_data = round(seq_data, 2);
        eigen_data = round(eigen_data, 2);
        
        % Convert to strings with exactly 2 decimal places
        seq_data_str = arrayfun(@(x) sprintf('%.2f', x), seq_data, 'UniformOutput', false);
        eigen_data_str = arrayfun(@(x) sprintf('%.2f', x), eigen_data, 'UniformOutput', false);
        
        % Write to Excel
        writecell({r}, filename, 'Sheet', sheet, 'Range', sprintf('A%d', row));
        writecell({dgp}, filename, 'Sheet', sheet, 'Range', sprintf('B%d', row));
        writecell(seq_data_str, filename, 'Sheet', sheet, 'Range', sprintf('C%d', row));
        writecell(eigen_data_str, filename, 'Sheet', sheet, 'Range', sprintf('I%d', row));
    end
    row_start = row_start + 1; % Add empty row between r values
end

disp('Results saved to Simulation_Results.xlsx');