%% ========================================================================
%               MASTER SCRIPT FOR ROLLING ANALYSIS
% =========================================================================
%% This master script controls the entire analysis workflow.

%% ========================================================================
%% To ensure that all subfolders are correctly loaded, make sure to set your 
%% current working directory to the outermost level of the project folder. 
%% This guarantees that the script will automatically add all relevant 
%% subdirectories to the MATLAB path, allowing the empirical application to 
%% run smoothly without requiring manual adjustments.
%% Add folders containing data and supplementary toolboxes (functions)
%% ========================================================================
%
% - Method 1: Direct calling (simple, for scripts in the same folder).
% - Method 2: Using run() from a subfolder (recommended for organization).
%
% It also adds a 'utils' folder for shared helper functions.
%
% Created: 15-Jun-2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% ========================================================================
%  0. INITIAL SETUP (ROBUST VERSION)
%  ========================================================================
%  Clear workspace, restore default path to avoid contamination from other
%  folders, and then add only the paths for this specific project.
clear; clc; close all;
disp('--- [SETUP] Initializing environment...');

% --- Create a clean path environment ---
% This is the crucial step to prevent loading code from unwanted folders
% like 'codeForSimulations'. It resets the path to MATLAB's default state.
restoredefaultpath;
rehash toolboxcache;
disp('--- [SETUP] MATLAB path has been reset to default.');

% --- Add only the necessary project folders ---
% Now, add only the subfolders of the current directory (empiricalAnalysis)
% to the path.
baseFolder = pwd; % This will be the path to '.../empiricalAnalysis/'
addpath(genpath(baseFolder));
disp('--- [SETUP] Subfolders for empirical analysis have been added to the path.');

% --- Set up the output folder ---
output_folder = fullfile(baseFolder, 'OutputForecast');
% Create the folder if it doesn't exist
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
disp('--- [SETUP] Environment ready.');
disp(' ');
% ========================================================================
%               CHOOSE ONE METHOD TO RUN THE ANALYSIS
% =========================================================================
% =========================================================================
%  METHOD 2: USING run() FROM A SUBFOLDER (The "After" / Recommended Version)
% =========================================================================



disp('--- [METHOD 2] Starting analysis using run() FROM SUBFOLDER...');

%% --- Machine Learning ---
disp('--> Running Machine Learning procedures...');

%================== WARNING =============================
% Uncomment line 58 if you want to run Boosting.
% This function requires significant computational time.
% On a typical machine with standard hardware configurations, 
% the execution can take approximately 4 days to complete.
% To facilitate replicability and reduce computational burden, the output 
% file from this procedure has been already included in the folder.
% You do not need to re-run this script unless you want to regenerate the results from scratch.
%================== WARNING =============================


poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

%run('USA_Rolling_Rev1_XGBoosting.m');

poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

run('USA_Rolling_Rev1_SparsePCA.m');

poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

run('USA_Rolling_Rev1_FastICA.m');

poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

disp('...Machine Learning complete.');
disp(' ');

%% --- MDDM ---
disp('--> Running MDDM procedures...');


poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

run('USA_Rolling_Rev1_TestMDDM.m');

poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

run('USA_Rolling_Rev1_FixedFactors.m');

poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

run('USA_Rolling_Rev1_ScreeMD.m');

poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

disp('...MDDM complete.');
disp(' ');

%% --- LAM Yao Bathia ---
disp('--> Running LAM Yao Bathia procedures...');


poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

run('USA_Rolling_Rev1_LAM.m');

poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

run('USA_Rolling_Rev1_FixedFactors_LAM.m');

poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

disp('...LAM Yao Bathia complete.');
disp(' ');


%% --- Cross Validation ---


poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

disp('--> Running Cross Validation procedure...');
run('USA_Rolling_Rev1_CVAllModels_v2.m');

poolobj = gcp('nocreate');
if ~isempty(poolobj)
    delete(poolobj);
end

disp('...Cross Validation complete.');
disp(' ');


disp('--- [METHOD 2] All procedures finished. ---');
