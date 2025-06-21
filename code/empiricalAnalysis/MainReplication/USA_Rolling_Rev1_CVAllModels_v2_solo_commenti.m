clear; clc;
% Clear the workspace and command window

%% Load Results for the MDDM model with fixed number of factors
load('USA_Rolling_Rev1_FixedFactors_v2.mat', 'predMDDMgt','predSWgt')
predFixedMD = predMDDMgt;  % MDDM forecasts with fixed factors
predFixedSW = predSWgt;    % SW forecasts with fixed factors

%% Load Results for the LAM and YAO model
load('USA_Rolling_Rev1_LAM_v2.mat', 'predMDDMgt','predSWgt','predAR','nfactors','true','series')
predLAM = predMDDMgt;      % LAM forecasts
nfacLAM = nfactors;        % Number of selected factors (e.g., Bai-Ng)
load('USA_Rolling_Rev1_FixedFactors_LAM_v2','predMDDMgt')
predLAMfix = predMDDMgt;   % LAM forecasts with fixed factors

%% Load Results from the Super Test model (e.g., enriched MDDM)
load('USA_Rolling_Rev1_SuperTest_v2.mat','predMDDMgt')
load('USA_Rolling_Rev1_NumFactorsSupeTest.mat','nfacmddm')
predSuperTest = predMDDMgt;
NfacSuperTest = nfacmddm;  % Corresponding number of factors for SuperTest

%% Load Sparse PCA Dynamic Factor Model forecasts
load('USA_Rolling_Rev1_SparsePCA_v2.mat', 'predSparsegt','vSparseLoad')

%% Load Boosting Forecasts (e.g., XGBoost)
load('USA_Rolling_Rev1_XGBoosting_cp3_v2.mat', 'predBoosting','LearnCyc','LearnRate')

%% Load Scree test-based forecasts for MDDM
load('USA_Rolling_Rev1_ScreeMD_v2.mat', 'predMDDMgt','nScreeFac')
predMdscree = predMDDMgt;

%% Load ICA-based Dynamic Factor Model forecasts
load('USA_Rolling_Rev1_FastICA_v2.mat', 'predFastIcagt','vrmax')

% --- Setup ---
NN     = 119;                  % Number of time series
HH     = [1 6 12];             % Forecast horizons
t1f    = datetime(1971,01,01); 
dateXf = datevec(dateshift(t1f,'start','month',0:625)');  % Monthly date vector
BegSampleY = 1971; BegSampleM = 1;
EndSampleY = 1975; EndSampleM = 12;

% Indices corresponding to the forecast window
ind_first = find(dateXf(:,1)==BegSampleY & dateXf(:,2)==BegSampleM);
ind_last  = find(dateXf(:,1)==EndSampleY & dateXf(:,2)==EndSampleM);

%% Parameters for Cross-Validation
rmax = 10;                             % Maximum number of factors
K0 = 1:2:30;                           % Grid of factor numbers for some models
rw = 0;                                % Recursive (rw=0) or rolling window (rw=jwin)

%% Begin forecast evaluation across expanding windows
for jwin = 1:626-60
    disp(jwin)
    rw = jwin;                         % Update rolling window index
    tic;
    for k = 1:NN                       % For each time series
        for h = HH                    % For each forecast horizon
            
            % Evaluate FHLZ with multiple windows
            for win = 1:numel(Win)
                CV_MSFE_FHLZ_REC{h}(k,win) = mean((true(...) - predFHLZrec(...)).^2);
            end

            % Evaluate Scree test, LAM, SuperTest and their fixed factor variants
            for k0 = 1:numel(K0)
                CV_MSFE_MDscree{h}(k,k0) = mean((true(...) - predMdscree(...)).^2);
                CV_MSFE_LAM{h}(k,k0)     = mean((true(...) - predLAM(...)).^2);
                CV_MSFE_TEST_MD{h}(k,k0) = mean((true(...) - predSuperTest(...)).^2);
                for r = 1:rmax
                    CV_MSFE_LAM_FIX{h}(k,k0,r)  = mean((true(...) - predLAMfix(...)).^2);
                    CV_MSFE_MDDM_FIX{h}(k,k0,r) = mean((true(...) - predFixedMD(...)).^2);
                    CV_MSFE_SW_FIX{h}(k,r)      = mean((true(...) - predFixedSW(...)).^2);
                end
            end

            % Evaluate Boosting model (grid search over cycles and learning rate)
            for lc = 1:length(LearnCyc)
                for lr = 1:length(LearnRate)
                    CV_MSFE_Boo{h}(k,lr,lc) = mean((true(...) - predBoosting(...)).^2);
                end
            end
            for lc = 1:length(LearnCyc)
                [ValLearnRatecv(lc,1),twempindLearnRatecv(lc,1)] = min(...);
            end
            [~,templearncycle] = min(ValLearnRatecv);

            % Evaluate ICA model across different numbers of components
            rica = vrmax(ind_first+rw);
            for rc = 1:rica
                CV_MSFE_ICA{h}(k,rc) = mean((true(...) - predFastIcagt(...)).^2);
            end

            % Evaluate Sparse DFM for different sparsity levels
            for r = 1:rmax
                for vlam = 1:length(vSparseLoad)
                    CV_MSFE_SPARSE{h}(k,vlam,r) = mean((true(...) - predSparsegt(...)).^2);
                end
            end

            % Model selection: choose number of factors by minimum MSFE
            for r = 1:rmax
                [ValFixcvSW(r,1),indFixcvSW(r,1)] = min(...);
                [ValFixcvk0Lam(r,1),indFixcvk0Lam(r,1)] = min(...);
                [ValFixcvk0(r,1),indFixcvk0(r,1)] = min(...);
                [ValSParseLam(r,1),indSParseLamcv(r,1)] = min(...);
            end
            [~,tempnfacsw]     = min(ValFixcvSW);
            [~,tempnfaclam]    = min(ValFixcvk0Lam);
            [~,tempnfacmd]     = min(ValFixcvk0);
            [~,tempnfacsparse] = min(ValSParseLam);
            [~,tempnfacICA]    = min(...);

            % Select best K0 for several methods
            [~,indFHLZwinREC] = min(...);
            [~,indScreecvk0]  = min(...);
            [~,indLAMcvk0]    = min(...);
            [~,indMDcvk0]     = min(...);

            % Save selected model parameters
            k0Screecv(jwin,k,h)     = K0(indScreecvk0);
            k0LAMcv(jwin,k,h)       = K0(indLAMcvk0);
            k0MDcv(jwin,k,h)        = K0(indMDcvk0);
            LamSprseLoading(jwin,k,h) = vSparseLoad(...);
            k0MDFixcvLAM(jwin,k,h)  = K0(...);
            k0MDFixcv(jwin,k,h)     = K0(...);

            % Save final forecasts from each method
            finalpredScreeMD(jwin,k,h)  = predMdscree(...);
            finalpredLAM(jwin,k,h)      = predLAM(...);
            finalpredMD(jwin,k,h)       = predSuperTest(...);
            finalpredFixLAM(jwin,k,h)   = predLAMfix(...);
            finalpredFixMD(jwin,k,h)    = predFixedMD(...);
            finalpredSW(jwin,k,h)       = predSWgt(...);
            finalpredFixSW(jwin,k,h)    = predFixedSW(...);
            finalpredICA(jwin,k,h)      = predFastIcagt(...);
            finalpredFHLZ_REC(jwin,k,h) = predFHLZrec(...);
            finalpredSparse(jwin,k,h)   = predSparsegt(...);
            finalpredAR(jwin,k,h)       = predAR(...);
            finalpredBoosting(jwin,k,h) = predBoosting(...);
            finaltrue(jwin,k,h)         = true(...);

            % Save selected number of factors
            finalnfacScreeMD(jwin,k,h)   = nScreeFac(...);
            finalnfacLAM(jwin,k,h)       = nfacLAM(...);
            finalnfacSuperTest(jwin,k,h) = NfacSuperTest(...);
            finalnfacMDFixcv(jwin,k,h)   = tempnfacmd;
            finalnfacLAMFixcv(jwin,k,h)  = tempnfaclam;
            finalnfacSWFixcv(jwin,k,h)   = tempnfacsw;
            finalnfacsparse(jwin,k,h)    = tempnfacsparse;
            finalnfacICA(jwin,k,h)       = tempnfacICA;

            % Boosting model: store best hyperparameters
            indLearnRatecv(jwin,k,h)  = twempindLearnRatecv(...);
            indLearnCyclecv(jwin,k,h) = templearncycle;

            % Store all forecasts for combination purposes
            PreTrue = true(...);
            PreFor = [...];         % Forecasts on validation set
            OutFor = [...];         % One-step ahead forecasts

            % Forecast combinations using different weighting methods
            [w_ip,outfor_ip]     = ip(...);
            [w_pp,outfor_pp]     = pp(...);
            [w_ir,outfor_ir]     = ir(...);

            % Combinations using only factor-based models
            [w_ipOnlyFac,outfor_ipOnlyFac] = ip(...);
            [w_ppOnlyFac,outfor_ppOnlyFac] = pp(...);
            [w_irOnlyFac,outfor_irOnlyFac] = ir(...);

            % Save forecast combinations
            ComboEqual(jwin,k,h)       = mean(OutFor);
            ComboInvPer(jwin,k,h)      = outfor_ip;
            ComboPointPer(jwin,k,h)    = outfor_pp;
            ComboInvRank(jwin,k,h)     = outfor_ir;

            ComboEqualOnlyFac(jwin,k,h)    = mean(OutForOnlyFac);
            ComboInvPerOnlyFac(jwin,k,h)   = outfor_ipOnlyFac;
            ComboPointPerOnlyFac(jwin,k,h) = outfor_ppOnlyFac;
            ComboInvRankOnlyFac(jwin,k,h)  = outfor_irOnlyFac;

            % Save weights used for each forecast combination method
            WInvPerOnlyFac(jwin,:,k,h)   = w_ip';
            WPointPerOnlyFac(jwin,:,k,h) = w_pp';
            WInvRankOnlyFac(jwin,:,k,h)  = w_ir';
        end
    end
    toc;
end

% Clear unnecessary variables and save final output
clear predSuperTest predMdscree predLAM predFixedMD predFastIcagt predSparsegt predBoosting predSWgt predAR
save USA_Rolling_Rev1_CVAllModels_v2