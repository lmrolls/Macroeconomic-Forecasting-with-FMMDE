%% EXPORT PANEL-STYLE LATEX MSFE TABLE
clear; clc;

%% Load input data
load USA_Rolling_Rev1_CVAllModels_v2
load('USA_GroupVariable_Rev1.mat','group','group_name')

%% Settings
NN = 119;
HH = [1 6 12];
en = 532;
percentiles = [10 25 50 75 90];
group_labels = {'OUTPUT & INCOME', 'LABOR MARKET', 'HOUSING', ...
                'CONS., INV. & ORD.','GROUP 7' , 'INT. & EX. RATES', 'PRICES','GROUP 8' };
model_names = {'MDDM_ST','MDDM_SCREE','LAM','SW','MDDM_CV'};
latex_model_names = {'FMMDE$_{ST}$','FMMDE$_{\lambda}$','LYB$_{\lambda}$','SW$_{BN}$','FMMDE$_{CV}$'};

%% Compute MSFE ratios relative to AR
for k = 1:NN
    for h = HH
        MSFE_AR(k,h)                    = mean((finaltrue(1:en-h,k,h) - finalpredAR(1:en-h,k,h)).^2);
        MSFE_STRUCT(k,h).MDDM_ST        = mean((finaltrue(1:en-h,k,h) - finalpredMD(1:en-h,k,h)).^2);
        MSFE_STRUCT(k,h).MDDM_SCREE     = mean((finaltrue(1:en-h,k,h) - finalpredScreeMD(1:en-h,k,h)).^2);
        MSFE_STRUCT(k,h).LAM            = mean((finaltrue(1:en-h,k,h) - finalpredLAM(1:en-h,k,h)).^2);
        MSFE_STRUCT(k,h).SW             = mean((finaltrue(1:en-h,k,h) - finalpredSW(1:en-h,k,h)).^2);
        MSFE_STRUCT(k,h).MDDM_CV        = mean((finaltrue(1:en-h,k,h) - finalpredFixMD(1:en-h,k,h)).^2);
    end
end

%% Aggregate MSFE ratios
TAB_STRUCT = struct();
for m = 1:length(model_names)
    model = model_names{m};
    tmp = nan(NN, length(HH));
    for i = 1:NN
        for j = 1:length(HH)
            h = HH(j);
            tmp(i,j) = MSFE_STRUCT(i,h).(model) / MSFE_AR(i,h);
        end
    end
    TAB_STRUCT.(model) = tmp;
end

%% Create LaTeX-formatted panel-style table (like Table 7)
fprintf('\n%%================= LATEX TABLE 7 PANEL-STYLE =================\n');

for m = 1:length(model_names)
    model = model_names{m};
    latex_name = latex_model_names{m};
    data = TAB_STRUCT.(model);

    % Panel label (A, B, C, ...)
    panel_letter = char('A' + m - 1);

    % Begin table
    fprintf('\n\\begin{table}[!ht]\\centering\n');
    fprintf('\\caption*{\\textbf{Panel %s:} %s}\n', panel_letter, latex_name);
    fprintf('\\begin{tabular}{l');
    for i = 1:length(HH)
        fprintf('ccccc');
    end
    fprintf('}\n\\toprule\n');

    % Horizon headers
    for h = 1:length(HH)
        fprintf('& \\multicolumn{5}{c}{$h = %d$} ', HH(h));
    end
    fprintf('\\\\\n');

    % Percentile headers
    for h = 1:length(HH)
        fprintf('& 10th & 25th & 50th & 75th & 90th ');
    end
    fprintf('\\\\ \\midrule\n');

    % Row for each group
    for g = [1 2 3 4 6 7]
        fprintf('%-22s', group_labels{g});
        for h = 1:length(HH)
            horizon = HH(h);
            gdata = prctile(data(group == g, h), percentiles);
            fprintf(' & %.3f & %.3f & %.3f & %.3f & %.3f', gdata);
        end
        fprintf(' \\\\\n');
    end

    % Close table
    fprintf('\\bottomrule\n\\end{tabular}\n\\end{table}\n');
end