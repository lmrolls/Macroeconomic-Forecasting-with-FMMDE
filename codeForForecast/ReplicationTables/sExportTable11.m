%% EXPORT FORMATTED MSFE TABLES FOR REPLICATION (LATEX REPLICA TABLE FORMAT)
% Questo script replica il formato della tabella stile accademico (come Table 10)
% generando blocchi per modello × orizzonte × gruppi, con intestazioni ripetute

clear; clc;
addpath('..\OutputForecast')
addpath('..\ModelConfidenceSetRev1')

%% Load input data
load USA_Rolling_Rev1_CVAllModels_v2
load('USA_GroupVariable_Rev1.mat','group','group_name')

%% Settings
NN = 119;
HH = [1 6 12];
percentiles = [10 25 50 75 90];
group_labels = {'OUTPUT & INCOME', 'LABOR MARKET', 'HOUSING', ...
                'CONS., INV. & ORD.','GROUP 7' , 'INT. & EX. RATES', 'PRICES','GROUP 8' };
model_names = {'ICA','SPARSE','BOOSTING','COMBO_EQ','COMBO_IP'};
latex_model_names = {'ICA','SPARSE','BOOST','COMBO$_{EQ}$','COMBO$_{IP}$'};

%% Compute MSFE ratios relative to AR
for k = 1:NN
    for h = HH
        MSFE_AR(k,h)                    = mean((finaltrue(:,k,h) - finalpredAR(:,k,h)).^2);
        MSFE_STRUCT(k,h).ICA            = mean((finaltrue(:,k,h) - finalpredICA(:,k,h)).^2);
        MSFE_STRUCT(k,h).SPARSE         = mean((finaltrue(:,k,h) - finalpredSparse(:,k,h)).^2);
        MSFE_STRUCT(k,h).BOOSTING       = mean((finaltrue(:,k,h) - finalpredBoosting(:,k,h)).^2);
        MSFE_STRUCT(k,h).COMBO_EQ       = mean((finaltrue(:,k,h) - ComboEqual(:,k,h)).^2);
        MSFE_STRUCT(k,h).COMBO_IP       = mean((finaltrue(:,k,h) - ComboInvPer(:,k,h)).^2);
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
fprintf('\n%%================= LATEX TABLE 10 PANEL-STYLE =================\n');

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