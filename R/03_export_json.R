#!/usr/bin/env Rscript
# =============================================================================
# 03_export_json.R
# Export R analysis results to JSON for D3 frontend
# =============================================================================

library(tidyverse)
library(jsonlite)

OUTPUT_DIR <- here::here("outputs")

cat("=== Exporting Analysis Results to JSON ===\n")

# Load R analysis results
results <- readRDS(file.path(OUTPUT_DIR, "analysis_results.rds"))

# =============================================================================
# PREPARE JSON STRUCTURE FOR D3
# =============================================================================

# Convert data frames to lists for proper JSON serialization
dashboard_data <- list(

  # -----------------------------------------------------------------------------
  # META
  # -----------------------------------------------------------------------------
  meta = list(
    source = "R Statistical Analysis",
    generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
    r_version = R.version.string,
    packages = c("vegan", "Kendall", "lme4", "mgcv")
  ),

  # -----------------------------------------------------------------------------
  # SUMMARY
  # -----------------------------------------------------------------------------
  summary = list(
    years_of_data = results$summary$years_of_data,
    year_range = list(
      start = results$summary$year_range[1],
      end = results$summary$year_range[2]
    ),
    total_species = results$summary$total_species,
    total_samples = results$summary$total_samples,
    enclosure_records = results$summary$enclosure_records,
    seine_records = results$summary$seine_records
  ),

  # -----------------------------------------------------------------------------
  # MODEL RESULTS
  # -----------------------------------------------------------------------------
  model_results = list(

    # Habitat comparison (t-tests)
    habitat_comparison = list(
      tidal_creek = list(
        mean_density = round(results$model_results$habitat_comparison$tidal_creek$mean_density, 2),
        std_density = round(results$model_results$habitat_comparison$tidal_creek$std_density, 2),
        mean_richness = round(results$model_results$habitat_comparison$tidal_creek$mean_richness, 2),
        std_richness = round(results$model_results$habitat_comparison$tidal_creek$std_richness, 2),
        n = results$model_results$habitat_comparison$tidal_creek$n
      ),
      main_channel = list(
        mean_density = round(results$model_results$habitat_comparison$main_channel$mean_density, 2),
        std_density = round(results$model_results$habitat_comparison$main_channel$std_density, 2),
        mean_richness = round(results$model_results$habitat_comparison$main_channel$mean_richness, 2),
        std_richness = round(results$model_results$habitat_comparison$main_channel$std_richness, 2),
        n = results$model_results$habitat_comparison$main_channel$n
      ),
      density_test = list(
        t_statistic = round(results$model_results$habitat_comparison$density_test$t_statistic, 3),
        p_value = signif(results$model_results$habitat_comparison$density_test$p_value, 4),
        cohens_d = round(results$model_results$habitat_comparison$density_test$cohens_d, 3),
        significant = results$model_results$habitat_comparison$density_test$significant
      ),
      richness_test = list(
        t_statistic = round(results$model_results$habitat_comparison$richness_test$t_statistic, 3),
        p_value = signif(results$model_results$habitat_comparison$richness_test$p_value, 4),
        cohens_d = round(results$model_results$habitat_comparison$richness_test$cohens_d, 3),
        significant = results$model_results$habitat_comparison$richness_test$significant
      )
    ),

    # Temporal trends (Mann-Kendall)
    temporal_trends = list(
      years = results$model_results$temporal_trends$years,
      annual_density = round(results$model_results$temporal_trends$annual_density, 2),
      annual_richness = round(results$model_results$temporal_trends$annual_richness, 2),
      density_trend = list(
        sens_slope = round(results$model_results$temporal_trends$density_trend$sens_slope, 4),
        tau = round(results$model_results$temporal_trends$density_trend$tau, 3),
        p_value = signif(results$model_results$temporal_trends$density_trend$p_value, 4),
        trend = results$model_results$temporal_trends$density_trend$trend
      )
    ),

    # Diversity indices
    diversity = list(
      shannon = round(results$model_results$diversity$shannon, 3),
      simpson = round(results$model_results$diversity$simpson, 3),
      evenness = round(results$model_results$diversity$evenness, 3),
      richness = results$model_results$diversity$richness
    ),

    # Species accumulation curve
    accumulation = list(
      sites = results$model_results$accumulation$sites,
      richness = round(results$model_results$accumulation$richness, 1),
      sd = round(results$model_results$accumulation$sd, 2),
      method = results$model_results$accumulation$method
    ),

    # Beta diversity
    beta_diversity = list(
      method = results$model_results$beta_diversity$method,
      mean_dissimilarity = round(results$model_results$beta_diversity$mean_dissimilarity, 3),
      min_dissimilarity = round(results$model_results$beta_diversity$min_dissimilarity, 3),
      max_dissimilarity = round(results$model_results$beta_diversity$max_dissimilarity, 3)
    ),

    # NMDS ordination
    nmds = list(
      stress = round(results$model_results$nmds$stress, 3),
      converged = results$model_results$nmds$converged,
      points = lapply(1:nrow(results$model_results$nmds$points), function(i) {
        list(
          year = as.character(results$model_results$nmds$points$year[i]),
          x = round(results$model_results$nmds$points$NMDS1[i], 4),
          y = round(results$model_results$nmds$points$NMDS2[i], 4)
        )
      })
    ),

    # GLM results
    glm = list(
      formula = results$model_results$glm$formula,
      coefficients = list(
        intercept = round(results$model_results$glm$coefficients$intercept, 3),
        habitat_effect = round(results$model_results$glm$coefficients$habitat_main_channel, 3),
        year_effect = round(results$model_results$glm$coefficients$year, 4)
      ),
      p_values = list(
        intercept = signif(results$model_results$glm$p_values$intercept, 4),
        habitat = signif(results$model_results$glm$p_values$habitat, 4),
        year = signif(results$model_results$glm$p_values$year, 4)
      ),
      r_squared = round(results$model_results$glm$r_squared, 3),
      aic = round(results$model_results$glm$aic, 1)
    ),

    # GAM results
    gam = list(
      formula = results$model_results$gam$formula,
      smooth_year = list(
        edf = round(results$model_results$gam$smooth_terms$year$edf, 2),
        F_stat = round(results$model_results$gam$smooth_terms$year$F_stat, 2),
        p_value = signif(results$model_results$gam$smooth_terms$year$p_value, 4)
      ),
      deviance_explained = round(results$model_results$gam$deviance_explained * 100, 1),
      r_squared = round(results$model_results$gam$r_squared, 3),
      predictions = list(
        years = round(results$model_results$gam$predictions$years, 1),
        fitted = round(results$model_results$gam$predictions$fitted, 2),
        se = round(results$model_results$gam$predictions$se, 2)
      )
    ),

    # Mixed model results
    mixed_model = if (!is.null(results$model_results$mixed_model$error)) {
      list(error = results$model_results$mixed_model$error)
    } else {
      list(
        formula = results$model_results$mixed_model$formula,
        fixed_effects = list(
          intercept = round(results$model_results$mixed_model$fixed_effects$intercept, 3),
          habitat = round(results$model_results$mixed_model$fixed_effects$habitat, 3),
          year = round(results$model_results$mixed_model$fixed_effects$year, 4)
        ),
        random_effects = list(
          location_variance = round(results$model_results$mixed_model$random_effects$location_variance, 3),
          residual_variance = round(results$model_results$mixed_model$random_effects$residual_variance, 3),
          icc = round(results$model_results$mixed_model$random_effects$icc, 3),
          location_intercepts = lapply(1:nrow(results$model_results$mixed_model$random_effects$location_intercepts), function(i) {
            list(
              location = results$model_results$mixed_model$random_effects$location_intercepts$location[i],
              intercept = round(results$model_results$mixed_model$random_effects$location_intercepts$intercept[i], 3),
              lower = round(results$model_results$mixed_model$random_effects$location_intercepts$lower[i], 3),
              upper = round(results$model_results$mixed_model$random_effects$location_intercepts$upper[i], 3)
            )
          })
        ),
        n_locations = results$model_results$mixed_model$n_locations
      )
    }
  ),

  # -----------------------------------------------------------------------------
  # CHART DATA
  # -----------------------------------------------------------------------------
  charts = list(

    # Species abundance (for bar chart)
    species_abundance = lapply(1:nrow(results$charts$species_abundance), function(i) {
      list(
        species_code = results$charts$species_abundance$species_code[i],
        species_name = results$charts$species_abundance$species_name[i],
        count = results$charts$species_abundance$count[i]
      )
    }),

    # Annual trends (for line chart)
    annual_trends = lapply(1:nrow(results$charts$annual_trends), function(i) {
      list(
        year = results$charts$annual_trends$year[i],
        tc_density = round(results$charts$annual_trends$tc_density[i], 2),
        mc_density = round(results$charts$annual_trends$mc_density[i], 2),
        tc_richness = round(results$charts$annual_trends$tc_richness[i], 2),
        mc_richness = round(results$charts$annual_trends$mc_richness[i], 2)
      )
    }),

    # Heatmap data (species x year)
    heatmap = lapply(1:nrow(results$charts$heatmap), function(i) {
      list(
        year = results$charts$heatmap$year[i],
        species = results$charts$heatmap$species_code[i],
        count = results$charts$heatmap$count[i],
        normalized = round(results$charts$heatmap$normalized[i], 3)
      )
    })
  )
)

# =============================================================================
# WRITE JSON
# =============================================================================

# Write pretty-printed JSON
json_output <- toJSON(dashboard_data, pretty = TRUE, auto_unbox = TRUE)

output_file <- file.path(OUTPUT_DIR, "dashboard_data.json")
writeLines(json_output, output_file)

cat(sprintf("  Exported to: %s\n", output_file))
cat(sprintf("  File size: %.1f KB\n", file.size(output_file) / 1024))

# Also write to api subdirectory for backwards compatibility
api_dir <- file.path(OUTPUT_DIR, "api")
dir.create(api_dir, showWarnings = FALSE)
writeLines(json_output, file.path(api_dir, "dashboard_data.json"))
cat(sprintf("  Also exported to: %s\n", file.path(api_dir, "dashboard_data.json")))

cat("\nJSON export complete.\n")
