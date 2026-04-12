# =========================================================
# 00_packages.R
# Purpose:
#   This file installs and loads all R packages needed by
#   the project.
#
# Why this file is useful:
#   - Keeps package setup in one place
#   - Makes the project easier to run on a new computer
#   - Helps readers quickly understand which libraries
#     the project depends on
# =========================================================

# This character vector lists every package used anywhere
# in the project.
required_packages <- c(
  # tidyverse:
  # A very common collection of packages for data analysis.
  # We use it for:
  # - dplyr: filtering, selecting, grouping, mutating
  # - ggplot2: charts
  # - tibble / tidyr / purrr: data structure and reshaping
  "tidyverse",
  
  # tidymodels:
  # A modeling framework that makes machine learning and
  # model evaluation more consistent and readable.
  # We use pieces of it such as yardstick for metrics,
  # and it also helps if the project grows later.
  "tidymodels",
  
  # data.table:
  # Very fast data reading and processing package.
  # Helpful when financial datasets become large.
  # In this beginner project, it is optional in many places,
  # but it is commonly used in real-world analytics work.
  "data.table",
  
  # lubridate:
  # Makes date parsing and date calculations easier.
  # We use it to handle reporting dates such as quarter-end.
  "lubridate",
  
  # janitor:
  # Helps clean column names into a simpler format.
  # Example:
  #   "Bank Name" -> "bank_name"
  # This makes coding easier and reduces typing mistakes.
  "janitor",
  
  # skimr:
  # Creates quick dataset summaries.
  # Useful during exploratory data analysis (EDA) to inspect
  # missing values, data types, and variable distributions.
  "skimr",
  
  # gt:
  # Creates nicely formatted tables for reports.
  # Helpful when presenting results in a polished way.
  "gt",
  
  # yardstick:
  # Used for model evaluation metrics such as:
  # - accuracy
  # - AUC
  # - precision
  # - recall
  # This is important for comparing model quality.
  "yardstick",
  
  # vip:
  # Stands for Variable Importance Plots.
  # Useful for understanding which features matter most
  # in some machine learning models.
  "vip",
  
  # ranger:
  # Fast implementation of random forest models.
  # We use it for the tree-based model in this project.
  "ranger",
  
  # quantmod:
  # Used to download financial and macroeconomic data.
  # In this project, we use it to pull FRED series.
  "quantmod",
  
  # arrow:
  # Useful for efficient reading/writing of larger datasets.
  # It is not always required for a small beginner project,
  # but it is good to have if the project grows later.
  "arrow",
  
  # readr:
  # Fast and beginner-friendly reading/writing of CSV files.
  # We use it for files such as watchlists and metrics.
  "readr",
  
  # stringr:
  # Makes string / text handling easier and more consistent.
  # Useful for cleaning text fields and shortening bank names
  # in charts and tables.
  "stringr",
  
  # forcats:
  # Helps work with factors (categorical variables).
  # Useful in modeling and charting when category order matters.
  "forcats",
  
  # glue:
  # Makes it easier to build strings with variables inside.
  # Helpful for readable messages, labels, and file paths.
  "glue",
  
  # here:
  # Helps build file paths relative to the project folder.
  # This makes scripts more portable across computers.
  "here",
  
  # quarto:
  # Used to render the final project report.
  # Example output:
  #   reports/credit_risk_report.html
  "quarto",
  
  # xgboost:
  # A powerful gradient boosting model.
  # We use it as an optional advanced model to compare with
  # logistic regression and random forest.
  "xgboost"
)

# This helper function checks whether each required package
# is already installed on the current computer.
#
# If a package is missing, it installs it automatically.
#
# Why this helps:
# - A new user can run the project more easily
# - You do not need to install packages one by one manually
install_if_missing <- function(pkgs) {
  # installed.packages() returns information about all
  # packages currently installed in R.
  installed <- rownames(installed.packages())
  
  # setdiff(pkgs, installed) returns the packages that are
  # required by the project but not yet installed.
  missing_pkgs <- setdiff(pkgs, installed)
  
  # Only install packages if at least one is missing.
  if (length(missing_pkgs) > 0) {
    install.packages(missing_pkgs)
  }
}

# Run the helper function on the full package list.
install_if_missing(required_packages)

# Load all required packages into the current R session.
#
# lapply(...) loops through the package names.
# library(..., character.only = TRUE) tells R to use the
# package name stored in the variable, not the literal word.
#
# invisible(...) prevents R from printing an unnecessary list
# of return values to the console.
invisible(lapply(required_packages, library, character.only = TRUE))

# tidymodels_prefer() tells R to prefer tidymodels functions
# when multiple packages contain functions with the same name.
#
# Example:
# Some packages define overlapping function names, and this
# setting helps reduce ambiguity inside modeling workflows.
tidymodels_prefer()