required_packages <- c(
  "tidyverse",
  "tidymodels",
  "data.table",
  "lubridate",
  "janitor",
  "skimr",
  "gt",
  "yardstick",
  "vip",
  "ranger",
  "quantmod",
  "arrow",
  "readr",
  "stringr",
  "forcats",
  "glue",
  "here",
  "quarto"
)

install_if_missing <- function(pkgs) {
  installed <- rownames(installed.packages())
  missing_pkgs <- setdiff(pkgs, installed)
  if (length(missing_pkgs) > 0) install.packages(missing_pkgs)
}

install_if_missing(required_packages)
invisible(lapply(required_packages, library, character.only = TRUE))
tidymodels_prefer()
