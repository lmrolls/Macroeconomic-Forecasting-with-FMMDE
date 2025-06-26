clear;clc;
%% Load Results Model MDDM fixed factors
load('USA_Rolling_Rev1_FixedFactors_v2.mat', 'predMDDMgt','predSWgt')
predFixedMD = predMDDMgt;
predFixedSW = predSWgt;
%% Load Results Model Lam and Yao
load('USA_Rolling_Rev1_LAM_v2.mat', 'predMDDMgt','predSWgt','predAR','nfactors','true','series')
predLAM = predMDDMgt;
nfacLAM = nfactors;
load('USA_Rolling_Rev1_FixedFactors_LAM_v2','predMDDMgt')
predLAMfix = predMDDMgt;
%% Load Results Model MDDM Super Test
load('USA_Rolling_Rev1_SuperTest_v2.mat','predMDDMgt')
predSuperTest = predMDDMgt;
%% Load Sparse Dynamic Factor Model
load('USA_Rolling_Rev1_SparsePCA_v2.mat', 'predSparsegt','vSparseLoad')
%% Load Boosting Forecast
load('USA_Rolling_Rev1_XGBoosting_cp3_v2.mat', 'predBoosting','LearnCyc','LearnRate')
%% Load Scree MD Forecast
load('USA_Rolling_Rev1_ScreeMD_v2.mat', 'predMDDMgt','nScreeFac')
predMdscree = predMDDMgt;
load('USA_Rolling_Rev1_FastICA_v2.mat', 'predFastIcagt','vrmax')

NN              = 119; % the number of series
HH              = [1 6 12]; % The step forecast
t1f             = datetime(1971,01,01);
dateXf          = datevec(dateshift(t1f,'start','month',0:625)');
BegSampleY      = 1971;
BegSampleM      = 1;
EndSampleY      = 1975;
EndSampleM      = 12;

ind_first       = find(dateXf(:,1)==BegSampleY & dateXf(:,2)==BegSampleM);
ind_last        = find(dateXf(:,1)==EndSampleY & dateXf(:,2)==EndSampleM);

%% If rw = 0 selection with CV recursive.
%% If rw = jwins election with  CV rolling.
rmax      = 10;
K0        = [1 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30];
rw        = 0;
%% Compute the MSFE for PC regression

for jwin = 1:626-60%
    disp(jwin)
    rw = jwin;
    tic;
    for k = 1:NN
        for h = HH

            for k0 = 1:numel(K0)
                CV_MSFE_MDscree{h}(k,k0)   =  mean((true(ind_first+rw:(ind_last+jwin)-h,h,k) - predMdscree(ind_first+rw:(ind_last+jwin)-h,h,k,k0)).^2);
                CV_MSFE_LAM{h}(k,k0)       =  mean((true(ind_first+rw:(ind_last+jwin)-h,h,k) - predLAM(ind_first+rw:(ind_last+jwin)-h,h,k,k0)).^2);
                CV_MSFE_TEST_MD{h}(k,k0)   =  mean((true(ind_first+rw:(ind_last+jwin)-h,h,k) - predSuperTest(ind_first+rw:(ind_last+jwin)-h,h,k,k0)).^2);
                for r = 1:rmax
                    CV_MSFE_LAM_FIX{h}(k,k0,r)    =  mean((true(ind_first+rw:(ind_last+jwin)-h,h,k) - predLAMfix(ind_first+rw:(ind_last+jwin)-h,h,k,k0,r)).^2);
                    CV_MSFE_MDDM_FIX{h}(k,k0,r)   =  mean((true(ind_first+rw:(ind_last+jwin)-h,h,k) - predFixedMD(ind_first+rw:(ind_last+jwin)-h,h,k,k0,r)).^2);
                    CV_MSFE_SW_FIX{h}(k,r)        =  mean((true(ind_first+rw:(ind_last+jwin)-h,h,k) - predFixedSW(ind_first+rw:(ind_last+jwin)-h,h,k,r)).^2);
                end
            end

            %% BOOSTING MODEL SELECTION
            for lc = 1:length(LearnCyc)
                for lr = 1:length(LearnRate)
                    CV_MSFE_Boo{h}(k,lr,lc)       =  mean((true(ind_first+rw:(ind_last+jwin)-h,h,k) - predBoosting(ind_first+rw:(ind_last+jwin)-h,h,k,lr,lc)).^2);
                end
            end
            for lc = 1:length(LearnCyc)
                [ValLearnRatecv(lc,1),twempindLearnRatecv(lc,1)]     = min(squeeze(CV_MSFE_Boo{h}(k,:,lc)));
            end
            [~,templearncycle]        = min(ValLearnRatecv);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
            %% FastICA Dynamic Factor Model
            rica = vrmax(ind_first+rw);
            for rc = 1:rica
                CV_MSFE_ICA{h}(k,rc)    =  mean((true(ind_first+rw:(ind_last+jwin)-h,h,k) - predFastIcagt(ind_first+rw:(ind_last+jwin)-h,h,k,rc)).^2);
            end
            %% Sparse Dynamic Factor Model
            for r = 1:rmax
                for vlam = 1:length(vSparseLoad)
                    CV_MSFE_SPARSE{h}(k,vlam,r)    =  mean((true(ind_first+rw:(ind_last+jwin)-h,h,k) - predSparsegt(ind_first+rw:(ind_last+jwin)-h,h,k,vlam,r)).^2);
                end
            end

            for r = 1:rmax
                [ValFixcvSW(r,1),indFixcvSW(r,1)]          = min(squeeze(CV_MSFE_SW_FIX{h}(k,r)));
                [ValFixcvk0Lam(r,1),indFixcvk0Lam(r,1)]    = min(squeeze(CV_MSFE_LAM_FIX{h}(k,:,r)));
                [ValFixcvk0(r,1),indFixcvk0(r,1)]          = min(squeeze(CV_MSFE_MDDM_FIX{h}(k,:,r)));
                [ValSParseLam(r,1),indSParseLamcv(r,1)]    = min(squeeze(CV_MSFE_SPARSE{h}(k,:,r)));
            end
            [~,tempnfacsw]        = min(ValFixcvSW);
            [~,tempnfaclam]       = min(ValFixcvk0Lam);
            [~,tempnfacmd]        = min(ValFixcvk0);
            [~,tempnfacsparse]    = min(ValSParseLam);
            
            %% Best Models fo ICA
            [~,tempnfacICA]       = min(squeeze(CV_MSFE_ICA{h}(k,:)));
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Best K0
            [~,indScreecvk0]     = min(squeeze(CV_MSFE_MDscree{h}(k,:)));
            [~,indLAMcvk0]       = min(squeeze(CV_MSFE_LAM{h}(k,:)));
            [~,indMDcvk0]        = min(squeeze(CV_MSFE_TEST_MD{h}(k,:)));
            k0Screecv(jwin,k,h)  = K0(indScreecvk0);
            k0LAMcv(jwin,k,h)    = K0(indLAMcvk0);
            k0MDcv(jwin,k,h)     = K0(indMDcvk0);
            
            %% Sparsenenss Loadings
            LamSprseLoading(jwin,k,h)   = vSparseLoad(indSParseLamcv(tempnfacsparse));
            
            %% K0 e Number of Factors for MDDM with Rolling CV
            k0MDFixcvLAM(jwin,k,h)  = K0(indFixcvk0Lam(tempnfaclam));
            k0MDFixcv(jwin,k,h)     = K0(indFixcvk0(tempnfacmd));
            
            %% Final Prediction
            finalpredScreeMD(jwin,k,h)    = predMdscree(ind_last+jwin,h,k,indScreecvk0);
            finalpredLAM(jwin,k,h)        = predLAM(ind_last+jwin,h,k,indLAMcvk0);
            finalpredMD(jwin,k,h)         = predSuperTest(ind_last+jwin,h,k,indMDcvk0);
            finalpredFixLAM(jwin,k,h)     = predLAMfix(ind_last+jwin,h,k,indFixcvk0Lam(tempnfaclam),tempnfaclam);
            finalpredFixMD(jwin,k,h)      = predFixedMD(ind_last+jwin,h,k,indFixcvk0(tempnfacmd),tempnfacmd);
            finalpredSW(jwin,k,h)         = predSWgt(ind_last+jwin,h,k);
            finalpredFixSW(jwin,k,h)      = predFixedSW(ind_last+jwin,h,k,tempnfacsw);
            finalpredICA(jwin,k,h)        = predFastIcagt(ind_last+jwin,h,k,tempnfacICA);
            finalpredSparse(jwin,k,h)     = predSparsegt(ind_last+jwin,h,k,indSParseLamcv(tempnfacsparse),tempnfacsparse);
            finalpredAR(jwin,k,h)         = predAR(ind_last+jwin,h,k);
            finalpredBoosting(jwin,k,h)   = predBoosting(ind_last+jwin,h,k,twempindLearnRatecv(templearncycle),templearncycle);
            finaltrue(jwin,k,h)           = true(ind_last+jwin,h,k);

            %% Best Number of Factors for different Approach

            finalnfacMDFixcv(jwin,k,h)    = tempnfacmd;
            finalnfacLAMFixcv(jwin,k,h)   = tempnfaclam;
            finalnfacSWFixcv(jwin,k,h)    = tempnfacsw;
            finalnfacsparse(jwin,k,h)     = tempnfacsparse;
            finalnfacICA(jwin,k,h)        = tempnfacICA;

            %% Best Model Selectioon for Boosting
            indLearnRatecv(jwin,k,h)      = twempindLearnRatecv(templearncycle);
            indLearnCyclecv(jwin,k,h)     = templearncycle;

            %% Combinations of Forecast
            OutpredScreeMD    =  predMdscree(ind_first+rw:(ind_last+jwin)-h,h,k,indScreecvk0);
            OutpredLAM        =  predLAM(ind_first+rw:(ind_last+jwin)-h,h,k,indLAMcvk0);
            OutpredMD         =  predSuperTest(ind_first+rw:(ind_last+jwin)-h,h,k,indMDcvk0);
            OutpredFixMD      =  predFixedMD(ind_first+rw:(ind_last+jwin)-h,h,k,indFixcvk0(tempnfacmd),tempnfacmd);
            OutpredFixLAM     =  predLAMfix(ind_first+rw:(ind_last+jwin)-h,h,k,indFixcvk0Lam(tempnfaclam),tempnfaclam);
            OutpredSW         =  predSWgt(ind_first+rw:(ind_last+jwin)-h,h,k);
            OutpredFixSW      =  predFixedSW(ind_first+rw:(ind_last+jwin)-h,h,k,tempnfacsw);
            OutpredICA        =  predFastIcagt(ind_first+rw:(ind_last+jwin)-h,h,k,tempnfacICA);
            OutpredSparse     =  predSparsegt(ind_first+rw:(ind_last+jwin)-h,h,k,indSParseLamcv(tempnfacsparse),tempnfacsparse);
            OutpredBoosting   =  predBoosting(ind_first+rw:(ind_last+jwin)-h,h,k,twempindLearnRatecv(templearncycle),templearncycle);
            OutpredAR         =  predAR(ind_first+rw:(ind_last+jwin)-h,h,k);
            

            PreTrue = true(ind_first+rw:(ind_last+jwin)-h,h,k);
            PreFor  = [OutpredScreeMD OutpredLAM OutpredMD OutpredFixMD OutpredFixLAM OutpredSW  OutpredFixSW OutpredICA OutpredSparse OutpredBoosting OutpredAR];
            OutFor  = [finalpredScreeMD(jwin,k,h) finalpredLAM(jwin,k,h) finalpredFixLAM(jwin,k,h) finalpredMD(jwin,k,h) finalpredFixMD(jwin,k,h) finalpredSW(jwin,k,h)...
                       finalpredFixSW(jwin,k,h) finalpredICA(jwin,k,h) finalpredSparse(jwin,k,h) finalpredBoosting(jwin,k,h) finalpredAR(jwin,k,h)];
            
            PreForOnlyFac  = [OutpredScreeMD OutpredLAM OutpredMD OutpredFixMD OutpredFixLAM OutpredSW  OutpredFixSW OutpredICA OutpredSparse OutpredBoosting OutpredAR];
            OutForOnlyFac  = [finalpredScreeMD(jwin,k,h) finalpredLAM(jwin,k,h) finalpredFixLAM(jwin,k,h) finalpredMD(jwin,k,h) finalpredFixMD(jwin,k,h) finalpredSW(jwin,k,h)...
                              finalpredFixSW(jwin,k,h) finalpredICA(jwin,k,h) finalpredSparse(jwin,k,h)];
            
            [w_ip,outfor_ip] = ip(PreTrue,PreFor,'criterion','se','forecasts',OutFor,'table',false);
            [w_pp,outfor_pp] = pp(PreTrue,PreFor,'criterion','se','forecasts',OutFor,'table',false);
            [w_ir,outfor_ir] = ir(PreTrue,PreFor,'forecasts',OutFor,'table',false);

            [w_ipOnlyFac,outfor_ipOnlyFac] = ip(PreTrue,PreForOnlyFac,'criterion','se','forecasts',OutFor,'table',false);
            [w_ppOnlyFac,outfor_ppOnlyFac] = pp(PreTrue,PreForOnlyFac,'criterion','se','forecasts',OutFor,'table',false);
            [w_irOnlyFac,outfor_irOnlyFac] = ir(PreTrue,PreForOnlyFac,'forecasts',OutFor,'table',false);
             
             %% Final Prediction
             ComboEqual(jwin,k,h)       = mean(OutFor);
             ComboInvPer(jwin,k,h)      = outfor_ip;
             ComboPointPer(jwin,k,h)    = outfor_pp;
             ComboInvRank(jwin,k,h)     = outfor_ir;

             ComboEqualOnlyFac(jwin,k,h)       = mean(OutForOnlyFac);
             ComboInvPerOnlyFac(jwin,k,h)      = outfor_ipOnlyFac;
             ComboPointPerOnlyFac(jwin,k,h)    = outfor_ppOnlyFac;
             ComboInvRankOnlyFac(jwin,k,h)     = outfor_irOnlyFac;

             %% Weights for Combination
             WInvPerOnlyFac(jwin,:,k,h)   = w_ip';
             WPointPerOnlyFac(jwin,:,k,h) = w_pp';
             WInvRankOnlyFac(jwin,:,k,h)  = w_ir';
             
             WInvPerOnlyFac(jwin,:,k,h)   = w_ip';
             WPointPerOnlyFac(jwin,:,k,h) = w_pp';
             WInvRankOnlyFac(jwin,:,k,h)  = w_ir';
        end
    end
    toc;
end
clear predSuperTest predMdscree predLAM predFixedMD predFastIcagt predSparsegt predBoosting predSWgt predAR
save USA_Rolling_Rev1_CVAllModels_v2
