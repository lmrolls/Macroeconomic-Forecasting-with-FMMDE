clear; clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%% LOADING THE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
csv_in       = 'current_May2024.csv';  % Input CSV file with macroeconomic data
dum          = importdata(csv_in,','); % Load data using comma as delimiter

% Variable names
series       = dum.textdata(1,2:end);
% Transformation codes for each variable
tcode        = dum.data(1,:);
% Raw time series data
raw          = dum.data(2:end,:);
raw          = raw(13:end,:); % Remove initial months (e.g., incomplete data)

% Apply pre-specified transformations and handle missing values
yt           = prepare_missing(raw,tcode);

% Exclude variables with many missing values in the core sample (post-1970)
include      = ~any(isnan(yt(24:end-12,:)));
yt           = yt(:,include);
raw          = raw(:,include);
yt           = yt(1:end-2,:);
raw          = raw(1:end-2,:);
series       = series(include);
tcode        = tcode(include);

% Construct the vector of corresponding dates starting from Jan 1960
t1           = datetime(1960,01,01);
[Traw,NN]    = size(raw);
fred_dates   = dateshift(t1,'start','month',0:Traw-1)';

%%%%%%%%%%%%%%%%%%%% FORECAST TARGET CONSTRUCTION %%%%%%%%%%%%%%%%%%%%%%%%%%
HH            = [1 6 12]; % Forecast horizons: 1-month, 6-months, 12-months ahead
temp_var2for  = zeros(Traw-2,HH(end));

% Compute target variables for each forecast horizon
for n = 1:NN
    trans = tcode(n); % Transformation code
    for h = HH
        % Transformation logic according to standard macroeconomic definitions
        if trans == 1
            temp_var2for(h:end,h) = yt(h+2:end,n);
        elseif trans == 2
            temp_var2for(h:end,h) = yt(h+2:end,n);
        elseif trans == 3
            tempA = h^(-1)*((raw(1+h:end,n)-raw(1:end-h,n))./raw(1:end-h,n));
            tempB = ((raw(2:end,n)-raw(1:end-1,n))./raw(1:end-1,n));
            temp_var2for(h:end,h) = 1200*tempA(2:end,1)-1200*tempB(1:end-h,1);
        elseif trans == 4
            temp_var2for(h:end,h) = log(yt(h+2:end,n));
        elseif trans == 5
            tempA = h^(-1)*log(raw(1+h:end,n)./raw(1:end-h,n));
            temp_var2for(h:end,h) = 1200*tempA(2:end,1);
        elseif trans == 6
            tempA = h^(-1)*log(raw(1+h:end,n)./raw(1:end-h,n));
            tempB = log(raw(2:end,n)./raw(1:end-1,n));
            temp_var2for(h:end,h) = 1200*tempA(2:end,1)-1200*tempB(1:end-h,1);
        elseif trans == 7
            temp_var2for(h:end,h) = yt(h+2:end,n);
        end
    end
    var2for(:,n,:) = temp_var2for(HH(end):end,:); %#ok<SAGROW>
end

%%%%%%%%%%%%%%%%%%%% FINAL SAMPLE CONSTRUCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove initial months affected by differencing
dateX        = datevec(fred_dates(HH(end)+2:end,:));
data         = yt(HH(end)+2:end,:);
[T,NN]       = size(data);

%%%%%%%%%%%%%%%%%%%% DUMMY VARIABLE FOR COVID EFFECTS %%%%%%%%%%%%%%%%%%%%%%
StartCovid_y      = 2020; StartCovid_m = 1;
EndCovid_y        = 2022; EndCovid_m   = 12;
vt                = zeros(T,1);
startcovid        = find((dateX(:,1) == StartCovid_y) & (dateX(:,2) == StartCovid_m));
endcovid          = find((dateX(:,1) == EndCovid_y) & (dateX(:,2) == EndCovid_m));
tempvt            = fImportDataCovidRev1("dataCovidSerenaNg.csv");
vt(startcovid:endcovid,1) = tempvt(1:36,2); % Import COVID dummies from external file
cp                = 3;
%%%%%%%%%%%%%%%%%%%% SAMPLE SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_y = 1970; start_m = 12;
end_y = 2024; end_m = 1;
start_sample = find((dateX(:,1) == start_y) & (dateX(:,2) == start_m));
end_sample   = find((dateX(:,1) == end_y) & (dateX(:,2) == end_m));
leng_pred    = length(start_sample:end_sample-HH(end));
Jwind = start_sample;  % Rolling window length

%%%%%%%%%%%%%%%%%%%% BOOSTING PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LearnRate   = 0.2:0.1:0.8;    % Learning rates for boosting
LearnCyc    = [100 200];      % Number of boosting iterations

%%%%%%%%%%%%%%%%%%%% INITIALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
jt              = 0;
true            = zeros(leng_pred,HH(end),NN);
predAR          = zeros(leng_pred,HH(end),NN);
opt_nlag_AR     = zeros(leng_pred,HH(end),NN);
predBoosting    = zeros(leng_pred,HH(end),NN,length(LearnRate));

% Store forecast evaluation dates
jcvt = 0;
for jcv = start_sample:end_sample-HH(end)
    jcvt = jcvt + 1;
    for h=HH
        dateCV{jcvt,h} = datestr(dateX(jcv+h,:));
    end
end

%%%%%%%%%%%%%%%%%%%% START DATE FOR COVID EFFECT DETECTION %%%%%%%%%%%%%%%%%
T0_y = 2020; T0_m = 3;
T0   = find((dateX(:,1) == T0_y) & (dateX(:,2) == T0_m));

%%%%%%%%%%%%%%%%%%%% PSEUDO REAL-TIME FORECAST LOOP %%%%%%%%%%%%%%%%%%%%%%%%
for j = start_sample:end_sample-HH(end)
    tic
    disp(datestr(dateX(j,:)))
    j0 = j-Jwind+1;
    jt = jt + 1;

    % PRE-COVID SAMPLE
    if j < T0
        xns  = data(j0:j,:);
        x    = standardize(xns);
        y2f  = var2for(j0:j,:,:);
        vV2  = [];
    else
        % COVID-PERIOD (apply data cleaning based on dummy)
        indcov      = j-T0;
        vt0         = vt(j0:j,:);
        xns	        = data(j0:j,:);
        [outRes,vV] = fMeanClean(xns,vt0,cp);
        pp          = standardize(outRes(end,:));
        x0	        = standardize(data(j0:j-indcov-1,:));
        x1          = outRes(end-indcov:end,:);
        x2          = [x0;x1];
        x           = standardize(x2);
        vV2         = [zeros(3,size(vV,2));vV];
        y2f         = var2for(j0:j,:,:);
    end

    % FORECAST FOR EACH VARIABLE
    for k = 1:NN
        true2        = zeros(HH(end),1);
        predAR2      = zeros(HH(end),1);
        opt_nlag_AR2 = zeros(1,HH(end),1);
        for h = HH
            % Select optimal AR lag
            sLagAR               = fAutoRegressiveModSel(y2f(:,k,h),xns(:,k),vV2,6,h);
            opt_nlag_AR2(h)     = sLagAR;
            true2(h)            = var2for(j+h,k,h);
            % Boosting Forecast
            parfor ns = 1:7
                for nc = 1:2
                    tempBoostinggt = fXGBoostingForecast(y2f(:,k,h),xns(:,k),x,vV2,sLagAR,0,LearnRate(ns),LearnCyc(nc),h);
                    predBoosting(jt,h,k,ns,nc) = tempBoostinggt;
                end
            end
        end
        true(jt,:,k)           = true2;
        opt_nlag_AR(jt,:,k)    = opt_nlag_AR2;
    end
    toc
end

%%=========== SAVING OUTPUT ========================
file = 'USA_Rolling_Rev1_XGBoosting_cp3_v2';
eval(['save ', file, ' -v7.3'])