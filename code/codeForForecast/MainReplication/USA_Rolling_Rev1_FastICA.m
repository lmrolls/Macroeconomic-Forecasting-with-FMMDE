clear; clc;
% %%%%%%%%%%%%%%%%%%%%%%%%% LOADING THE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
csv_in       = 'current_May2024.csv';
%csv_in       = '2015-04.csv';
dum          = importdata(csv_in,',');
% Variable names
series       = dum.textdata(1,2:end);
% Transformation numbers
tcode        = dum.data(1,:);
% Raw data
%% We reomve some variables (5) because of many NaN's
raw          = dum.data(2:end,:);
raw          = raw(13:end,:);
yt           = prepare_missing(raw,tcode);
include      = ~any(isnan(yt(24:end-12,:)));
yt           = (yt(:,include));
raw          = (raw(:,include));
yt           = yt(1:end-2,:);
raw          = raw(1:end-2,:);
series       = series(include);
tcode        = tcode(include);
t1           = datetime(1960,01,01);
[Traw,NN]    = size(raw);
fred_dates   = dateshift(t1,'start','month',0:Traw-1)';
%% Constructing the Date
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% We construct the variable to forecast
HH            = [1 6 12];
temp_var2for  = zeros(Traw-2,HH(end));
for n = 1:NN
    trans = tcode(n);
    for h = HH
        if trans == 1
            temp_var2for(h:end,h)   = yt(h+2:end,n);
        elseif trans == 2
            % tempA                   = h^(-1)*((raw(1+h:end,n)-raw(1:end-h,n))./raw(1:end-h,n));
            % temp_var2for(h:end,h)   = 1200*tempA(2:end,1);
            temp_var2for(h:end,h)   = yt(h+2:end,n);
        elseif trans == 3
            tempA                   = h^(-1)*((raw(1+h:end,n)-raw(1:end-h,n))./raw(1:end-h,n));
            tempB                   = (((raw(2:end,n)-raw(1:end-1,n))./raw(1:end-1,n)));
            temp_var2for(h:end,h)   = 1200*tempA(2:end,1)-1200*tempB(1:end-h,1);
        elseif trans == 4
            temp_var2for(h:end,h)   = log(yt(h+2:end,n));
        elseif trans == 5
            tempA                   = h^(-1)*log(raw(1+h:end,n)./raw(1:end-h,n));
            temp_var2for(h:end,h)   = 1200*tempA(2:end,1);
        elseif trans == 6
            tempA                   = h^(-1)*log(raw(1+h:end,n)./raw(1:end-h,n));
            tempB                   = (log(raw(2:end,n)./raw(1:end-1,n)));
            temp_var2for(h:end,h)   = 1200*tempA(2:end,1)-1200*tempB(1:end-h,1);
        elseif trans == 7
            % tempA                   = h^(-1)*((raw(1+h:end,n)-raw(1:end-h,n))./raw(1:end-h,n));
            % tempB                   = (((raw(2:end,n)-raw(1:end-1,n))./raw(1:end-1,n)));
            % temp_var2for(h:end,h)   = tempA(2:end,1);
            temp_var2for(h:end,h)   = yt(h+2:end,n);
        end
    end
    var2for(:,n,:) = temp_var2for(HH(end):end,:); %#ok<SAGROW>
end
%% Final Dataset
% Remove first two months because some series have been second differenced
dateX        = datevec(fred_dates(HH(end)+2:end,:));
data         = yt(HH(end)+2:end,:);
[T,NN]       = size(data);
%% Data for Dummy Covid
% Since the data imported start from January 2020, we have to alline the
% Covid data with macroeconomic data stored in "data".
%% sample starts
StartCovid_y      = 2020;
StartCovid_m      = 1;
EndCovid_y        = 2022;
EndCovid_m        = 12;
vt                = zeros(T,1);

%% Finds when to start the simulated out-of-sample exercise
startcovid                = find((dateX(:,1) == StartCovid_y) & (dateX(:,2) == StartCovid_m));
endcovid                  = find((dateX(:,1) == EndCovid_y) & (dateX(:,2) == EndCovid_m));
tempvt                    = fImportDataCovidRev1("dataCovidSerenaNg.csv");
vt(startcovid:endcovid,1) = tempvt(1:36,2);

%% Max number of factors
rmax         = 5;
cp           = 3;
%% sample starts
start_y      = 1970;
start_m      = 12;
%% sample starts
end_y        = 2024;
end_m        = 1;
%% Finds when to start the simulated out-of-sample exercise
start_sample = find((dateX(:,1) == start_y) & (dateX(:,2) == start_m));
end_sample   = find((dateX(:,1) == end_y) & (dateX(:,2) == end_m));
leng_pred    = length(start_sample:end_sample-HH(end));
%% Size of the rolling window
Jwind        = start_sample;
%% Initialization
jt              = 0;
true            = zeros(leng_pred,HH(end),NN);
predAR          = zeros(leng_pred,HH(end),NN);
predSWgt        = zeros(leng_pred,HH(end),NN,rmax);
predFastIcagt    = zeros(leng_pred,HH(end),NN,rmax);
opt_nlag_AR     = zeros(leng_pred,HH(end),NN);
opt_nlag_DIAR   = zeros(leng_pred,HH(end),NN,rmax);
opt_nlag_sparse = zeros(leng_pred,HH(end),NN,rmax);
bic_sparse      = zeros(leng_pred,HH(end),NN,rmax);


jcvt       = 0;
for jcv  = start_sample:end_sample-HH(end)
    jcvt = jcvt + 1;
    for h=HH
        dateCV{jcvt,h} = datestr(dateX(jcv+h,:));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% sample starts
T0_y        = 2020;
T0_m        = 3;
%% Finds when to start the simulated out-of-sample exercise
T0 = find((dateX(:,1) == T0_y) & (dateX(:,2) == T0_m));

%% MAIN LOOP FOR PSEUDO REAL TIME
%for j  = start_sample:end_sample-HH(end)
for j  = start_sample:end_sample-HH(end)
    tic
    disp(datestr(dateX(j,:)))
    %% Define the beginning of the estimation sample
    j0 = j-Jwind+1;
    jt = jt + 1;
    %% j<T0 - Precovid Period
    if j<T0
        % The data at each time point of the evaluation exercise
        xns	     = data(j0:j,:);
        x	     = standardize(xns);
        y2f      = var2for(j0:j,:,:);
        vV2      = [];
    else
        indcov      = j-T0;
        vt0         = vt(j0:j,:);
        xns	        = data(j0:j,:);
        [outRes,vV] = fMeanClean(xns,vt0,cp);
        pp          = standardize(outRes(end,:));
        x0	        = standardize(data(j0:j-indcov-1,:));
        x1          = outRes(end-indcov:end,:);
        x2          = [x0;x1];
        x           = standardize(x2);
        vV2         = [zeros(cp,size(vV,2));vV];
        y2f         = var2for(j0:j,:,:);
    end
    %% Factor FIXED
    %% SW
    [F,~,lamhatSW,~] = stockwatson2002(x,rmax);
   
    %[tempFica,o1,o2] = fastica (x', 'approach', 'defl','lastEig', rmax, 'numOfIC', rmax);
   [~,tempFica] = fastICA(x',rmax,'negentropy',0);
    Fica             = tempFica';
    vrmax(jt,1) = size(Fica,2);
    for k=1:NN
        true2            = zeros(HH(end),1); %#ok<PFBNS>
        predAR2          = zeros(HH(end),1);
        predSWgt2        = zeros(1,HH(end),1,rmax);
        predFastIcagt2   = zeros(1,HH(end),1,rmax);
        opt_nlag_AR2     = zeros(1,HH(end),1);
        opt_nlag_DIAR2   = zeros(1,HH(end),1,rmax);
        
        bic_sparse2      = zeros(1,HH(end),1,rmax);
        for h=HH
            %% Model Selection
            sLagAR                = fAutoRegressiveModSel(y2f(:,k,h),xns(:,k),vV2,6,h);
            opt_nlag_AR2(h)       = sLagAR;
            %% True Value
            true2(h)              = var2for(j+h,k,h);
            %% AR Forecast
            tempAR                = fAutoRegressiveForecast(y2f(:,k,h),xns(:,k),vV2,sLagAR,h);
            predAR2(h)	          = tempAR;
            for ff = 1:size(Fica,2)
                
                Ffin                  = F(:,1:ff);
                sLagDIAR              = fDiffusionIndexModSel(Ffin,y2f(:,k,h),xns(:,k),vV2,6,h);
                opt_nlag_DIAR2(h)     = sLagDIAR;
                %% SW - Diffusion Index Forecast
                tempSWgt              = fDiffusionIndexForecast(y2f(:,k,h),xns(:,k),Ffin,vV2,6,0,h);
                predSWgt2(1,h,1,ff)   = tempSWgt;
                    %% FastIca - Diffusion Index Forecast
                   
                    [sLagFastIca,sBicMD]          = fDiffusionIndexModSel(Fica(:,1:ff),y2f(:,k,h),xns(:,k),vV2,6,h);

                    tempMDDMgt                  = fDiffusionIndexForecast(y2f(:,k,h),xns(:,k),Fica(:,1:ff),vV2,6,0,h);
                    predFastIcagt2(1,h,1,ff)     = tempMDDMgt;
            end
        end
        true(jt,:,k)                  = true2;
        predAR(jt,:,k)                = predAR2;
        predSWgt(jt,:,k,:)            = predSWgt2;
        predFastIcagt(jt,:,k,:)       = predFastIcagt2;
        opt_nlag_AR(jt,:,k)           = opt_nlag_AR2;
        opt_nlag_DIAR(jt,:,k,:)       = opt_nlag_DIAR2;
        
    end
    toc
end
clear x
st = 61;
en = 626;
for r = 1:5
for k = 1:NN
    for h = HH
    mse_ica(h,k,r) = mean((true(st:en,h,k) -predFastIcagt(st:en,h,k,r)).^2);
    mse_ar(h,k) = mean((true(st:en,h,k) - predAR(st:en,h,k)).^2);
    end
end
end

full_table_ica = mse_ica(:,:,:)./mse_ar(:,:);


file=(['USA_Rolling_Rev1_FastICA_v2']);
eval([ 'save ',file, ' -v7.3'])