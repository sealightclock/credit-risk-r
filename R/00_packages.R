# =========================================================
# 00_packages.R
# Purpose:
#   Install and load the packages needed by this project.
#
# Why keep this file:
#   - makes setup easier on a new computer
#   - keeps package management in one place
#   - helps readers understand the project dependencies
# =========================================================

# Package list for the current project.
#
# Notes:
# - tidyverse covers most day-to-day data work:
#   dplyr, ggplot2, readr, tidyr, tibble, stringr, etc.
# - some packages below are only needed for optional parts:
#   quarto = report rendering
#   xgboost = advanced model
#   shiny   = dashboard app
required_packages <- c(
  "tidyverse",  # data wrangling, charts, CSV reading, text handling
  "lubridate",  # easier date parsing and date calculations
  "janitor",    # clean column names like "Bank Name" -> "bank_name"
  "yardstick",  # model metrics like accuracy, AUC, precision, recall
  "ranger",     # random forest model
  "quantmod",   # download FRED macro data
  "quarto",     # render the final report
  "xgboost",    # optional advanced boosting model
  "shiny"       # optional interactive dashboard
)

# Install any packages that are missing.
install_if_missing <- function(pkgs) {
  installed <- rownames(installed.packages())
  missing_pkgs <- setdiff(pkgs, installed)
  
  if (length(missing_pkgs) > 0) {
    install.packages(missing_pkgs)
  }
}

install_if_missing(required_packages)

# Load all packages into the current R session.
invisible(lapply(required_packages, library, character.only = TRUE))

# Optional quick message so beginners can confirm setup worked.
message("Packages loaded successfully.")
