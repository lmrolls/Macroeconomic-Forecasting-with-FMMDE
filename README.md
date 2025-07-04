# Macroeconomic Forecasting with FMMDE

**Reproducibility Package for "Macroeconomic Forecasting using Factor Models with Martingale Difference Errors"**

* **Date Assembled**: June 29, 2025
* **Author(s)**: Luca Mattia Rolla, Alessandro Giovannelli
* **Contact**: Luca Mattia Rolla (lmrolla92@gmail.com, University of Rome “Tor Vergata”, Italy), Alessandro Giovannelli (alessandro.giovannelli@univaq.it, University of L'Aquila, Italy)
* **Repository URL**: <https://github.com/lmrolls/Macroeconomic-Forecasting-with-FMMDE>

## Overview

This repository contains the code and data to reproduce the results for the paper "Macroeconomic Forecasting using Factor Models with Martingale Difference Errors."

The paper analyzes the forecasting performance of a new class of factor models with martingale difference errors (FMMDE). The model's properties are evaluated against a wide range of alternatives, including other factor models and machine learning techniques. The paper's main contributions are:

1.  It introduces a **novel sequential testing methodology** for selecting the number of factors in FMMDE models and demonstrates its effectiveness through simulations.
2.  It conducts an extensive empirical analysis comparing FMMDE with alternative methods to improve predictions of U.S. macroeconomic aggregates, using the comprehensive FRED-MD dataset.

**Important Note on Reproducibility**: The scripts in this package use a fixed random seed to ensure the exact reproducibility of the provided outputs. Consequently, these results may not perfectly match those in the final published paper, which were generated without setting a specific seed.

## Repository Structure and Outputs

The project is organized into two main subfolders:

* **`codeForSimulations`**: Contains all scripts to reproduce the Monte Carlo simulations (Tables 1-5).
    * It includes a subfolder named **`outputFromSimulations`**, which contains the pre-computed results in Excel and LaTeX format, allowing for direct comparison with newly generated results. The LaTeX files are generated using the `latexTable` function (Duenisch, 2025).
* **`codeForForecast`**: Contains all scripts and functions for the empirical analysis (Tables 6-11).
    * It includes a subfolder named **`OutputForecast`**, which is initially empty. When the master script `sMasterEmpiricalApplication.m` is run, this folder is populated with the `.mat` output files from each forecasting model, culminating in the final `USA_Rolling_Rev1_CVAllModels_v2.mat` file.
    * This folder also includes other necessary subdirectories: `Data`, `ForecastCombinationRev1`, `ICARev1`, `MainReplication`, `ModelConfidenceSetRev1`, `ReplicationTables`, and `SpaSMRev1`.
* **Shared Functions**: Both `codeForSimulations` and `codeForForecast` contain a subfolder named **`factorEstimation`**. This folder is identical in both locations and contains the same set of functions for factor estimation.
* **Third-Party Toolboxes**: The `codeForForecast` folder also includes the toolboxes for specific methods used in the paper: Sparse PCA (`SpaSMRev1`; Sjöstrand et al., 2018), Independent Component Analysis (`ICARev1`; Moore, 2025), Forecast Combination (`ForecastCombinationRev1`; Panagiotopoulos, 2025), and Model Confidence Set (`ModelConfidenceSetRev1`; Hansen, Lunde, and Nason, 2011).

## How to Reproduce the Results

### Part 1: Reproducing the Empirical Analysis (Tables 6-11)

The empirical analysis is a multi-stage process. The main pipeline must be run first to generate the necessary forecast data, after which the final tables can be created.

#### **Stage A: Running the Main Forecast Pipeline**

This stage runs the entire out-of-sample forecasting exercise for all models and generates a single, consolidated data file containing all results.

1.  **Set Working Directory (CRITICAL STEP):** Before you begin, you must set your MATLAB **Current Folder** to the `codeForForecast` directory. This is essential for the master script to correctly locate all necessary functions and toolboxes.

2.  **Run the Master Script:** From within the `codeForForecast` directory, execute the master script:
    ```matlab
    run sMasterEmpiricalApplication.m
    ```

3.  **What the Script Does:**
    * The master script sequentially executes all the individual out-of-sample forecasting scripts (e.g., `USA_Rolling_Rev1_TestMDDM.m`, `USA_Rolling_Rev1_SparsePCA.m`).
    * Each of these scripts saves a `.mat` file containing its specific forecast results into a new folder named `OutputForecast`.
    * After all individual forecasts are generated, the master script runs `USA_Rolling_Rev1_CVAllModels_v2.m`. This final script loads all the previously generated `.mat` files, applies a rolling time-series cross-validation to select the optimal model parameters, and saves the final, consolidated results into a single file: `OutputForecast/USA_Rolling_Rev1_CVAllModels_v2.mat`.

    > **WARNING: Computational Time**
    > The script for the Gradient Boosting model (`USA_Rolling_Rev1_XGBoosting.m`) is computationally intensive and can take several days to complete on standard hardware. For convenience, its output file is already included in the repository, so you can comment out the line `run('USA_Rolling_Rev1_XGBoosting.m');` in the master script if you wish to skip this step.

#### **Stage B: Generating the Final Tables**

This stage can only be run after Stage A is complete and the `USA_Rolling_Rev1_CVAllModels_v2.mat` file has been generated.

1.  **Set Working Directory:** Set your MATLAB **Current Folder** to the `ReplicationTables` folder, which is located inside `codeForForecast`.

2.  **Run a Table Script:** From within the `ReplicationTables` directory, run any of the `sExportTable*.m` scripts to generate the corresponding table from the paper. For example:
    ```matlab
    run sExportTable6.m
    ```
    This will print the LaTeX code for Table 6 to the MATLAB command window.

3.  **How it Works:** The table-generation scripts are self-contained. They use relative paths (`addpath('..\OutputForecast')` and `addpath('..\ModelConfidenceSetRev1')`) to load the consolidated results file from the `OutputForecast` folder and the necessary functions for the Model Confidence Set tests.

### Part 2: Reproducing the Simulation Studies (Tables 1-5)

The simulation studies are self-contained and must be run from within their specific subfolders. The procedure for this part has not changed.

1.  **Set Working Directory:** To run a simulation, you must first navigate your MATLAB **Current Folder** into that specific table's directory. For example, to reproduce Table 1:
    ```matlab
    cd codeForSimulations/Table1/
    ```

2.  **Run the Simulation Script:** From within the table's directory, run the main script:
    ```matlab
    run MainFile_TAB1.m
    ```
    This script will perform the Monte Carlo simulation and save the results (a `.mat` file, an `.xlsx` file, and a `.tex` file) in the current directory (`.../Table1/`).

3.  **Comparison**: For direct comparison, the pre-computed results are available in the corresponding `outputFromSimulations/tables/` subfolder (e.g., `outputFromSimulations/tables/tab1/`).

    > **Note on Table 3 and Computation Time:** The simulation for Table 3 can be computationally lengthy. As a time-saving alternative, you can use the `cut=true` option in the `seqTest.m` function. We provide pre-computed results generated with this setting, which are available in the specific subfolder: **`outputFromSimulations/tables/tab3/cutTrue/`**. These results were also generated with a fixed seed to ensure reproducibility and allow you to inspect the outcomes without running the most time-intensive simulation.

## Technical Notes

### Sequential Testing Algorithm: `seqTest.m`

The function `seqTest.m` implements the sequential testing procedure for factor selection in FMMDE models, as described in Section 3 of the paper. This function is a core component of the simulation studies and is used to determine the number of latent factors in the model.

#### Function Arguments

* `Y`: A T x p matrix of the time series data (T observations, p variables).
* `B`: The number of bootstrap replicates used to approximate p-values.
* `crit`: The critical p-value threshold for the test (e.g., 0.05).
* `k0`: The number of lags used for computing the cumulative Martingale Difference Divergence Matrix (MDDM).
* `boot`: A string specifying the bootstrap type. Can be `'radem'` for Rademacher (default) or `'esc'` for Mammen distribution.
* `cut`: A logical value (`true` or `false`). If `true`, the bootstrap procedure is applied only to a truncated fraction (one-third) of the estimated factors. This is a crucial time-saving feature for computationally intensive simulations. See **Appendix B** of the paper for more details on this truncation solution.

### Saving Large Data Files: The `-v7.3` Flag

In the forecasting scripts for Sparse PCA and XGBoosting (`USA_Rolling_Rev1_SparsePCA.m` and `USA_Rolling_Rev1_XGBoosting.m`), the `save` command includes the `-v7.3` flag. This is a necessary technical choice to handle the large size of the output variables. This flag instructs MATLAB to use the Version 7.3 MAT-file format, which is based on HDF5 and can store variables larger than 2 GB. Without this flag, saving the extensive results from these models would result in an error.

## Data Information

* **Simulation Data**: The data for the simulation studies (Tables 1-5) is generated by the scripts located in `codeForSimulations/DGPs/`.
* **Empirical Data**:
    * The primary empirical analysis uses the **FRED-MD database** (McCracken & Ng, 2016). This is a publicly available dataset of 119 U.S. monthly macroeconomic variables spanning from January 1959 to January 2024. The data can be accessed online at: <https://www.stlouisfed.org/research/economists/mccracken/fred-databases>. As described in the paper, all series are pre-processed to ensure stationarity. The necessary data file, `current_May2024.csv`, is included in the `codeForForecast/Data` folder.
    * For the analysis including the COVID-19 pandemic, the model uses data on monthly deaths to 'de-COVID' the series, following the approach of **Ng (2021)**. The required data file, `dataCovidSerenaNg.csv`, is also included in the `codeForForecast/Data` folder. This conditional mean cleaning is performed by the `fMeanClean.m` function.

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
    * Symbolic Math Toolbox Version 9.2 (R2022b)

### Empirical Analysis

* **Hardware**:
    * **Model**: MacBook Pro (MacBookPro18,2)
    * **Chip**: Apple M1 Max (10 cores: 8 performance, 2 efficiency)
    * **Memory**: 64 GB
    * **OS**: macOS
* **Software**: The software environment (MATLAB version and toolboxes) is the same as that used for the Simulation Analysis.

## License

This package is licensed under the MIT License (see `LICENSE` file).

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
