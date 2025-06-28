# Macroeconomic Forecasting with FMMDE

Reproducibility Package for "Macroeconomic Forecasting using Factor Models with Martingale Difference Errors: Empirical Analysis"

## Package Information

* **Date Assembled**: April 23, 2025
* **Author(s)**: Luca Mattia Rolla, Alessandro Giovannelli
* **Contact**: Luca Mattia Rolla (lmrolla92@gmail.com, University of Rome “Tor Vergata”, Italy), Alessandro Giovannelli (alessandro.giovannelli@univaq.it, University of L'Aquila, Italy)
* **Repository URL**: <https://github.com/lmrolls/EmpiricalAnalysisFinal>

## Overview

This repository contains the code and data to reproduce the empirical results for the paper "Macroeconomic Forecasting using Factor Models with Martingale Difference Errors."

## Getting Started: How to Run the Empirical Analysis

To run the empirical analysis, first ensure your system meets the requirements listed in the "System and Software Environment" section. Then, clone the repository (the folder will likely be named `EmpiricalAnalysisFinal`) and open MATLAB. The procedures for reproducing the empirical results are different and are detailed below.

### Running the Full Empirical Analysis (Tables 6-11)

The entire empirical analysis is a multi-step process that must be executed from the project's root directory.

* **Step 1: Set Working Directory.** Before you begin, set your MATLAB **Current Folder** to the project's root directory (e.g., `...EmpiricalAnalysisFinal`). This is a critical step.

* **Step 2: Generate Forecast Results**. From the root directory, run the master script:
    * **Master Script**: `sMasterEmpiricalApplication.m`
    * **Description**: This script manages the full analysis workflow. It runs a sequence of out-of-sample forecasting scripts for each methodology (e.g., `USA_Rolling_Rev1_MDTest.m`). Each of these scripts produces its own `.mat` output file.
    * After the individual forecasts are generated, the master script runs `USA_Rolling_Rev1_CVAllModels_v2.m`. This final script loads all the previously generated `.mat` files, applies the rolling time series cross-validation, and saves the final, consolidated results into a single file: `USA_Rolling_Rev1_CVAllModels_v2.mat`.
    * **Command**:
        ```matlab
        run sMasterEmpiricalApplication.m
        ```

* **Step 3: Generate Final Tables**. After completing Step 2, run the scripts in the `ReplicationTables/` folder (e.g., `sExportTable6.m`). These scripts load the crucial `USA_Rolling_Rev1_CVAllModels_v2.mat` file to produce the final LaTeX tables for the paper (Tables 6-11).

* **Warning: The script run('USA_Rolling_Rev1_XGBoosting.m'); requires significant computational time. With the hardware configurations adopted, the execution can take approximately 4 days to complete. To facilitate replicability and reduce computational burden, the output file from this procedure has been already included in the folder. You do not need to re-run this script unless you want to regenerate the results from scratch.

* **Empirical Data**:
    * The primary empirical analysis uses the **FRED-MD database** (McCracken & Ng, 2016). This is a publicly available dataset of 119 U.S. monthly macroeconomic variables spanning from January 1959 to January 2024. The data can be accessed online at: <https://www.stlouisfed.org/research/economists/mccracken/fred-databases>. As described in the paper, all series are pre-processed to ensure stationarity. A full list of variables and their transformations is available in **Appendix A** of the paper. The necessary data file, `current_May2024.csv`, is included in the `code/empiricalAnalysis/Data` folder.
    * For the analysis including the COVID-19 pandemic, the model uses data on monthly deaths to 'de-COVID' the series, following the approach of **Ng (2021)**. The required data file, `dataCovidSerenaNg.csv`, is also included in the `code/empiricalAnalysis/Data` folder. This conditional mean cleaning is performed by the `fMeanClean.m` function, located in the `code/empiricalAnalysis/MainReplication/Utils` folder.

## System and Software Environment

The results in the paper were obtained using the following environments.

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