# Macroeconomic Forecasting with FMMDE

Reproducibility Package for "Macroeconomic Forecasting using Factor Models with Martingale Difference Errors"

## Package Information

* **Date Assembled**: April 23, 2025
* **Author(s)**: Luca Mattia Rolla, Alessandro Giovannelli
* **Contact**: Luca Mattia Rolla (lmrolla92@gmail.com, University of Rome “Tor Vergata”, Italy), Alessandro Giovannelli (alessandro.giovannelli@univaq.it, University of L'Aquila, Italy)
* **Repository URL**: <https://github.com/lmrolls/Macroeconomic-Forecasting-with-FMMDE>

## Overview

This repository contains the code and data to reproduce the results for the paper "Macroeconomic Forecasting using Factor Models with Martingale Difference Errors."

The paper analyzes the forecasting performance of a new class of factor models with martingale difference errors (FMMDE; Lee and Shao, 2018). The model's properties are evaluated against a wide range of alternatives, including other factor models (Lam and Yao, 2012; Stock and Watson, 2002a, 2002b) and machine learning techniques such as sparse PCA, ICA, and gradient boosting.

The paper's main contributions are twofold:

1.  It introduces a **novel sequential testing methodology** for selecting the number of factors in FMMDE models and demonstrates its effectiveness through simulations.
2.  It conducts an extensive empirical analysis comparing FMMDE with alternative methods to improve predictions of U.S. macroeconomic aggregates, using the comprehensive FRED-MD dataset.

All results in this package were obtained using the **MATLAB Parallel Computing Toolbox** to speed up computations. The scripts exactly reproduce the outputs available in this repository (Excel tables, LaTeX code, `.mat` files) under a fixed seed. **Important Note on Reproducibility**: The scripts in this package use a fixed random seed to ensure the exact reproducibility of the provided outputs. Consequently, these results may not perfectly match those in the final published paper, which were generated without setting a specific seed.

## Getting Started: How to Run the Analysis

To run the analysis, first ensure your system meets the requirements listed in the "System and Software Environment" section. Then, clone the repository and open MATLAB.

**Important**: Before running any scripts, make sure to set your MATLAB **Current Folder** to the root directory of this project (e.g., `C:\Users\utente\Desktop\FMMDE_2025`). This will ensure that all subfolders and functions are correctly added to the MATLAB path and allow the application to run smoothly without manual adjustments.

### Running the Full Empirical Analysis (Tables 6-11)

The entire empirical analysis is a two-step process:

* **Step 1: Generate Forecast Results**: Run the master script to generate the raw forecasts and perform cross-validation.
    * **Master Script**: `sMasterEmpiricalApplication.m`
    * **Description**: This script manages the full analysis workflow. It runs a sequence of scripts to perform the out-of-sample forecasting for all methodologies. After all individual forecasts are generated, it runs `USA_Rolling_Rev1_CVAllModels_v2.m` to apply the rolling time series cross-validation procedure. This final script saves all the cross-validated results into a single output file: `OutputForecast/USA_Rolling_Rev1_CVAllModels_v2.mat`.
    * **Command**:
        ```matlab
        run sMasterEmpiricalApplication.m
        ```

* **Step 2: Generate Final Tables**: After completing Step 1, run the scripts in the `ReplicationTables` folder to produce the final LaTeX tables for the paper.
    * **Description**: The scripts in `code/empiricalAnalysis/ReplicationTables/` (e.g., `sExportTable6.m`, `sExportTable7.m`, etc.) load the `USA_Rolling_Rev1_CVAllModels_v2.mat` file and use the results to generate the final formatted tables (Tables 6-11). **These scripts must be run after the master script has finished.**

### Running Individual Simulations (Tables 1-5)

The simulation studies, which correspond to Tables 1-5 in the paper, can be run individually from the `code/codeForSimulations` directory.

* **How it Works**: Each subfolder (e.g., `Table1`, `Table2`, etc.) contains a main script named `MainFile_TAB*.m`. Running this script will reproduce the specific simulation results for the corresponding table in the paper.
* **Running a Simulation**: To run the simulation for Table 1, you can run its main script from the project's root directory:
    ```matlab
    run code/codeForSimulations/Table1/MainFile_TAB1.m
    ```
* **Outputs**: Each simulation script generates several output files using a fixed random seed for reproducibility. These include:
    * A `.mat` file containing the raw MATLAB simulation results.
    * An `.xlsx` file with the results formatted as an Excel table.
    * A `.tex` file with the final, formatted LaTeX code for the table.
* **Output Location**: When you run a simulation script (e.g., `MainFile_TAB1.m`), it saves the new output files directly within its own folder (e.g., `code/codeForSimulations/Table1/`). For direct comparison, the pre-computed results generated with the fixed random seed for the paper are already available in the corresponding `outputFromSimulations/tables/` subfolder.

## Sequential Testing Algorithm: `seqTest.m`

The function `seqTest.m` implements the sequential testing procedure for factor selection in FMMDE models, as described in Section 3 of the paper. This function is a core component of the simulation studies and is used to determine the number of latent factors in the model.

### Function Arguments

* `Y`: A T x p matrix of the time series data (T observations, p variables).
* `B`: The number of bootstrap replicates used to approximate p-values.
* `crit`: The critical p-value threshold for the test (e.g., 0.05).
* `k0`: The number of lags used for computing the cumulative Martingale Difference Divergence Matrix (MDDM).
* `boot`: A string specifying the bootstrap type. Can be `'radem'` for Rademacher (default) or `'esc'` for Mammen distribution.
* `cut`: A logical value (`true` or `false`). If `true`, the bootstrap procedure is applied only to a truncated fraction (one-third) of the estimated factors, which significantly reduces computation time. See **Appendix B** for more details on this truncation solution.

## Repository Structure and Outputs

The project's code is located in the `code/` folder.

* `code/codeForSimulations`: Contains all scripts for the Monte Carlo simulations.
* `code/empiricalAnalysis`: Includes the scripts and functions required to perform the empirical analysis. This folder contains subdirectories for the `MainReplication` (including `MainForecast`), competing models, and `ReplicationTables`. The toolboxes for specific methods are included directly in this folder: Sparse PCA (`SpaSMRev1`; Sjöstrand et al., 2018), Independent Component Analysis (`ICARev1`; Moore, 2025), Forecast Combination (`ForecastCombinationRev1`; Panagiotopoulos, 2025), and Model Confidence Set (`ModelConfidenceSetRev1`; Hansen, Lunde, and Nason, 2011).
* `outputFromSimulations`: Contains all the results from the simulation scripts in Excel and LaTeX format. The LaTeX files are generated using the `latexTable` function (Duenisch, 2025).

## Data Information

* **Simulation Data**: The data for the simulation studies (Tables 1-5) is generated by the scripts located in `code/codeForSimulations/DGPs/`.
* **Empirical Data**:
    * The primary empirical analysis uses the **FRED-MD database** (McCracken & Ng, 2016). This is a publicly available dataset of 119 U.S. monthly macroeconomic variables spanning from January 1959 to January 2024. The data can be accessed online at: <https://www.stlouisfed.org/research/economists/mccracken/fred-databases>. As described in the paper, all series are pre-processed to ensure stationarity. A full list of variables and their transformations is available in **Appendix A** of the paper. The necessary data file, `current_May2024.csv`, is included in the `code/empiricalAnalysis/Data` folder.
    * For the analysis including the COVID-19 pandemic, the model uses data on monthly deaths to 'de-COVID' the series, following the approach of **Ng (2021)**. The required data file, `dataCovidSerenaNg.csv`, is also included in the `code/empiricalAnalysis/Data` folder. This conditional mean cleaning is performed by the `fMeanClean.m` function, located in the `code/empiricalAnalysis/MainReplication/Utils` folder.

## System and Software Environment

The results in the paper were obtained using the following environments.

### Simulation Analysis

* **Hardware**:
    * **Model**: HP ProDesk 400 G5 MT
    * **CPU**: Intel(R) Core(TM) i7-8700 CPU @ 3.20GHz
    * **OS**: Microsoft Windows 10 Pro (64-bit, Version 10.0, Build 19045)
* **Expected Runtime**: The runtime for simulations varies. For example, a simulation with n=200 variables and T=200 time periods takes approximately 100 seconds on the specified hardware. Please see Appendix B of the paper for detailed computational times under various scenarios.
* **Software**:
    * **MATLAB Version**: 9.13.0.2080170 (R2022b) Update 1
    * **Java Version**: Java 1.8.0_202-b08 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM
* **MATLAB Toolboxes**:
    * Curve Fitting Toolbox Version 3.8 (R2022b)
    * Deep Learning Toolbox Version 14.5 (R2022b)
    * Econometrics Toolbox Version 6.1 (R2022b)
    * Financial Toolbox Version 6.4 (R2022b)
    * Global Optimization Toolbox Version 4.8 (R2022b)
    * Optimization Toolbox Version 9.4 (R2022b)
    * Parallel Computing Toolbox Version 7.7 (R2022b)
    * Statistics and Machine Learning Toolbox Version 12.4 (R2022b)

### Empirical Analysis

* **Hardware**:
    * **Model**: MacBook Pro (MacBookPro18,2)
    * **Chip**: Apple M1 Max (10 cores: 8 performance, 2 efficiency)
    * **Memory**: 64 GB
    * **OS**: macOS
* **Software**: The software environment (MATLAB version and toolboxes) is the same as that used for the Simulation Analysis.

## References

* Duenisch, E. (2025). *latexTable* (<https://github.com/eliduenisch/latexTable>), GitHub.
* Hansen, P. R., Lunde, A., & Nason, J. M. (2011). The model confidence set. *Econometrica*, 79(2), 453-497.
* Lam, C., & Yao, Q. (2012). Factor modeling for high-dimensional time series: Inference for the number of factors. *The Annals of Statistics*, 40(2), 694–726.
* Lee, C. E., & Shao, X. (2018). Martingale Difference Divergence Matrix and its application to dimension reduction for stationary multivariate time series. *Journal of the American Statistical Association*, 113(521), 216–229.
* McCracken, M. W., & Ng, S. (2016). FRED-MD: A monthly database for macroeconomic research. *Journal of Business & Economic Statistics*, 34(4), 574–589.
* Moore, B. (2025). *PCA and ICA Package* (Version 2.2.0.0). MATLAB Central File Exchange. Retrieved June 23, 2025, from <https://www.mathworks.com/matlabcentral/fileexchange/38300-pca-and-ica-package>.
* Ng, S. (2021). Modeling macroeconomic variations after covid-19 (Tech. Rep.). National Bureau of Economic Research.
* Panagiotopoulos, A. (2025). *Forecasting Combination* (Version 1.1.1). MATLAB Central File Exchange. Retrieved June 23, 2025, from <https://www.mathworks.com/matlabcentral/fileexchange/89629-forecasting-combination>.
* Sjöstrand, K., Clemmensen, L. H., Larsen, R., Einarsson, G., & Ersbøll, B. Κ. (2018). Spasm: A matlab toolbox for sparse statistical modeling. *Journal of Statistical Software*, 84 (10).
* Stock, J. H., & Watson, M. W. (2002a). Forecasting using principal components from a large number of predictors. *Journal of the American statistical association*, 97(460), 1167–1179.
* Stock, J. H., & Watson, M. W. (2002b). Macroeconomic forecasting using diffusion indexes. *Journal of Business & Economic Statistics*, 20(2), 147–162.
* Zou, H., Hastie, T., & Tibshirani, R. (2006). Sparse principal component analysis. *Journal of computational and graphical statistics*, 15(2), 265-286.

## License

This package is licensed under the MIT License (see `LICENSE` file).
