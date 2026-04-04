source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

fdic_files <- list.files(
  path = dir_raw_fdic,
  pattern = "\\.(csv|txt)$",
  full.names = TRUE
)

if (length(fdic_files) == 0) {
  stop("No FDIC raw files found in data_raw/fdic/. Add quarter-level Call Report bulk CSV/TXT files first.")
}

message("FDIC files found:")
print(fdic_files)

fdic_preview <- readr::read_csv(fdic_files[1], show_col_types = FALSE, n_max = 10)
print(names(fdic_preview))
print(fdic_preview)
