# ------------------------------------------------------------------------------
# This script downloads COVID-19 data for the United States using the COVID19 R package,
# including confirmed cases, hospitalizations, and deaths.
# The data is saved as 'dataCovidSerenaNg.csv' for later use in the forecasting project.
# ------------------------------------------------------------------------------

# Set the working directory to the appropriate folder
setwd("~/Library/CloudStorage/Dropbox/DistanceCovariance/Revisione/Revision1_IJF_May20_2024/FredDatasetRev1")

# Install required packages (only once)
# install.packages("COVID19")
# install.packages("bit64")
# install.packages("readr")

# Load necessary libraries
library(COVID19)  # For downloading COVID-19 datasets
library(bit64)    # For handling 64-bit integers
library(readr)    # For saving CSV files

# Retrieve COVID-19 data for the United States
# - level = 1: National level
# - start = "2020-01-01": Start date
# - end = Sys.Date(): Current date
# - gmr = TRUE: Include Google Mobility Report data
# - raw = FALSE: Preprocessed (cleaned) version
data <- covid19(country = "US", level = 1, start = "2020-01-01", end = Sys.Date(), gmr = TRUE, raw = FALSE)

# Convert the 'date' column to Date format
data$date <- as.Date(data$date)

# Select only the necessary columns: date, confirmed cases, hospitalizations, and deaths
nu <- data.frame(data$date, data$confirmed, data$hosp, data$deaths)

# Save the selected data as a CSV file
write_csv(nu, "dataCovidSerenaNg.csv")

# ------------------------------------------------------------------------------
# Notes:
# - Additional code for other data manipulations (dplyr, lubridate) is commented out,
#   because it is not necessary for this basic download task.
# - If needed, install dplyr or lubridate packages for advanced manipulations.
# ------------------------------------------------------------------------------

# (Optional) Example of reading and handling data locally:
# library(dplyr)
# library(lubridate)
# dir.create("data")
# x <- covid19(country = "US", level = 1, start = "2020-01-01", end = Sys.Date(), gmr = TRUE, raw = FALSE, dir = "data")

# (Optional) View the first few rows of the retrieved dataset:
# head(nu)

