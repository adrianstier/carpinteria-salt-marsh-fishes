#!/usr/bin/env Rscript
# =============================================================================
# 05_export_advanced_json.R
# Export advanced analysis results to JSON for D3.js dashboard
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(jsonlite)
})

OUTPUT_DIR <- here::here("outputs")

cat("=== Exporting Advanced Results to JSON ===\n")

# Load analysis results
results <- readRDS(file.path(OUTPUT_DIR, "analysis_results.rds"))

# Check if advanced results exist
if (!"advanced" %in% names(results)) {
  stop("Advanced results not found. Run 04_advanced_analysis.R first.")
}

# Load existing dashboard data
dashboard_file <- file.path(OUTPUT_DIR, "dashboard_data.json")
if (file.exists(dashboard_file)) {
  dashboard_data <- fromJSON(dashboard_file)
} else {
  dashboard_data <- list()
}

# =============================================================================
# Add advanced analysis results
# =============================================================================

# Seasonality data for charts
dashboard_data$advanced <- list(
  seasonality = list(
    monthly = results$advanced$seasonality$monthly %>%
      mutate(month_name = factor(month_name, levels = month.abb)) %>%
      arrange(month) %>%
      as.data.frame(),
    seasonal = results$advanced$seasonality$seasonal %>% as.data.frame(),
    species_peaks = results$advanced$seasonality$species_peaks %>% as.data.frame()
  ),

  stability = list(
    turnover = results$advanced$stability$turnover %>% as.data.frame(),
    community_cv = results$advanced$stability$community_cv,
    mean_turnover = results$advanced$stability$metrics$mean_turnover,
    turnover_trend = results$advanced$stability$metrics$turnover_trend
  ),

  core_satellite = list(
    summary = results$advanced$core_satellite$summary %>% as.data.frame(),
    species = results$advanced$core_satellite$species %>%
      head(20) %>%  # Top 20 for display
      as.data.frame()
  ),

  guilds = list(
    feeding_summary = results$advanced$guilds$feeding_summary %>% as.data.frame(),
    habitat_summary = results$advanced$guilds$habitat_summary %>% as.data.frame(),
    feeding_trends = results$advanced$guilds$feeding_trends %>% as.data.frame(),
    habitat_trends = results$advanced$guilds$habitat_trends %>% as.data.frame()
  ),

  rank_abundance = list(
    data = results$advanced$rank_abundance$data %>%
      head(20) %>%  # Top 20 species
      as.data.frame(),
    dominance = results$advanced$rank_abundance$dominance
  ),

  nursery = results$advanced$nursery %>% as.data.frame()
)

# Update meta
dashboard_data$meta$advanced_generated <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
dashboard_data$meta$advanced_analyses <- c(
  "seasonality",
  "community_stability",
  "core_satellite_species",
  "ecological_guilds",
  "rank_abundance",
  "nursery_function"
)

# =============================================================================
# Save updated JSON
# =============================================================================

# Write with pretty formatting
json_output <- toJSON(dashboard_data, pretty = TRUE, auto_unbox = TRUE)
writeLines(json_output, dashboard_file)

cat(sprintf("  Updated: %s\n", dashboard_file))
cat(sprintf("  Added %d advanced analysis sections\n",
            length(dashboard_data$meta$advanced_analyses)))

cat("\nJSON export complete.\n")
