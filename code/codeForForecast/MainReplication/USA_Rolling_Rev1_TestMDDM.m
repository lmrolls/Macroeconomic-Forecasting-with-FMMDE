%% Initialization
clear; clc; rng(1);
%% Load the Data
csv_in = 'current_May2024.csv'; % Dataset file
dum    = importdata(csv_in, ',');  % Import CSV file

% Extract variable names
series = dum.textdata(1,2:end);

% Extract transformation codes
tcode = dum.data(1,:);

% Extract raw data
raw = dum.data(2:end,:);
raw = raw(13:end,:); % Remove first 12 months (to align transformations)

%% Handle missing values and remove series with many NaNs
yt      = prepare_missing(raw, tcode); 
include = ~any(isnan(yt(24:end-12,:))); % Keep only series without NaNs in training sample
yt      = yt(:, include);
raw     = raw(:, include);
yt      = yt(1:end-2,:);
raw     = raw(1:end-2,:);
series  = series(include);
tcode   = tcode(include);

% Construct monthly dates
t1 = datetime(1960,01,01);
[Traw, NN] = size(raw);
fred_dates = dateshift(t1, 'start', 'month', 0:Traw-1)';

%% Construct Forecast Targets
HH = [1 6 12]; % Forecast horizons (1, 6, 12 months ahead)
temp_var2for = zeros(Traw-2, HH(end));

for n = 1:NN
    trans = tcode(n);
    for h = HH
        if trans == 1 || trans == 2 || trans == 7
            temp_var2for(h:end,h) = yt(h+2:end,n);
        elseif trans == 3
            tempA = h^(-1)*((raw(1+h:end,n) - raw(1:end-h,n)) ./ raw(1:end-h,n));
            tempB = ((raw(2:end,n) - raw(1:end-1,n)) ./ raw(1:end-1,n));
            temp_var2for(h:end,h) = 1200*tempA(2:end,1) - 1200*tempB(1:end-h,1);
        elseif trans == 4
            temp_var2for(h:end,h) = log(yt(h+2:end,n));
        elseif trans == 5
            tempA = h^(-1)*log(raw(1+h:end,n)./raw(1:end-h,n));
            temp_var2for(h:end,h) = 1200*tempA(2:end,1);
        elseif trans == 6
            tempA = h^(-1)*log(raw(1+h:end,n)./raw(1:end-h,n));
            tempB = (log(raw(2:end,n)./raw(1:end-1,n)));
            temp_var2for(h:end,h) = 1200*tempA(2:end,1) - 1200*tempB(1:end-h,1);
        end
    end
    var2for(:,n,:) = temp_var2for(HH(end):end,:); %#ok<SAGROW>
end

%% Final Dataset Construction
dateX = datevec(fred_dates(HH(end)+2:end,:));
data = yt(HH(end)+2:end,:);
[T, NN] = size(data);

%% Prepare COVID-related Regressors
StartCovid_y = 2020; StartCovid_m = 1;
EndCovid_y   = 2022; EndCovid_m   = 12;
vt = zeros(T,1);

% Align COVID data with macroeconomic data
startcovid                  = find((dateX(:,1) == StartCovid_y) & (dateX(:,2) == StartCovid_m));
endcovid                    = find((dateX(:,1) == EndCovid_y) & (dateX(:,2) == EndCovid_m));
tempvt                      = fImportDataCovidRev1("dataCovidSerenaNg.csv");
vt(startcovid:endcovid,1)   = tempvt(1:36,2);

%% Forecast Settings
rmax = 10; % Max number of static factors
K0max = [1 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30]; % Candidate number of factors for dynamic tests

%% Define Rolling-Sample Evaluation Window
start_y = 1970; start_m = 12;
end_y = 2024; end_m = 1;
start_sample = find((dateX(:,1) == start_y) & (dateX(:,2) == start_m));
end_sample = find((dateX(:,1) == end_y) & (dateX(:,2) == end_m));
leng_pred = length(start_sample:end_sample - HH(end));
Jwind = start_sample; % Size of the initial estimation window

%% Initialize Storage Variables
jt = 0;
nfactors = zeros(leng_pred, length(K0max));
true = zeros(leng_pred, HH(end), NN);
predAR = zeros(leng_pred, HH(end), NN);
predSWgt = zeros(leng_pred, HH(end), NN);
predMDDMgt = zeros(leng_pred, HH(end), NN, length(K0max));
opt_nlag_AR = zeros(leng_pred, HH(end), NN);
opt_nlag_DIAR = zeros(leng_pred, HH(end), NN);
opt_nlag_MDDIAR = zeros(leng_pred, HH(end), NN, length(K0max));
bic_MDDIAR = zeros(leng_pred, HH(end), NN, length(K0max));

%% COVID Lags (Fixed to 3)
cp = 3;

%% Create Date Labels for Forecasts
jcvt = 0;
for jcv = start_sample:end_sample-HH(end)
    jcvt = jcvt + 1;
    for h = HH
        dateCV{jcvt,h} = datestr(dateX(jcv+h,:)); %#ok<SAGROW>
    end
end

%% Define COVID Out-of-Sample Start
T0_y = 2020; T0_m = 3;
T0 = find((dateX(:,1) == T0_y) & (dateX(:,2) == T0_m));

%% Rolling Forecast Loop
for j = start_sample:end_sample-HH(end)
    tic
    disp(datestr(dateX(j,:)))

    j0 = j - Jwind + 1;
    jt = jt + 1;

    % Define estimation sample
    if j <= T0
        xns = data(j0:j,:);
        x = standardize(xns);
        y2f = var2for(j0:j,:,:);
        vV2 = [];
    else
        indcov = j - T0;
        vt0 = vt(j0:j,:);
        xns = data(j0:j,:);
        [outRes, vV] = fMeanClean(xns, vt0, cp);
        pp = standardize(outRes(end,:));
        x0 = standardize(data(j0:j-indcov-1,:));
        x1 = outRes(end-indcov:end,:);
        x2 = [x0; x1];
        x = standardize(x2);
        vV2 = [zeros(cp, size(vV,2)); vV];
        y2f = var2for(j0:j,:,:);
    end

    % Static Factor Estimation
    static = 'baing';
    rbai = numstatic(x, rmax, static);
    [F, ~, lamhatSW, ~] = stockwatson2002(x, rbai);

    % Dynamic Factor Estimation (MDDM)
    FmddmK0 = cell(length(K0max), 1);
    parfor k0 = 1:length(K0max)

        rng_seed_offset = j * 1e6 + k0 * 100 + 16e7;
        rng(rng_seed_offset,"twister");

        [~, Fmddm] = seqTest(x, 200, 0.05, K0max(k0));
        FmddmK0{k0} = Fmddm;
        nfacmddm(jt,k0) = size(Fmddm,2);
    end

    % Forecast each variable
    for k = 1:NN
        true2 = zeros(HH(end),1);
        predAR2 = zeros(HH(end),1);
        predSWgt2 = zeros(1,HH(end),1);
        predMDDMgt2 = zeros(1,HH(end),1,length(K0max));
        opt_nlag_AR2 = zeros(1,HH(end),1);
        opt_nlag_DIAR2 = zeros(1,HH(end),1);
        opt_nlag_MDDIAR2 = zeros(1,HH(end),1,length(K0max));
        bic_MDDIAR2 = zeros(1,HH(end),1,length(K0max));

        for h = HH
            % Lag Selection
            [sLagAR, bic1] = fAutoRegressiveModSel(y2f(:,k,h), xns(:,k), vV2, 6, h);
            opt_nlag_AR2(h) = sLagAR;

            sLagDIAR = fDiffusionIndexModSel(F, y2f(:,k,h), xns(:,k), vV2, 6, h);
            opt_nlag_DIAR2(h) = sLagDIAR;

            % True value
            true2(h) = var2for(j+h,k,h);

            % AR Forecast
            tempAR = fAutoRegressiveForecast(y2f(:,k,h), xns(:,k), vV2, sLagAR, h);
            predAR2(h) = tempAR;

            % SW Forecast
            tempSWgt = fDiffusionIndexForecast(y2f(:,k,h), xns(:,k), F, vV2, sLagDIAR, 0, h);
            predSWgt2(1,h,1) = tempSWgt;

            % MDDM Forecasts
            for k0 = 1:length(K0max)
                Fmddm = FmddmK0{k0};
                if isempty(Fmddm)
                    predMDDMgt2(1,h,1,k0) = tempAR;
                else
                    [sLagMDDIAR, sBicMD] = fDiffusionIndexModSel(Fmddm, y2f(:,k,h), xns(:,k), vV2, 6, h);
                    opt_nlag_MDDIAR2(1,h,1,k0) = sLagMDDIAR;
                    bic_MDDIAR2(1,h,1,k0) = sBicMD;
                    tempMDDMgt = fDiffusionIndexForecast(y2f(:,k,h), xns(:,k), Fmddm, vV2, sLagMDDIAR, 0, h);
                    predMDDMgt2(1,h,1,k0) = tempMDDMgt;
                end
            end
        end

        % Store results
        true(jt,:,k) = true2;
        predAR(jt,:,k) = predAR2;
        predSWgt(jt,:,k) = predSWgt2;
        predMDDMgt(jt,:,k,:) = predMDDMgt2;
        opt_nlag_AR(jt,:,k) = opt_nlag_AR2;
        opt_nlag_DIAR(jt,:,k) = opt_nlag_DIAR2;
        opt_nlag_MDDIAR(jt,:,k,:) = opt_nlag_MDDIAR2;
        bic_MDDIAR(jt,:,k,:) = bic_MDDIAR2;
    end
    toc
end

%% Save Results
file_name = 'USA_Rolling_Rev1_SuperTest_v2';
%save(file)

%%=========== SAVING OUTPUT ========================
this_script_path = pwd;
output_folder    = fullfile(this_script_path, 'OutputForecast');
output_folder    = char(java.io.File(output_folder).getCanonicalPath());  % normalizza
%file_name        = 'USA_Rolling_Rev1_MDTest_v2.mat';
save(fullfile(output_folder, file_name));