clear; clc;
load USA_Rolling_Rev1_CVAllModels_v2
load('USA_GroupVariable_Rev1.mat','group','group_name')
NN = 119;
HH = [1 6 12];

%% EVALUATION 
for k = 1:NN
    for h = HH
        %% TEST
        MSFE_MDDM_ST(k,h)      =  mean((finaltrue(1:end,k,h) - finalpredMD(1:end,k,h)).^2);        
        MSFE_MDDM_SCREE(k,h)   =  mean((finaltrue(1:end,k,h) - finalpredScreeMD(1:end,k,h)).^2);
        MSFE_LAM(k,h)          =  mean((finaltrue(1:end,k,h) - finalpredLAM(1:end,k,h)).^2);
        MSFE_SW(k,h)           =  mean((finaltrue(1:end,k,h) - finalpredSW(1:end,k,h)).^2);
        %% CV
        MSFE_MDDM_CV(k,h)      =  mean((finaltrue(1:end,k,h) - finalpredFixMD(1:end,k,h)).^2);
        MSFE_LAM_CV(k,h)       =  mean((finaltrue(1:end,k,h) - finalpredFixLAM(1:end,k,h)).^2); 
        MSFE_SW_CV(k,h)        =  mean((finaltrue(1:end,k,h) - finalpredFixSW(1:end,k,h)).^2); 
        MSFE_ICA(k,h)          =  mean((finaltrue(1:end,k,h) - finalpredICA(1:end,k,h)).^2);
        MSFE_SPARSE(k,h)       =  mean((finaltrue(1:end,k,h) - finalpredSparse(1:end,k,h)).^2);
        MSFE_BOOSTING(k,h)     =  mean((finaltrue(1:end,k,h) - finalpredBoosting(1:end,k,h)).^2);
        MSFE_COMBO_EQ(k,h)     =  mean((finaltrue(1:end,k,h) - ComboEqual(1:end,k,h)).^2);
        MSFE_COMBO_IP(k,h)     =  mean((finaltrue(1:end,k,h) - ComboInvPer(1:end,k,h)).^2);
        MSFE_COMBO_PP(k,h)     =  mean((finaltrue(1:end,k,h) - ComboPointPer(1:end,k,h)).^2);
        MSFE_COMBO_IR(k,h)     =  mean((finaltrue(1:end,k,h) - ComboInvRank(1:end,k,h)).^2);
        MSFE_AR(k,h)           =  mean((finaltrue(1:end,k,h) - finalpredAR(1:end,k,h)).^2);
    end
end

TAB_MDDM_ST 	= MSFE_MDDM_ST    ./  MSFE_AR;
TAB_MDDM_CV 	= MSFE_MDDM_CV    ./  MSFE_AR;
TAB_MDDM_SCREE 	= MSFE_MDDM_SCREE ./  MSFE_AR;
TAB_LAM 		= MSFE_LAM        ./  MSFE_AR;
TAB_LAM_CV 		= MSFE_LAM_CV     ./  MSFE_AR;
TAB_SW 			= MSFE_SW         ./  MSFE_AR;
TAB_SW_CV 	    = MSFE_SW_CV      ./  MSFE_AR;
TAB_ICA 	    = MSFE_ICA        ./  MSFE_AR;
TAB_SPARSE 		= MSFE_SPARSE     ./  MSFE_AR;
TAB_BOOSTING 	= MSFE_BOOSTING   ./  MSFE_AR;
TAB_COMBO_EQ 	= MSFE_COMBO_EQ   ./  MSFE_AR;
TAB_COMBO_IP 	= MSFE_COMBO_IP   ./  MSFE_AR;
TAB_COMBO_PP 	= MSFE_COMBO_PP   ./  MSFE_AR;
TAB_COMBO_IR 	= MSFE_COMBO_IR   ./  MSFE_AR;

SelVar = [6 24 32 100 107];

%% TABELLA FULL PERIOD
for sk = 1:length(SelVar)     
%% Tables for series:  IPI(6), UR(24), Employ(32), CPI(100), Core CPI(107)
%% Tabella 6 del paper diventa come segue
TABELLA_9(:,:,sk) = [   TAB_MDDM_ST(SelVar(sk),HH);...
                        TAB_MDDM_SCREE(SelVar(sk),HH);...
                        TAB_LAM(SelVar(sk),HH);...
                        TAB_SW(SelVar(sk),HH);...
                        TAB_MDDM_CV(SelVar(sk),HH);...
                        TAB_LAM_CV(SelVar(sk),HH);...
                        TAB_SW_CV(SelVar(sk),HH);...
                        TAB_ICA(SelVar(sk),HH);...
                        TAB_SPARSE(SelVar(sk),HH);...
                        TAB_BOOSTING(SelVar(sk),HH);...
                        TAB_COMBO_EQ(SelVar(sk),HH);...
                        TAB_COMBO_IP(SelVar(sk),HH)];
end

for sk = 1:length(SelVar)
    for h = HH
        err_MDDM_ST(:,sk,h)      =  ((finaltrue(1:end,SelVar(sk),h) - finalpredMD(1:end,SelVar(sk),h)).^2);
        err_MDDM_SCREE(:,sk,h)   =  ((finaltrue(1:end,SelVar(sk),h) - finalpredScreeMD(1:end,SelVar(sk),h)).^2);
        err_LAM(:,sk,h)          =  ((finaltrue(1:end,SelVar(sk),h) - finalpredLAM(1:end,SelVar(sk),h)).^2);
        err_SW(:,sk,h)           =  ((finaltrue(1:end,SelVar(sk),h) - finalpredSW(1:end,SelVar(sk),h)).^2);
        %% CV
        err_MDDM_CV(:,sk,h)      =  ((finaltrue(1:end,SelVar(sk),h) - finalpredFixMD(1:end,SelVar(sk),h)).^2);
        err_LAM_CV(:,sk,h)       =  ((finaltrue(1:end,SelVar(sk),h) - finalpredFixLAM(1:end,SelVar(sk),h)).^2); 
        err_SW_CV(:,sk,h)        =  ((finaltrue(1:end,SelVar(sk),h) - finalpredFixSW(1:end,SelVar(sk),h)).^2); 
        
        err_ICA(:,sk,h)          =  ((finaltrue(1:end,SelVar(sk),h) - finalpredICA(1:end,SelVar(sk),h)).^2);
        err_SPARSE(:,sk,h)       =  ((finaltrue(1:end,SelVar(sk),h) - finalpredSparse(1:end,SelVar(sk),h)).^2);
        err_BOOSTING(:,sk,h)     =  ((finaltrue(1:end,SelVar(sk),h) - finalpredBoosting(1:end,SelVar(sk),h)).^2);
        err_COMBO_EQ(:,sk,h)     =  ((finaltrue(1:end,SelVar(sk),h) - ComboEqual(1:end,SelVar(sk),h)).^2);
        err_COMBO_IP(:,sk,h)     =  ((finaltrue(1:end,SelVar(sk),h) - ComboInvPer(1:end,SelVar(sk),h)).^2);
        err_AR(:,sk,h)           =  ((finaltrue(1:end,SelVar(sk),h) - finalpredAR(1:end,SelVar(sk),h)).^2);
                
        losses{sk,h} = [err_MDDM_ST(:,sk,h)  err_MDDM_SCREE(:,sk,h)   err_LAM(:,sk,h)...
                        err_SW(:,sk,h)       err_MDDM_CV(:,sk,h)      err_LAM_CV(:,sk,h)...
                        err_SW_CV(:,sk,h)...
                        err_ICA(:,sk,h)      err_SPARSE(:,sk,h)       err_BOOSTING(:,sk,h)...
                        err_COMBO_EQ(:,sk,h) err_COMBO_IP(:,sk,h)     err_AR(:,sk,h)];
        [INCLUDEDR{sk,h},PVALSR{sk,h},EXCLUDEDR{sk,h},INCLUDEDSQ{sk,h},PVALSSQ{sk,h},EXCLUDEDSQ{sk,h}] = mcs(losses{sk,h}, .05, 5000, 15,'BLOCK');
    end
end

for sk = 1:length(SelVar)
    for h = 1:length(HH)
        pvalues([EXCLUDEDR{sk,HH(h)};INCLUDEDR{sk,HH(h)}],h,sk) = PVALSR{sk,HH(h)};
        % MCS(INCLUDEDR{k,h},h) = 11111;
        % MCS(EXCLUDEDR{k,h},h) = 99999;
    end
end

%% FINAL LATEX TABLE GENERATION SCRIPT
% Assumes:
% - TABELLA_6(m,h,s): Relative MSFE for model m, horizon h, series s
% - pvalues(m,h,s): p-values from MCS for model m, horizon h, series s

model_labels = { ...
    'FMMDE$_{ST}$', 'FMMDE$_{\lambda}$', 'LYB$_{\lambda}$', 'SW$_{BN}$', ...
    'FMMDE$_{CV}$', 'LYB$_{CV}$', 'SW$_{CV}$', 'ICACV', 'SPACCV', ...
    'Boosting', 'COMB$_{EW}$', 'COMB$_{IP}$','AR(BIC)'};

series_labels = {'IPI','UR','PAYEMS','CPI','cCPI'};
Hvec = [1 6 12];
nModels = length(model_labels);
nSeries = length(series_labels);

%% ========== PANEL A: RELATIVE MSFE ==========
fprintf('\\begin{table}[!ht]\\centering\n');
fprintf('\\caption*{\\textbf{Panel A:} Relative MSFE}\n');
fprintf('\\begin{tabular}{l');
for i = 1:nSeries
    fprintf('ccc');
end
fprintf('}\n\\toprule\n');

% First header: variable names
for i = 1:nSeries
    fprintf('& \\multicolumn{3}{c}{%s} ', series_labels{i});
end
fprintf('\\\\\n');

% Second header: horizons
for i = 1:nSeries
    fprintf('& $h{=}1$ & $h{=}6$ & $h{=}12$ ');
end
fprintf('\\\\ \\midrule\n');

% Table rows (models)
for m = 1:nModels-1
    fprintf('%-14s', model_labels{m});
    for s = 1:nSeries
        for h = 1:3
            fprintf(' & %.3f', TABELLA_9(m, h, s));
        end
    end
    fprintf(' \\\\\n');
end

fprintf('\\bottomrule\n\\end{tabular}\n\\end{table}\n\n');

%% ========== PANEL B: MCS P-VALUES ==========
fprintf('\\begin{table}[!ht]\\centering\n');
fprintf('\\caption*{\\textbf{Panel B:} Model Confidence Set (P-values)}\n');
fprintf('\\begin{tabular}{l');
for i = 1:nSeries
    fprintf('ccc');
end
fprintf('}\n\\toprule\n');

% First header: variable names
for i = 1:nSeries
    fprintf('& \\multicolumn{3}{c}{%s} ', series_labels{i});
end
fprintf('\\\\\n');

% Second header: horizons
for i = 1:nSeries
    fprintf('& $h{=}1$ & $h{=}6$ & $h{=}12$ ');
end
fprintf('\\\\ \\midrule\n');

% Table rows (models)
for m = 1:nModels
    fprintf('%-14s', model_labels{m});
    for s = 1:nSeries
        for h = 1:3
            val = pvalues(m, h, s);
            if isnan(val)
                fprintf(' & ');
            else
                fprintf(' & %.3f', val);
            end
        end
    end
    fprintf(' \\\\\n');
end

fprintf('\\bottomrule\n\\end{tabular}\n\\end{table}\n');
