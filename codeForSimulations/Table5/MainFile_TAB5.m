% mainFile_TAB5_Unified - Evaluate Forecasting Performance of Factor Models for Linear and Nonlinear Factors
%
% Purpose: Evaluate the out-of-sample one-step-ahead predictive performance of three factor
% estimation methods: FMMDE (Factor Model Maximum Distance Estimator), SW (Stock-Watson 2002),
% and LYB (Lam-Yao-Bathia) using simulated data from both linear and nonlinear factor models.
%
% Parameters:
% - NN_start: Cross-sectional dimensions (N = [100, 300, 500])
% - TT_start: Time-series dimensions (T = [200, 500, 1000])
% - rr: True number of factors (rr = 3)
% - nreps: Number of Monte Carlo replications (1000)
%
% Methodology:
% - Simulated data X_t (N-dimensional) are generated from a 3-dimensional factor model:
%   - Linear factors: Using fLeeShao(T,N,rr) (Eq. 5 in Lee & Shao, 2018).
%   - Nonlinear factors: Using fLeeShaoNonLinear(T,N) (Eq. 3 in Lee & Shao, 2018).
% - Factors F^{m}_t (3-dimensional) are estimated from X_t using methods m = {FMMDE, SW, LYB}.
% - For each variable X_{t,k} (k=1,...,N), forecast X_{t+1,k} using:
%     X_{t+1,k} = beta*F^{m}_t + epsi_t, where beta is estimated via OLS.
% - Compute the mean squared forecast error (MSFE) for each method by averaging squared
%   forecast errors across N variables per replication.
% - Calculate MSFE ratios: MSFE^{FMMDE}/MSFE^{m} (m = SW, LYB) for both linear and nonlinear
%   factor models.
% - Average the MSFE ratios over 1000 Monte Carlo replications.
%
% Dependencies:
% - fLeeShao(): Generates data from the 3-factor linear model (Eq. 5 in Lee & Shao, 2018).
% - fLeeShaoNonLinear(): Generates data from the 3-factor nonlinear model (Eq. 3 in Lee & Shao, 2018).
% - stockwatson2002(): Estimates factors using Stock-Watson (2002).
% - fixedFactorsMDDM(): Estimates factors using FMMDE for a prespecified number of factors.
% - fixedFactorLAM(): Estimates factors using LYB for a prespecified number of factors.
% - standardize(): Standardizes the input data.
%
% Output: Matrices of averaged MSFE ratios (MSFE^{FMMDE}/MSFE^{SW}, MSFE^{FMMDE}/MSFE^{LYB})
% for each (N,T) combination, for both linear and nonlinear factor models, formatted to match
% Table 5 in the paper.
%
% References:
% - Lee, E., & Shao, X. (2018). Martingale Difference Divergence Matrix and Its Application
%   to Dimension Reduction for Stationary Multivariate Time Series. Journal of the American
%   Statistical Association, 113(521), 216–229. DOI: 10.1080/01621459.2016.1240082
% - Stock, J. H., & Watson, M. W. (2002). Forecasting Using Principal Components from a Large
%   Number of Predictors. Journal of the American Statistical Association, 97(460), 1167–1179.
% - Lam, C., Yao, Q., & Bathia, N. (2011). Estimation of Latent Factors for High-Dimensional
%   Time Series. Biometrika, 98(4), 901–918. DOI: 10.1093/biomet/asr047
%
% Notes:
% - The script assumes all dependencies are in the specified paths ('../factorEstimation', '../DGPs', 'subfunctions').
% - The number of replications is set to 1000 to match the table description.
% - Results are displayed in a format suitable for direct comparison with Table 5.
%%#########################################################################################

close all; clear all; clc;

addpath('../factorEstimation');
addpath('../DGPs');
addpath('subfunctions');

% Set random number generator for replicability
rng(1);

% Parameters
NN_start = [100 300 500]; % Cross-sectional dimensions
TT_start = [200 500 1000]; % Time-series dimensions
rr = 3; % Number of factors
nreps = 1000; % Number of Monte Carlo replications
k0 = 1;

% Initialize cell arrays for MSE storage (Linear and Nonlinear)
mse_cla_sw_lin = cell(length(NN_start), length(TT_start));
mse_cla_md_lin = cell(length(NN_start), length(TT_start));
mse_cla_lam_lin = cell(length(NN_start), length(TT_start));
mse_cla_sw_nonlin = cell(length(NN_start), length(TT_start));
mse_cla_md_nonlin = cell(length(NN_start), length(TT_start));
mse_cla_lam_nonlin = cell(length(NN_start), length(TT_start));

% Initialize matrices for average MSE (Linear and Nonlinear)
GM_mse_sw_lin = zeros(length(NN_start), length(TT_start));
GM_mse_md_lin = zeros(length(NN_start), length(TT_start));
GM_mse_lam_lin = zeros(length(NN_start), length(TT_start));
GM_mse_sw_nonlin = zeros(length(NN_start), length(TT_start));
GM_mse_md_nonlin = zeros(length(NN_start), length(TT_start));
GM_mse_lam_nonlin = zeros(length(NN_start), length(TT_start));

for TT = 1:length(TT_start)
    T = TT_start(TT);
    disp(['T = ', num2str(T)]);
    for NN = 1:length(NN_start)
        N = NN_start(NN);
        disp(['N = ', num2str(N)]);
        
        % Pre-allocate arrays for forecasts and true values
        yfor_sw_lin = zeros(nreps, N);
        yfor_md_lin = zeros(nreps, N);
        yfor_lam_lin = zeros(nreps, N);
        ytrue_lin = zeros(nreps, N);
        yfor_sw_nonlin = zeros(nreps, N);
        yfor_md_nonlin = zeros(nreps, N);
        yfor_lam_nonlin = zeros(nreps, N);
        ytrue_nonlin = zeros(nreps, N);
        
        parfor rep = 1:nreps
            %disp(['Replication ', num2str(rep)]);
            rng_seed_offset = rep + TT * 10000 + NN * 100000;
            rng(rng_seed_offset, 'twister');
            
            % Disable rank-deficient matrix warning
            warning('off', 'MATLAB:rankDeficientMatrix');

            % LINEAR FACTOR DATA GENERATION
            x_lin = fLeeShao(T, N, rr);
            x_lin = standardize(x_lin);
            Xt_lin = x_lin(1:end-1, :); % X_t
            Xout_lin = x_lin(end, :); % X_{t+1}

            % NONLINEAR FACTOR DATA GENERATION
            x_nonlin = fLeeShaoNonLinear(T, N);
            x_nonlin = standardize(x_nonlin);
            Xt_nonlin = x_nonlin(1:end-1, :); % X_t
            Xout_nonlin = x_nonlin(end, :); % X_{t+1}

            % FACTOR ESTIMATION (Linear)
            [Fmddm_lin] = fixedFactorsMDDM(Xt_lin, k0, rr); % FMMDE
            [Fsw_lin] = stockwatson2002(Xt_lin, rr); % SW
            [Flam_lin] = fixedFactorLAM(Xt_lin, k0, rr); % LYB

            % FACTOR ESTIMATION (Nonlinear)
            [Fmddm_nonlin] = fixedFactorsMDDM(Xt_nonlin, k0, rr); % FMMDE
            [Fsw_nonlin] = stockwatson2002(Xt_nonlin, rr); % SW
            [Flam_nonlin] = fixedFactorLAM(Xt_nonlin, k0, rr); % LYB

            for k = 1:N
                % Linear Factors
                yt_lin = Xt_lin(:, k);
                ytout_lin = Xout_lin(:, k);
                ysub_lin = yt_lin(2:end, 1);

                % Nonlinear Factors
                yt_nonlin = Xt_nonlin(:, k);
                ytout_nonlin = Xout_nonlin(:, k);
                ysub_nonlin = yt_nonlin(2:end, 1);

                % Lagged Factors (F_{t-1})
                Fswsub_lin = Fsw_lin(1:end-1, :);
                Fmdsub_lin = Fmddm_lin(1:end-1, :);
                Flamsub_lin = Flam_lin(1:end-1, :);
                Fswsub_nonlin = Fsw_nonlin(1:end-1, :);
                Fmdsub_nonlin = Fmddm_nonlin(1:end-1, :);
                Flamsub_nonlin = Flam_nonlin(1:end-1, :);

                % Factors at time t (F_t)
                Fsfor_lin = Fsw_lin(end, :);
                Fmdfor_lin = Fmddm_lin(end, :);
                Flamfor_lin = Flam_lin(end, :);
                Fsfor_nonlin = Fsw_nonlin(end, :);
                Fmdfor_nonlin = Fmddm_nonlin(end, :);
                Flamfor_nonlin = Flam_nonlin(end, :);

                % OLS ESTIMATION (Linear)
                b_hat_sw_lin = Fswsub_lin\ysub_lin;
                yfor_sw_lin(rep, k) = Fsfor_lin*b_hat_sw_lin;
                b_hat_md_lin = Fmdsub_lin\ysub_lin;
                yfor_md_lin(rep, k) = Fmdfor_lin*b_hat_md_lin;
                b_hat_lam_lin = Flamsub_lin\ysub_lin;
                yfor_lam_lin(rep, k) = Flamfor_lin*b_hat_lam_lin;
                ytrue_lin(rep, k) = ytout_lin;

                % OLS ESTIMATION (Nonlinear)
                b_hat_sw_nonlin = Fswsub_nonlin\ysub_nonlin;
                yfor_sw_nonlin(rep, k) = Fsfor_nonlin*b_hat_sw_nonlin;
                b_hat_md_nonlin = Fmdsub_nonlin\ysub_nonlin;
                yfor_md_nonlin(rep, k) = Fmdfor_nonlin*b_hat_md_nonlin;
                b_hat_lam_nonlin = Flamsub_nonlin\ysub_nonlin;
                yfor_lam_nonlin(rep, k) = Flamfor_nonlin*b_hat_lam_nonlin;
                ytrue_nonlin(rep, k) = ytout_nonlin;
            end
        end

        % MSE COMPUTATION (outside parfor)
        mse_cla_sw_lin{NN,TT} = mean((ytrue_lin - yfor_sw_lin).^2, 2);
        mse_cla_md_lin{NN,TT} = mean((ytrue_lin - yfor_md_lin).^2, 2);
        mse_cla_lam_lin{NN,TT} = mean((ytrue_lin - yfor_lam_lin).^2, 2);
        mse_cla_sw_nonlin{NN,TT} = mean((ytrue_nonlin - yfor_sw_nonlin).^2, 2);
        mse_cla_md_nonlin{NN,TT} = mean((ytrue_nonlin - yfor_md_nonlin).^2, 2);
        mse_cla_lam_nonlin{NN,TT} = mean((ytrue_nonlin - yfor_lam_nonlin).^2, 2);

        % Average MSE across replications
        GM_mse_sw_lin(NN,TT) = mean(mse_cla_sw_lin{NN,TT});
        GM_mse_md_lin(NN,TT) = mean(mse_cla_md_lin{NN,TT});
        GM_mse_lam_lin(NN,TT) = mean(mse_cla_lam_lin{NN,TT});
        GM_mse_sw_nonlin(NN,TT) = mean(mse_cla_sw_nonlin{NN,TT});
        GM_mse_md_nonlin(NN,TT) = mean(mse_cla_md_nonlin{NN,TT});
        GM_mse_lam_nonlin(NN,TT) = mean(mse_cla_lam_nonlin{NN,TT});
    end
end

% Compute MSFE ratios
rMSFE_SW_lin = GM_mse_md_lin ./ GM_mse_sw_lin;
rMSFE_LYB_lin = GM_mse_md_lin ./ GM_mse_lam_lin;
rMSFE_SW_nonlin = GM_mse_md_nonlin ./ GM_mse_sw_nonlin;
rMSFE_LYB_nonlin = GM_mse_md_nonlin ./ GM_mse_lam_nonlin;

%%

% Display results in table format
disp('Table 5: Ratio of Average MSFE (FMMDE / SW and LYB) for Linear and Nonlinear Factors');
disp('-------------------------------------------------------------');
disp('SW Model');
disp('Linear Factors:');
fprintf('     N \\ T    |  200    500    1000\n');
for NN = 1:length(NN_start)
    fprintf('    %3d       | %.3f  %.3f  %.3f\n', NN_start(NN), rMSFE_SW_lin(NN, :));
end
disp('Nonlinear Factors:');
fprintf('     N \\ T    |  200    500    1000\n');
for NN = 1:length(NN_start)
    fprintf('    %3d       | %.3f  %.3f  %.3f\n', NN_start(NN), rMSFE_SW_nonlin(NN, :));
end
disp('-------------------------------------------------------------');
disp('LYB Model');
disp('Linear Factors:');
fprintf('     N \\ T    |  200    500    1000\n');
for NN = 1:length(NN_start)
    fprintf('    %3d       | %.3f  %.3f  %.3f\n', NN_start(NN), rMSFE_LYB_lin(NN, :));
end
disp('Nonlinear Factors:');
fprintf('     N \\ T    |  200    500    1000\n');
for NN = 1:length(NN_start)
    fprintf('    %3d       | %.3f  %.3f  %.3f\n', NN_start(NN), rMSFE_LYB_nonlin(NN, :));
end
disp('-------------------------------------------------------------');

% Re-enable warning (optional)
warning('on', 'MATLAB:rankDeficientMatrix');

%%

% Prepare data for Excel output mimicking LaTeX table horizontal structure
% Create a table with two main columns (SW, LYB), each with Linear and Nonlinear sub-columns
excel_data = cell(5, 13); % 5 rows (header + 3 N values + sub-header) x 13 columns (N + 2 models x 2 factor types x 3 T values)

% Header row
excel_data{1, 1} = '';
excel_data{1, 2} = 'SW Model';
excel_data{1, 5} = '';
excel_data{1, 8} = 'LYB Model';
excel_data{1, 11} = '';

% Sub-header row (Linear and Nonlinear)
excel_data{2, 1} = 'N';
excel_data{2, 2} = 'Linear Factors';
excel_data{2, 5} = 'Nonlinear Factors';
excel_data{2, 8} = 'Linear Factors';
excel_data{2, 11} = 'Nonlinear Factors';

% T-value headers
excel_data{3, 1} = '';
excel_data{3, 2} = 'T=200';
excel_data{3, 3} = 'T=500';
excel_data{3, 4} = 'T=1000';
excel_data{3, 5} = 'T=200';
excel_data{3, 6} = 'T=500';
excel_data{3, 7} = 'T=1000';
excel_data{3, 8} = 'T=200';
excel_data{3, 9} = 'T=500';
excel_data{3, 10} = 'T=1000';
excel_data{3, 11} = 'T=200';
excel_data{3, 12} = 'T=500';
excel_data{3, 13} = 'T=1000';

% Data rows for N = 100, 300, 500
for NN = 1:length(NN_start)
    excel_data{3+NN, 1} = NN_start(NN);
    % SW Model - Linear
    excel_data{3+NN, 2} = sprintf('%.3f', rMSFE_SW_lin(NN, 1));
    excel_data{3+NN, 3} = sprintf('%.3f', rMSFE_SW_lin(NN, 2));
    excel_data{3+NN, 4} = sprintf('%.3f', rMSFE_SW_lin(NN, 3));
    % SW Model - Nonlinear
    excel_data{3+NN, 5} = sprintf('%.3f', rMSFE_SW_nonlin(NN, 1));
    excel_data{3+NN, 6} = sprintf('%.3f', rMSFE_SW_nonlin(NN, 2));
    excel_data{3+NN, 7} = sprintf('%.3f', rMSFE_SW_nonlin(NN, 3));
    % LYB Model - Linear
    excel_data{3+NN, 8} = sprintf('%.3f', rMSFE_LYB_lin(NN, 1));
    excel_data{3+NN, 9} = sprintf('%.3f', rMSFE_LYB_lin(NN, 2));
    excel_data{3+NN, 10} = sprintf('%.3f', rMSFE_LYB_lin(NN, 3));
    % LYB Model - Nonlinear
    excel_data{3+NN, 11} = sprintf('%.3f', rMSFE_LYB_nonlin(NN, 1));
    excel_data{3+NN, 12} = sprintf('%.3f', rMSFE_LYB_nonlin(NN, 2));
    excel_data{3+NN, 13} = sprintf('%.3f', rMSFE_LYB_nonlin(NN, 3));
end

% Convert cell array to table for Excel
excel_table = cell2table(excel_data, 'VariableNames', {'N', 'SW_Linear_T200', 'SW_Linear_T500', 'SW_Linear_T1000', ...
    'SW_Nonlinear_T200', 'SW_Nonlinear_T500', 'SW_Nonlinear_T1000', ...
    'LYB_Linear_T200', 'LYB_Linear_T500', 'LYB_Linear_T1000', ...
    'LYB_Nonlinear_T200', 'LYB_Nonlinear_T500', 'LYB_Nonlinear_T1000'});

% Save to Excel
writetable(excel_table, 'Table5_MSFE_Ratios.xlsx', 'Sheet', 'Table5', 'WriteVariableNames', false);

disp('Results saved to Table5_MSFE_Ratios.xlsx');
% Re-enable warning (optional)
warning('on', 'MATLAB:rankDeficientMatrix');