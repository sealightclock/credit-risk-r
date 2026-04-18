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

install_if_missing <- function(pkgs) {
  installed <- rownames(installed.packages())
  missing_pkgs <- setdiff(pkgs, installed)

  if (length(missing_pkgs) > 0) {
    install.packages(missing_pkgs)
  }
}

install_if_missing(required_packages)
invisible(lapply(required_packages, library, character.only = TRUE))
message("Packages loaded successfully.")
