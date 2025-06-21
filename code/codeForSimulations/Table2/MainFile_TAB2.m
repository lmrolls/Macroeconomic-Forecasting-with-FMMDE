% MONTE CARLO SIMULATION FOR FACTOR MODEL ESTIMATION
%
% Purpose:
%   This script generates Table 2 in the paper by simulating factor models 
%   under varying parameters (true number of factors, DGP, signal-to-noise ratio, 
%   and sample sizes) and evaluating factor estimation accuracy using Sequential 
%   Testing and Eigenvalue Ratio methods for n=100, T=50 and n=100, T=100.
%
% Key Functionality:
%   - Conducts Monte Carlo simulations with nested loops over:
%     1. Sample sizes (n, T): (100, 50) and (100, 100)
%     2. True number of factors (r)
%     3. Data Generating Process (DGP)
%     4. Signal-to-noise parameter (theta)
%     5. Monte Carlo replications (via SimulFun)
%   - Stores results in tables for export, comparing estimation success rates.
%   - Displays results using disp() to match LaTeX table format.
%   - Exports results to an Excel file matching the LaTeX table structure.
%
% Parameters:
%   - n: Cross-sectional dimension ([100])
%   - T: Time-series dimension ([50, 100])
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
%       (1: 0.5*r, 2: r, 3: 3*r, 4: 5*r)
%
% Outputs:
%   - Console display of empirical probabilities matching Table 2.
%   - Excel file ('Simulation_Results_n100.xlsx') with results for both sample sizes.
%
% Notes:
%   - Requires 'factorEstimation' and 'subfunctions' folders in the MATLAB path.
%   - Random number generator seeded for replicability (rng(1, 'twister')).
%   - Parallelized Monte Carlo loop (parfor) for efficiency.
%   - Matches Table 2: n=100, T=50 (upper part), n=100, T=100 (lower part).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all; clear all; clc;

addpath('../factorEstimation');
addpath('../subfunctionsTAB123')

% Set random number generator for replicability
rng(1, 'twister');

% Parameters
n_values = [100,100]; % Cross-sectional dimension
T_values = [50, 100]; % Time-series dimensions
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
sequentialTest_n100_T50 = table(rvar, dgp, rx05, rx1, rx3, rx5);
eigenvalueRatio_n100_T50 = table(rvar, dgp, rx05, rx1, rx3, rx5);
sequentialTest_n100_T100 = table(rvar, dgp, rx05, rx1, rx3, rx5);
eigenvalueRatio_n100_T100 = table(rvar, dgp, rx05, rx1, rx3, rx5);

% Combined final table
finalTable = table(sequentialTest_n100_T50, eigenvalueRatio_n100_T50, ...
                   sequentialTest_n100_T100, eigenvalueRatio_n100_T100);

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
                   %disp([k, thetaMethod, DGP, r, n, T]);
                end
                disp(['Mean success rate (r = ', num2str(r), ', DGP = ', num2str(DGP), ...
                      ', thetaMethod = ', num2str(thetaMethod), '): ', ...
                      num2str(mean(out == r))]);
                
                index = (r-2)*3 + DGP;
                
                % Store results based on sample size
                if n == 100 && T == 50
                    finalTable.sequentialTest_n100_T50.rvar(index) = r;
                    finalTable.sequentialTest_n100_T50.dgp(index) = DGP;
                    finalTable.eigenvalueRatio_n100_T50.rvar(index) = r;
                    finalTable.eigenvalueRatio_n100_T50.dgp(index) = DGP;
                    
                    if thetaMethod == 1
                        finalTable.sequentialTest_n100_T50.rx05(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T50.rx05(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 2
                        finalTable.sequentialTest_n100_T50.rx1(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T50.rx1(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 3
                        finalTable.sequentialTest_n100_T50.rx3(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T50.rx3(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 4
                        finalTable.sequentialTest_n100_T50.rx5(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T50.rx5(index) = mean(out(:,2)==r);
                    end
                elseif n == 100 && T == 100
                    finalTable.sequentialTest_n100_T100.rvar(index) = r;
                    finalTable.sequentialTest_n100_T100.dgp(index) = DGP;
                    finalTable.eigenvalueRatio_n100_T100.rvar(index) = r;
                    finalTable.eigenvalueRatio_n100_T100.dgp(index) = DGP;
                    
                    if thetaMethod == 1
                        finalTable.sequentialTest_n100_T100.rx05(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T100.rx05(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 2
                        finalTable.sequentialTest_n100_T100.rx1(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T100.rx1(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 3
                        finalTable.sequentialTest_n100_T100.rx3(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T100.rx3(index) = mean(out(:,2)==r);
                    elseif thetaMethod == 4
                        finalTable.sequentialTest_n100_T100.rx5(index) = mean(out(:,1)==r);
                        finalTable.eigenvalueRatio_n100_T100.rx5(index) = mean(out(:,2)==r);
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

% Display results mimicking LaTeX Table 2
disp('Table 2: Empirical Probability of Estimating the True Number of Factors');
disp('-------------------------------------------------------------');
disp('n = 100, T = 50 (Upper Part)');
disp('-------------------------------------------------------------');
disp('Sequential Test');
fprintf(' r  | DGP/theta |  0.5r  |   r    |  3r    |  5r\n');
for r = 2:5
    for DGP = 1:3
        index = (r-2)*3 + DGP;
        fprintf('%2d | %8s | %.2f | %.2f | %.2f | %.2f\n', ...
                r, ['DGP', num2str(DGP)], ...
                finalTable.sequentialTest_n100_T50.rx05(index), ...
                finalTable.sequentialTest_n100_T50.rx1(index), ...
                finalTable.sequentialTest_n100_T50.rx3(index), ...
                finalTable.sequentialTest_n100_T50.rx5(index));
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
                finalTable.eigenvalueRatio_n100_T50.rx05(index), ...
                finalTable.eigenvalueRatio_n100_T50.rx1(index), ...
                finalTable.eigenvalueRatio_n100_T50.rx3(index), ...
                finalTable.eigenvalueRatio_n100_T50.rx5(index));
    end
    if r < 5
        disp('     |           |        |        |        |');
    end
end
disp('-------------------------------------------------------------');
disp('n = 100, T = 100 (Lower Part)');
disp('-------------------------------------------------------------');
disp('Sequential Test');
fprintf(' r  | DGP/theta |  0.5r  |   r    |  3r    |  5r\n');
for r = 2:5
    for DGP = 1:3
        index = (r-2)*3 + DGP;
        fprintf('%2d | %8s | %.2f | %.2f | %.2f | %.2f\n', ...
                r, ['DGP', num2str(DGP)], ...
                finalTable.sequentialTest_n100_T100.rx05(index), ...
                finalTable.sequentialTest_n100_T100.rx1(index), ...
                finalTable.sequentialTest_n100_T100.rx3(index), ...
                finalTable.sequentialTest_n100_T100.rx5(index));
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
                finalTable.eigenvalueRatio_n100_T100.rx05(index), ...
                finalTable.eigenvalueRatio_n100_T100.rx1(index), ...
                finalTable.eigenvalueRatio_n100_T100.rx3(index), ...
                finalTable.eigenvalueRatio_n100_T100.rx5(index));
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

filename = 'Simulation_ResultsTAB2.xlsx';
sheet = 'Table2';

% Headers
headers = {'', '', 'Sequential Test', '', '', '', '', 'Eigenvalue Ratio', '', '', ''};
subheaders = {'r', 'DGP/theta', '0.5r', 'r', '3r', '5r', '', '0.5r', 'r', '3r', '5r'};

% Write headers for n=100, T=50 (Upper Part)
writecell({'n=100, T=50'}, filename, 'Sheet', sheet, 'Range', 'A1');
writecell(headers, filename, 'Sheet', sheet, 'Range', 'A3');
writecell(subheaders, filename, 'Sheet', sheet, 'Range', 'A4');

% Write data for n=100, T=50
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
        seq_data = [finalTable.sequentialTest_n100_T50.rx05(index), ...
                    finalTable.sequentialTest_n100_T50.rx1(index), ...
                    finalTable.sequentialTest_n100_T50.rx3(index), ...
                    finalTable.sequentialTest_n100_T50.rx5(index)];
        eigen_data = [finalTable.eigenvalueRatio_n100_T50.rx05(index), ...
                      finalTable.eigenvalueRatio_n100_T50.rx1(index), ...
                      finalTable.eigenvalueRatio_n100_T50.rx3(index), ...
                      finalTable.eigenvalueRatio_n100_T50.rx5(index)];
        
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

% Write headers for n=100, T=100 (Lower Part)
% Upper part ends at row 19, add a 5-row gap
row_start = 19 + 5; % Start at row 24
writecell({'n=100, T=100'}, filename, 'Sheet', sheet, 'Range', sprintf('A%d', row_start));
writecell(headers, filename, 'Sheet', sheet, 'Range', sprintf('A%d', row_start + 2));
writecell(subheaders, filename, 'Sheet', sheet, 'Range', sprintf('A%d', row_start + 3));

% Write data for n=100, T=100 (same structure as upper part)
row_start = row_start + 4; % Data starts at row 28
for i = 1:length(r_values)
    r = r_values(i);
    for j = 1:length(dgp_labels)
        dgp = dgp_labels{j};
        row = row_start + (i-1)*4 + (j-1);
        index = (r-2)*3 + j;
        
        % Extract data
        seq_data = [finalTable.sequentialTest_n100_T100.rx05(index), ...
                    finalTable.sequentialTest_n100_T100.rx1(index), ...
                    finalTable.sequentialTest_n100_T100.rx3(index), ...
                    finalTable.sequentialTest_n100_T100.rx5(index)];
        eigen_data = [finalTable.eigenvalueRatio_n100_T100.rx05(index), ...
                      finalTable.eigenvalueRatio_n100_T100.rx1(index), ...
                      finalTable.eigenvalueRatio_n100_T100.rx3(index), ...
                      finalTable.eigenvalueRatio_n100_T100.rx5(index)];
        
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

disp('Results saved to Simulation_ResultsTAB2.xlsx');

%%

% =================================================================
% 3. GENERATE THE COMPLETE, WRAPPED LATEX TABLE (Final Header Alignment)
% =================================================================

% This script generates the complete, wrapped LaTeX table for Table 2.
fprintf('Simulations for Table 2 finished. Generating LaTeX code...\n');

% Define Parameters and Open File
filename_latex = 'table2_final_version.tex';
fid = fopen(filename_latex, 'w');

r_values = 2:5;
dgp_values = 1:3;

% Write the LaTeX Table Wrapper and Headers
fprintf(fid, '%% This complete table environment was automatically generated by MATLAB\n\n');
fprintf(fid, '\\begin{table}[htbp]\n');
fprintf(fid, '  \\centering\n');
fprintf(fid, '  \\caption{Empirical probability of estimating the true number of factors for n=100, T=50 (upper) and T=100 (lower).}\n');
fprintf(fid, '  \\label{tab:full_simulation_table_2}\n');
fprintf(fid, '  \\scalebox{0.7}{\n');
fprintf(fid, '    \\begin{tabular}{cc|ccccccc|cccccc|}\n');
fprintf(fid, '    \\cmidrule{3-15}\n');
fprintf(fid, '    & & & & \\multicolumn{4}{c}{\\textbf{Sequential Test}} & & & \\multicolumn{4}{c}{\\textbf{Eigenvalue Ratio}} & \\\\\n');
fprintf(fid, '    \\cmidrule{5-8}\\cmidrule{11-14}\n');
fprintf(fid, '    \\diagbox{$r$}{$\\theta$} & & & & \\multicolumn{1}{l}{$0.5r$} & \\multicolumn{1}{l}{$r$} & \\multicolumn{1}{l}{$3r$} & \\multicolumn{1}{l}{      $5r$} & & & \\multicolumn{1}{l}{$0.5r$} & \\multicolumn{1}{l}{$r$} & \\multicolumn{1}{l}{$3r$} & \\multicolumn{1}{l}{      $5r$} & \\\\\n');
fprintf(fid, '    \\hline \\hline\n');

% Generate the Upper Part of the Table (n=100, T=50)
results_seq_upper = finalTable.sequentialTest_n100_T50;
results_eigen_upper = finalTable.eigenvalueRatio_n100_T50;
write_table_part_final_aligned(fid, r_values, dgp_values, results_seq_upper, results_eigen_upper);

% Write the Separator Between the Two Parts
fprintf(fid, '    \\cmidrule{3-15}\n');
fprintf(fid, '    & & & & & & & & & & & & & & \\\\\n');

% Generate the Lower Part of the Table (n=100, T=100)
results_seq_lower = finalTable.sequentialTest_n100_T100;
results_eigen_lower = finalTable.eigenvalueRatio_n100_T100;
write_table_part_final_aligned(fid, r_values, dgp_values, results_seq_lower, results_eigen_lower);

% Write the Final LaTeX Footer
fprintf(fid, '    \\cmidrule{3-15}\n');
fprintf(fid, '    \\end{tabular}\n');
fprintf(fid, '  } %% End of scalebox\n');
fprintf(fid, '\\end{table}\n');
fclose(fid);

fprintf('Success! Final LaTeX table for Table 2 saved to %s\n', filename_latex);


% Helper function to write one part of the table
function write_table_part_final_aligned(fid, r_values, dgp_values, results_seq, results_eigen)
    index = 1;
    for r_idx = 1:length(r_values)
        r = r_values(r_idx);
        for dgp_idx = 1:length(dgp_values)
            dgp = dgp_values(dgp_idx);
            seq_data = [results_seq.rx05(index), results_seq.rx1(index), results_seq.rx3(index), results_seq.rx5(index)];
            eigen_data = [results_eigen.rx05(index), results_eigen.rx1(index), results_eigen.rx3(index), results_eigen.rx5(index)];
            if dgp_idx == 1
                fprintf(fid, '    \\multicolumn{2}{c|}{\\multirow{3}{*}{%d}} & ', r);
            else
                fprintf(fid, '    \\multicolumn{2}{c|}{} & ');
            end
            fprintf(fid, '\\multicolumn{1}{l}{$DGP_{%d}$} & & ', dgp);
            fprintf(fid, '\\multicolumn{1}{c}{%.2f} & \\multicolumn{1}{c}{%.2f} & \\multicolumn{1}{c}{%.2f} & \\multicolumn{1}{c}{%.2f} & & ', seq_data);
            fprintf(fid, '& \\multicolumn{1}{c}{%.2f} & \\multicolumn{1}{c}{%.2f} & \\multicolumn{1}{c}{%.2f} & \\multicolumn{1}{c}{%.2f} & \\\\\n', eigen_data);
            index = index + 1;
        end
        if r_idx < length(r_values)
            fprintf(fid, '    & & & & & & & & & & & & & & \\\\\n');
        end
    end
end