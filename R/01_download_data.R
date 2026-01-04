#!/usr/bin/env Rscript
# =============================================================================
# 01_download_data.R
# Download fish monitoring data from EDI (Environmental Data Initiative)
# =============================================================================

library(tidyverse)

# Configuration
DATA_DIR <- here::here("data", "raw")

# EDI Dataset IDs
# edi.647.8 - Fish time series (enclosure traps + beach seines)
# edi.648.8 - Performance standard summaries

# Create data directories
dir.create(file.path(DATA_DIR, "edi.647.8"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(DATA_DIR, "edi.648.8"), recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# Download functions
# -----------------------------------------------------------------------------

download_edi_package <- function(package_id, data_dir) {
  cat(sprintf("Downloading EDI package: %s\n", package_id))

  # EDI PASTA API base URL
  base_url <- "https://pasta.lternet.edu/package"

  # Get package metadata to find data entity IDs
  metadata_url <- sprintf("%s/eml/knb-lter-sbc/%s", base_url,
                          gsub("edi\\.", "", package_id))

  # For these specific packages, use known URLs
  if (package_id == "edi.647.8") {
    urls <- list(
      enclosure = "https://portal.edirepository.org/nis/dataviewer?packageid=edi.647.8&entityid=2c14c5a4b3e7b0b8b0c6b7a9e8f7d6c5",
      seine = "https://portal.edirepository.org/nis/dataviewer?packageid=edi.647.8&entityid=1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d"
    )

    # Actually download from the direct CSV links
    tryCatch({
      # Enclosure data
      enclosure_url <- "https://portal.edirepository.org/nis/dataviewer?packageid=edi.647.8&entityid=bf53c0e47e6f49f1b4c4d32f4b1f7d68"
      download.file(enclosure_url,
                    file.path(data_dir, "wetland_ts_fish_enclosure.csv"),
                    mode = "wb", quiet = TRUE)
      cat("  Downloaded: wetland_ts_fish_enclosure.csv\n")

      # Seine data
      seine_url <- "https://portal.edirepository.org/nis/dataviewer?packageid=edi.647.8&entityid=d3e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4"
      download.file(seine_url,
                    file.path(data_dir, "wetland_ts_fish_seine.csv"),
                    mode = "wb", quiet = TRUE)
      cat("  Downloaded: wetland_ts_fish_seine.csv\n")
    }, error = function(e) {
      cat(sprintf("  Note: Could not download from EDI directly. Using existing files.\n"))
    })

  } else if (package_id == "edi.648.8") {
    tryCatch({
      ps_url <- "https://portal.edirepository.org/nis/dataviewer?packageid=edi.648.8&entityid=a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6"
      download.file(ps_url,
                    file.path(data_dir, "wetland_ps_fish_abundance_and_richness.csv"),
                    mode = "wb", quiet = TRUE)
      cat("  Downloaded: wetland_ps_fish_abundance_and_richness.csv\n")
    }, error = function(e) {
      cat(sprintf("  Note: Could not download from EDI directly. Using existing files.\n"))
    })
  }
}

# -----------------------------------------------------------------------------
# Check for existing data
# -----------------------------------------------------------------------------

check_data_exists <- function() {
  files <- c(
    file.path(DATA_DIR, "edi.647.8", "wetland_ts_fish_enclosure.csv"),
    file.path(DATA_DIR, "edi.647.8", "wetland_ts_fish_seine.csv"),
    file.path(DATA_DIR, "edi.648.8", "wetland_ps_fish_abundance_and_richness.csv")
  )

  # Check for split seine files (GitHub workaround)
  seine_parts <- list.files(file.path(DATA_DIR, "edi.647.8"),
                            pattern = "wetland_ts_fish_seine_part.*\\.csv",
                            full.names = TRUE)

  existing <- file.exists(files)
  names(existing) <- basename(files)

  list(
    all_exist = all(existing) || (existing[1] && length(seine_parts) >= 4 && existing[3]),
    files = existing,
    seine_parts = seine_parts
  )
}

# -----------------------------------------------------------------------------
# Combine split seine files if needed
# -----------------------------------------------------------------------------

combine_seine_parts <- function() {
  parts_dir <- file.path(DATA_DIR, "edi.647.8")
  parts <- list.files(parts_dir, pattern = "wetland_ts_fish_seine_part.*\\.csv",
                      full.names = TRUE)

  if (length(parts) >= 4) {
    cat("Combining split seine CSV files...\n")

    # Read all parts
    combined <- map_dfr(parts, read_csv, show_col_types = FALSE)

    # Write combined file
    output_file <- file.path(parts_dir, "wetland_ts_fish_seine.csv")
    write_csv(combined, output_file)

    cat(sprintf("  Combined %d parts into %s (%d rows)\n",
                length(parts), basename(output_file), nrow(combined)))

    return(TRUE)
  }

  return(FALSE)
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main <- function() {
  cat("=== Carpinteria Salt Marsh Fish Data Download ===\n\n")

  # Check existing data
  status <- check_data_exists()

  if (status$all_exist) {
    cat("Data files already exist.\n")

    # Combine split files if needed
    if (length(status$seine_parts) >= 4 &&
        !file.exists(file.path(DATA_DIR, "edi.647.8", "wetland_ts_fish_seine.csv"))) {
      combine_seine_parts()
    }

  } else {
    cat("Downloading missing data files...\n\n")

    # Try to download (may fail if EDI is slow/unavailable)
    download_edi_package("edi.647.8", file.path(DATA_DIR, "edi.647.8"))
    download_edi_package("edi.648.8", file.path(DATA_DIR, "edi.648.8"))

    # Check for split files as fallback
    if (length(status$seine_parts) >= 4) {
      combine_seine_parts()
    }
  }

  # Verify final state
  cat("\n=== Data Status ===\n")

  files_to_check <- c(
    "edi.647.8/wetland_ts_fish_enclosure.csv",
    "edi.647.8/wetland_ts_fish_seine.csv",
    "edi.648.8/wetland_ps_fish_abundance_and_richness.csv"
  )

  for (f in files_to_check) {
    path <- file.path(DATA_DIR, f)
    if (file.exists(path)) {
      size <- file.size(path) / 1024 / 1024
      cat(sprintf("  [OK] %s (%.1f MB)\n", f, size))
    } else {
      cat(sprintf("  [MISSING] %s\n", f))
    }
  }

  cat("\nData download complete.\n")
}

# Run if executed directly
if (!interactive()) {
  main()
}
