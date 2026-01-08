#!/usr/bin/env Rscript
# =============================================================================
# 02_analysis.R
# Comprehensive statistical analysis of Carpinteria Salt Marsh fish data
# =============================================================================

# Load packages
suppressPackageStartupMessages({
  library(tidyverse)
  library(vegan)      # Community ecology: diversity, ordination, accumulation
  library(Kendall)    # Mann-Kendall trend test
  library(lme4)       # Mixed-effects models
  library(mgcv)       # GAMs
  library(broom)      # Tidy model outputs
})

# Configuration
DATA_DIR <- here::here("data", "raw")
OUTPUT_DIR <- here::here("outputs")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# =============================================================================
# 1. LOAD AND PREPARE DATA
# =============================================================================

cat("=== Loading Data ===\n")

# Performance standard data (annual summaries)
ps_data <- read_csv(
  file.path(DATA_DIR, "edi.648.8", "wetland_ps_fish_abundance_and_richness.csv"),
  show_col_types = FALSE
) %>%
  filter(wetland_code == "CSM")  # Carpinteria Salt Marsh only

# Enclosure trap data (gobies)
enclosure_data <- read_csv(
  file.path(DATA_DIR, "edi.647.8", "wetland_ts_fish_enclosure.csv"),
  show_col_types = FALSE
) %>%
  filter(wetland_code == "CSM")

# Beach seine data (larger fishes)
seine_data <- read_csv(
  file.path(DATA_DIR, "edi.647.8", "wetland_ts_fish_seine.csv"),
  show_col_types = FALSE
) %>%
  filter(wetland_code == "CSM")

cat(sprintf("  Performance data: %d records\n", nrow(ps_data)))
cat(sprintf("  Enclosure data: %d records\n", nrow(enclosure_data)))
cat(sprintf("  Seine data: %d records\n", nrow(seine_data)))

# =============================================================================
# 2. BASIC STATISTICS (matching Python)
# =============================================================================

cat("\n=== Basic Statistics ===\n")

# -----------------------------------------------------------------------------
# 2.1 Habitat Comparison (Welch's t-test)
# -----------------------------------------------------------------------------

# Prepare habitat-level summaries
habitat_data <- ps_data %>%
  mutate(habitat = ifelse(habitat_code == "TC", "tidal_creek", "main_channel"))

# Fish density by habitat
tc_density <- habitat_data %>% filter(habitat == "tidal_creek") %>% pull(count_per_m2)
mc_density <- habitat_data %>% filter(habitat == "main_channel") %>% pull(count_per_m2)

density_test <- t.test(tc_density, mc_density, var.equal = FALSE)

# Calculate Cohen's d manually
cohens_d_density <- (mean(tc_density) - mean(mc_density)) /
  sqrt((var(tc_density) + var(mc_density)) / 2)

# Species richness by habitat
tc_richness <- habitat_data %>% filter(habitat == "tidal_creek") %>% pull(species_count)
mc_richness <- habitat_data %>% filter(habitat == "main_channel") %>% pull(species_count)

richness_test <- t.test(tc_richness, mc_richness, var.equal = FALSE)

cohens_d_richness <- (mean(tc_richness) - mean(mc_richness)) /
  sqrt((var(tc_richness) + var(mc_richness)) / 2)

habitat_comparison <- list(
  tidal_creek = list(
    mean_density = mean(tc_density),
    std_density = sd(tc_density),
    mean_richness = mean(tc_richness),
    std_richness = sd(tc_richness),
    n = length(tc_density)
  ),
  main_channel = list(
    mean_density = mean(mc_density),
    std_density = sd(mc_density),
    mean_richness = mean(mc_richness),
    std_richness = sd(mc_richness),
    n = length(mc_density)
  ),
  density_test = list(
    t_statistic = unname(density_test$statistic),
    p_value = density_test$p.value,
    cohens_d = cohens_d_density,
    significant = density_test$p.value < 0.05
  ),
  richness_test = list(
    t_statistic = unname(richness_test$statistic),
    p_value = richness_test$p.value,
    cohens_d = cohens_d_richness,
    significant = richness_test$p.value < 0.05
  )
)

cat(sprintf("  Habitat density t-test: t=%.2f, p=%.4f, d=%.2f\n",
            density_test$statistic, density_test$p.value, cohens_d_density))

# -----------------------------------------------------------------------------
# 2.2 Temporal Trends (Mann-Kendall test)
# -----------------------------------------------------------------------------

annual_data <- ps_data %>%
  group_by(year) %>%
  summarize(
    mean_density = mean(count_per_m2, na.rm = TRUE),
    mean_richness = mean(species_count, na.rm = TRUE),
    .groups = "drop"
  )

# Mann-Kendall test for density trend
mk_density <- MannKendall(annual_data$mean_density)

# Sen's slope estimate
sen_slope_density <- function(y) {
  n <- length(y)
  slopes <- numeric(0)
  for (i in 1:(n-1)) {
    for (j in (i+1):n) {
      slopes <- c(slopes, (y[j] - y[i]) / (j - i))
    }
  }
  median(slopes)
}

temporal_trends <- list(
  years = annual_data$year,
  annual_density = annual_data$mean_density,
  annual_richness = annual_data$mean_richness,
  density_trend = list(
    sens_slope = sen_slope_density(annual_data$mean_density),
    tau = unname(mk_density$tau),
    p_value = mk_density$sl,
    trend = ifelse(mk_density$sl < 0.05,
                   ifelse(mk_density$tau > 0, "increasing", "decreasing"),
                   "stable")
  )
)

cat(sprintf("  Temporal trend: tau=%.3f, p=%.3f (%s)\n",
            mk_density$tau, mk_density$sl, temporal_trends$density_trend$trend))

# -----------------------------------------------------------------------------
# 2.3 Diversity Indices
# -----------------------------------------------------------------------------

# Create species abundance matrix from seine data
species_counts <- seine_data %>%
  filter(count > 0) %>%
  group_by(species_code) %>%
  summarize(total = sum(count), .groups = "drop") %>%
  arrange(desc(total))

abundance_vector <- species_counts$total

# Shannon diversity
shannon <- diversity(abundance_vector, index = "shannon")

# Simpson diversity (1 - D)
simpson <- diversity(abundance_vector, index = "simpson")

# Pielou's evenness
evenness <- shannon / log(length(abundance_vector))

diversity_indices <- list(
  shannon = shannon,
  simpson = simpson,
  evenness = evenness,
  richness = length(abundance_vector)
)

cat(sprintf("  Shannon H': %.3f, Simpson: %.3f, Evenness: %.3f\n",
            shannon, simpson, evenness))

# =============================================================================
# 3. EXPANDED ECOLOGY STATISTICS
# =============================================================================

cat("\n=== Ecological Analyses ===\n")

# -----------------------------------------------------------------------------
# 3.1 Species Accumulation Curve
# -----------------------------------------------------------------------------

# Create site x species matrix for seine data
seine_matrix <- seine_data %>%
  filter(count > 0) %>%
  mutate(site_id = paste(year, date, tc_mc_code, sep = "_")) %>%
  group_by(site_id, species_code) %>%
  summarize(count = sum(count), .groups = "drop") %>%
  pivot_wider(names_from = species_code, values_from = count, values_fill = 0) %>%
  column_to_rownames("site_id") %>%
  as.matrix()

# Species accumulation curve
spec_accum <- specaccum(seine_matrix, method = "random", permutations = 100)

accumulation_curve <- list(
  sites = spec_accum$sites,
  richness = spec_accum$richness,
  sd = spec_accum$sd,
  method = "random"
)

cat(sprintf("  Species accumulation: %d sites, %d species at saturation\n",
            max(spec_accum$sites), round(max(spec_accum$richness))))

# -----------------------------------------------------------------------------
# 3.2 Beta Diversity (Bray-Curtis)
# -----------------------------------------------------------------------------

# Calculate beta diversity between years
year_matrix <- seine_data %>%
  filter(count > 0) %>%
  group_by(year, species_code) %>%
  summarize(count = sum(count), .groups = "drop") %>%
  pivot_wider(names_from = species_code, values_from = count, values_fill = 0) %>%
  column_to_rownames("year") %>%
  as.matrix()

# Bray-Curtis dissimilarity
bc_dist <- vegdist(year_matrix, method = "bray")
bc_matrix <- as.matrix(bc_dist)

beta_diversity <- list(
  method = "bray-curtis",
  mean_dissimilarity = mean(bc_dist),
  min_dissimilarity = min(bc_dist),
  max_dissimilarity = max(bc_dist),
  years = rownames(year_matrix),
  matrix = bc_matrix
)

cat(sprintf("  Beta diversity (Bray-Curtis): mean=%.3f\n", mean(bc_dist)))

# -----------------------------------------------------------------------------
# 3.3 NMDS Ordination
# -----------------------------------------------------------------------------

# NMDS on year-level data
set.seed(42)
nmds <- metaMDS(year_matrix, distance = "bray", k = 2, trymax = 100,
                trace = 0, autotransform = FALSE)

nmds_results <- list(
  stress = nmds$stress,
  points = data.frame(
    year = rownames(year_matrix),
    NMDS1 = nmds$points[, 1],
    NMDS2 = nmds$points[, 2]
  ),
  converged = nmds$converged
)

cat(sprintf("  NMDS: stress=%.3f, converged=%s\n",
            nmds$stress, nmds$converged))

# =============================================================================
# 4. PREDICTIVE MODELS
# =============================================================================

cat("\n=== Predictive Models ===\n")

# Prepare modeling data
model_data <- ps_data %>%
  mutate(
    habitat = factor(ifelse(habitat_code == "TC", "Tidal Creek", "Main Channel")),
    year_centered = year - mean(year),
    location = tc_mc_code
  )

# -----------------------------------------------------------------------------
# 4.1 GLM: Fish density ~ habitat + year
# -----------------------------------------------------------------------------

glm_model <- glm(count_per_m2 ~ habitat + year_centered,
                 data = model_data, family = gaussian())

glm_summary <- summary(glm_model)

glm_results <- list(
  formula = "density ~ habitat + year",
  coefficients = list(
    intercept = coef(glm_model)[1],
    habitat_main_channel = coef(glm_model)[2],
    year = coef(glm_model)[3]
  ),
  p_values = list(
    intercept = coef(glm_summary)[1, 4],
    habitat = coef(glm_summary)[2, 4],
    year = coef(glm_summary)[3, 4]
  ),
  r_squared = 1 - (glm_summary$deviance / glm_summary$null.deviance),
  aic = AIC(glm_model)
)

cat(sprintf("  GLM R-squared: %.3f, AIC: %.1f\n",
            glm_results$r_squared, glm_results$aic))

# -----------------------------------------------------------------------------
# 4.2 GAM: Non-linear year effects
# -----------------------------------------------------------------------------

gam_model <- gam(count_per_m2 ~ habitat + s(year, k = 5),
                 data = model_data, method = "REML")

gam_summary <- summary(gam_model)

gam_results <- list(
  formula = "density ~ habitat + s(year)",
  parametric_terms = list(
    intercept = coef(gam_model)[1],
    habitat_effect = coef(gam_model)[2]
  ),
  smooth_terms = list(
    year = list(
      edf = gam_summary$s.table[1, 1],  # Effective degrees of freedom
      ref_df = gam_summary$s.table[1, 2],
      F_stat = gam_summary$s.table[1, 3],
      p_value = gam_summary$s.table[1, 4]
    )
  ),
  deviance_explained = gam_summary$dev.expl,
  r_squared = gam_summary$r.sq,
  aic = AIC(gam_model)
)

# Generate predictions for plotting
gam_predictions <- data.frame(
  year = seq(min(model_data$year), max(model_data$year), length.out = 50),
  habitat = factor("Tidal Creek", levels = levels(model_data$habitat))
) %>%
  mutate(
    predicted = predict(gam_model, newdata = ., type = "response"),
    se = predict(gam_model, newdata = ., type = "response", se.fit = TRUE)$se.fit
  )

gam_results$predictions <- list(
  years = gam_predictions$year,
  fitted = gam_predictions$predicted,
  se = gam_predictions$se
)

cat(sprintf("  GAM R-squared: %.3f, Deviance explained: %.1f%%\n",
            gam_results$r_squared, gam_results$deviance_explained * 100))

# -----------------------------------------------------------------------------
# 4.3 Mixed-Effects Model: Random intercepts for location
# -----------------------------------------------------------------------------

# Check if there's enough variation for mixed model
n_locations <- n_distinct(model_data$location)

if (n_locations > 3) {
  lmer_model <- lmer(count_per_m2 ~ habitat + year_centered + (1 | location),
                     data = model_data)

  lmer_summary <- summary(lmer_model)

  # Extract variance components
  var_comp <- as.data.frame(VarCorr(lmer_model))

  # Extract random effects (BLUPs) for caterpillar plot
  random_intercepts <- ranef(lmer_model)$location
  random_intercepts$location <- rownames(random_intercepts)
  names(random_intercepts)[1] <- "intercept"

  # Calculate confidence intervals for random effects
  re_se <- sqrt(var_comp$vcov[1])  # Standard error from location variance
  random_intercepts$lower <- random_intercepts$intercept - 1.96 * re_se
  random_intercepts$upper <- random_intercepts$intercept + 1.96 * re_se

  # Order by intercept value
  random_intercepts <- random_intercepts[order(random_intercepts$intercept), ]

  lmer_results <- list(
    formula = "density ~ habitat + year + (1|location)",
    fixed_effects = list(
      intercept = fixef(lmer_model)[1],
      habitat = fixef(lmer_model)[2],
      year = fixef(lmer_model)[3]
    ),
    random_effects = list(
      location_variance = var_comp$vcov[1],
      residual_variance = var_comp$vcov[2],
      icc = var_comp$vcov[1] / sum(var_comp$vcov),  # Intraclass correlation
      location_intercepts = random_intercepts
    ),
    n_locations = n_locations,
    aic = AIC(lmer_model),
    bic = BIC(lmer_model)
  )

  cat(sprintf("  Mixed model ICC: %.3f (%.1f%% variance at location level)\n",
              lmer_results$random_effects$icc,
              lmer_results$random_effects$icc * 100))
} else {
  lmer_results <- list(
    error = "Insufficient locations for mixed model",
    n_locations = n_locations
  )
  cat("  Mixed model: skipped (insufficient locations)\n")
}

# =============================================================================
# 5. CHART DATA PREPARATION
# =============================================================================

cat("\n=== Preparing Chart Data ===\n")

# Species abundance for bar chart
species_abundance <- seine_data %>%
  filter(count > 0) %>%
  group_by(species_code, species_name) %>%
  summarize(count = sum(count), .groups = "drop") %>%
  arrange(desc(count)) %>%
  head(15)

# Annual trends for line chart
annual_trends <- ps_data %>%
  group_by(year, habitat_code) %>%
  summarize(
    mean_density = mean(count_per_m2, na.rm = TRUE),
    mean_richness = mean(species_count, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = habitat_code,
    values_from = c(mean_density, mean_richness),
    names_sep = "_"
  ) %>%
  rename(
    tc_density = mean_density_TC,
    mc_density = mean_density_BNMC,
    tc_richness = mean_richness_TC,
    mc_richness = mean_richness_BNMC
  )

# Heatmap data (species x year)
heatmap_data <- seine_data %>%
  filter(count > 0) %>%
  group_by(year, species_code) %>%
  summarize(count = sum(count), .groups = "drop") %>%
  group_by(species_code) %>%
  mutate(
    max_count = max(count),
    normalized = count / max_count
  ) %>%
  ungroup() %>%
  filter(species_code %in% species_abundance$species_code[1:10])  # Top 10 species

cat("  Chart data prepared.\n")

# =============================================================================
# 6. SAVE RESULTS
# =============================================================================

cat("\n=== Saving Results ===\n")

# Compile all results
analysis_results <- list(
  meta = list(
    source = "R Analysis (02_analysis.R)",
    generated = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    r_version = R.version.string
  ),

  summary = list(
    years_of_data = n_distinct(ps_data$year),
    year_range = range(ps_data$year),
    total_species = n_distinct(c(enclosure_data$species_code, seine_data$species_code)),
    total_samples = n_distinct(paste(ps_data$year, ps_data$date, ps_data$tc_mc_code)),
    enclosure_records = nrow(enclosure_data),
    seine_records = nrow(seine_data)
  ),

  model_results = list(
    habitat_comparison = habitat_comparison,
    temporal_trends = temporal_trends,
    diversity = diversity_indices,
    accumulation = accumulation_curve,
    beta_diversity = beta_diversity,
    nmds = nmds_results,
    glm = glm_results,
    gam = gam_results,
    mixed_model = lmer_results
  ),

  charts = list(
    species_abundance = species_abundance,
    annual_trends = annual_trends,
    heatmap = heatmap_data
  )
)

# Save as RDS for R use
saveRDS(analysis_results, file.path(OUTPUT_DIR, "analysis_results.rds"))
cat("  Saved: analysis_results.rds\n")

cat("\nAnalysis complete.\n")
