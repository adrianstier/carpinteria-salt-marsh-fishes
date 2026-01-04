#!/usr/bin/env Rscript
# Install required packages

packages <- c("tidyverse", "vegan", "Kendall", "lme4", "mgcv", "jsonlite", "here", "broom")

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "\n")
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  } else {
    cat(pkg, "OK\n")
  }
}

cat("\nAll packages ready.\n")
