function vt = fImportDataCovidRev1(filename)
% This function imports and processes monthly COVID-related data from a CSV file.
% It constructs first-differenced log transformations of confirmed cases and deaths.
% The file 'dataCovidSerenaNg.csv' is downloaded using the R code 'DownloadDataCovid.R'
%
% Inputs:
%   filename - String containing the path to the CSV file (e.g., "dataCovidSerenaNg.csv")
%
% Outputs:
%   vt - Matrix containing two columns:
%        (1) First difference of log confirmed cases
%        (2) First difference of log deaths
% 
% The function aligns the time series such that the COVID shock appears in March 2020.

%% Step 1: Read the CSV file
dCovid = readtable(filename); % Load the COVID data into a table

%% Step 2: Create a timetable with daily data
TTdCovid = timetable(dCovid.data_date, dCovid.data_deaths, dCovid.data_hosp, dCovid.data_confirmed);

%% Step 3: Aggregate daily data into monthly frequency
% Aggregation rule: take the last available value in each month
TTdCovidMonthly = convert2monthly(TTdCovid, "Aggregation", "lastvalue");

%% Step 4: Compute first differences of the log-transformed series
% Confirmed cases
vConfirmed = diff(log(TTdCovidMonthly.Var1)); 

% Deaths
vDeaths = diff(log(TTdCovidMonthly.Var3));

% (Note: Hospitalizations are read but not used — line commented out.)

%% Step 5: Combine the two series into one matrix
vt = [vConfirmed, vDeaths];

%% Step 6: Handle missing or infinite values
vt(isinf(vt)) = 0; % Replace infinite values (e.g., due to log(0)) with 0
vt(isnan(vt)) = 0; % Replace NaN values with 0

%% Step 7: Align the shock timing
% Since we took first differences, we lose one observation at the start.
% Add a row of zeros at the beginning to align with March 2020.
vt = [0 0; vt];

end