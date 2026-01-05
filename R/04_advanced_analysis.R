#!/usr/bin/env Rscript
# =============================================================================
# 04_advanced_analysis.R
# Advanced ecological analyses for Carpinteria Salt Marsh fish data
# =============================================================================

# Load packages
suppressPackageStartupMessages({
  library(tidyverse)
  library(vegan)
  library(lubridate)
})

# Configuration
DATA_DIR <- here::here("data", "raw")
OUTPUT_DIR <- here::here("outputs")

# =============================================================================
# 1. LOAD DATA
# =============================================================================

cat("=== Loading Data ===\n")

# Load previous results
results <- readRDS(file.path(OUTPUT_DIR, "analysis_results.rds"))

# Load raw data
ps_data <- read_csv(
  file.path(DATA_DIR, "edi.648.8", "wetland_ps_fish_abundance_and_richness.csv"),
  show_col_types = FALSE
) %>%
  filter(wetland_code == "CSM")

seine_data <- read_csv(
  file.path(DATA_DIR, "edi.647.8", "wetland_ts_fish_seine.csv"),
  show_col_types = FALSE
) %>%
  filter(wetland_code == "CSM")

enclosure_data <- read_csv(
  file.path(DATA_DIR, "edi.647.8", "wetland_ts_fish_enclosure.csv"),
  show_col_types = FALSE
) %>%
  filter(wetland_code == "CSM")

# =============================================================================
# 2. SEASONALITY ANALYSIS
# =============================================================================

cat("\n=== Seasonality Analysis ===\n")

# Extract month from date
seine_seasonal <- seine_data %>%
  mutate(
    date = as.Date(date),
    month = month(date),
    season = case_when(
      month %in% c(12, 1, 2) ~ "Winter",
      month %in% c(3, 4, 5) ~ "Spring",
      month %in% c(6, 7, 8) ~ "Summer",
      month %in% c(9, 10, 11) ~ "Fall"
    ),
    season = factor(season, levels = c("Winter", "Spring", "Summer", "Fall"))
  )

# Monthly abundance patterns
monthly_abundance <- seine_seasonal %>%
  group_by(month) %>%
  summarize(
    total_count = sum(count, na.rm = TRUE),
    mean_count = mean(count, na.rm = TRUE),
    n_samples = n_distinct(paste(year, date)),
    .groups = "drop"
  ) %>%
  mutate(
    month_name = month.abb[month],
    cpue = total_count / n_samples  # Catch per unit effort
  )

# Seasonal patterns
seasonal_abundance <- seine_seasonal %>%
  group_by(season) %>%
  summarize(
    total_count = sum(count, na.rm = TRUE),
    mean_count = mean(count, na.rm = TRUE),
    n_samples = n_distinct(paste(year, date)),
    species_richness = n_distinct(species_code[count > 0]),
    .groups = "drop"
  ) %>%
  mutate(cpue = total_count / n_samples)

# Species-specific seasonality (top 10 species)
top_species <- seine_data %>%
  group_by(species_code) %>%
  summarize(total = sum(count), .groups = "drop") %>%
  arrange(desc(total)) %>%
  head(10) %>%
  pull(species_code)

species_seasonality <- seine_seasonal %>%
  filter(species_code %in% top_species) %>%
  group_by(species_code, month) %>%
  summarize(
    total_count = sum(count, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(species_code) %>%
  mutate(
    max_count = max(total_count),
    normalized = total_count / max_count,
    peak_month = month[which.max(total_count)]
  ) %>%
  ungroup()

cat(sprintf("  Peak abundance month: %s\n",
            month.abb[monthly_abundance$month[which.max(monthly_abundance$cpue)]]))

# =============================================================================
# 3. COMMUNITY STABILITY METRICS
# =============================================================================

cat("\n=== Community Stability Analysis ===\n")

# Year-to-year turnover using Bray-Curtis
year_matrix <- seine_data %>%
  filter(count > 0) %>%
  group_by(year, species_code) %>%
  summarize(count = sum(count), .groups = "drop") %>%
  pivot_wider(names_from = species_code, values_from = count, values_fill = 0) %>%
  column_to_rownames("year") %>%
  as.matrix()

# Calculate turnover between consecutive years
years <- as.numeric(rownames(year_matrix))
turnover <- data.frame(
  year = years[-1],
  turnover = NA
)

for (i in 2:length(years)) {
  bc <- vegdist(year_matrix[c(i-1, i), ], method = "bray")
  turnover$turnover[i-1] <- as.numeric(bc)
}

# Coefficient of variation for each species
species_cv <- seine_data %>%
  group_by(year, species_code) %>%
  summarize(annual_count = sum(count), .groups = "drop") %>%
  group_by(species_code) %>%
  summarize(
    mean_abundance = mean(annual_count),
    sd_abundance = sd(annual_count),
    cv = sd_abundance / mean_abundance,
    years_present = sum(annual_count > 0),
    .groups = "drop"
  ) %>%
  filter(mean_abundance > 0)

# Core vs satellite species
n_years <- n_distinct(seine_data$year)
core_satellite <- species_cv %>%
  mutate(
    occupancy = years_present / n_years,
    category = case_when(
      occupancy >= 0.8 ~ "Core",
      occupancy >= 0.4 ~ "Common",
      TRUE ~ "Satellite"
    )
  )

cat(sprintf("  Core species (>80%% years): %d\n",
            sum(core_satellite$category == "Core")))
cat(sprintf("  Satellite species (<40%% years): %d\n",
            sum(core_satellite$category == "Satellite")))
cat(sprintf("  Mean year-to-year turnover: %.3f\n", mean(turnover$turnover, na.rm = TRUE)))

# =============================================================================
# 4. ECOLOGICAL GUILD ANALYSIS
# =============================================================================

cat("\n=== Ecological Guild Analysis ===\n")

# Define ecological guilds based on species ecology
# These are based on standard estuarine fish guild classifications
guild_definitions <- tribble(
  ~species_code, ~common_name, ~feeding_guild, ~habitat_guild,
  "ATAF", "Topsmelt", "Planktivore", "Marine Migrant",
  "FUPA", "California Killifish", "Omnivore", "Resident",
  "ATFA", "Atherinopsidae", "Planktivore", "Marine Migrant",
  "POMY", "Shiner Perch", "Omnivore", "Marine Migrant",
  "LEAR", "Arrow Goby", "Benthivore", "Resident",
  "PACA", "Barred Sand Bass", "Piscivore", "Marine Migrant",
  "GIMI", "Longjaw Mudsucker", "Omnivore", "Resident",
  "PAMA", "Spotted Sand Bass", "Piscivore", "Marine Migrant",
  "ACFV", "Yellowfin Goby", "Benthivore", "Resident",
  "CYAG", "Shiner Surfperch", "Omnivore", "Marine Migrant",
  "URHA", "Round Stingray", "Benthivore", "Marine Migrant",
  "SEPO", "Barred Surfperch", "Benthivore", "Marine Migrant",
  "MUCE", "Striped Mullet", "Detritivore", "Marine Migrant",
  "HYGU", "Diamond Turbot", "Benthivore", "Marine Migrant",
  "SPAR", "California Halibut", "Piscivore", "Marine Migrant"
)

# Join guild info with abundance data
guild_abundance <- seine_data %>%
  filter(count > 0) %>%
  left_join(guild_definitions, by = "species_code") %>%
  filter(!is.na(feeding_guild))

# Feeding guild composition over time
feeding_guild_trends <- guild_abundance %>%
  group_by(year, feeding_guild) %>%
  summarize(total_count = sum(count), .groups = "drop") %>%
  group_by(year) %>%
  mutate(
    year_total = sum(total_count),
    proportion = total_count / year_total
  ) %>%
  ungroup()

# Habitat guild composition over time
habitat_guild_trends <- guild_abundance %>%
  group_by(year, habitat_guild) %>%
  summarize(total_count = sum(count), .groups = "drop") %>%
  group_by(year) %>%
  mutate(
    year_total = sum(total_count),
    proportion = total_count / year_total
  ) %>%
  ungroup()

# Current guild composition
current_feeding_guilds <- feeding_guild_trends %>%
  group_by(feeding_guild) %>%
  summarize(
    mean_proportion = mean(proportion),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_proportion))

current_habitat_guilds <- habitat_guild_trends %>%
  group_by(habitat_guild) %>%
  summarize(
    mean_proportion = mean(proportion),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_proportion))

cat("  Feeding guild composition:\n")
for (i in 1:nrow(current_feeding_guilds)) {
  cat(sprintf("    %s: %.1f%%\n",
              current_feeding_guilds$feeding_guild[i],
              current_feeding_guilds$mean_proportion[i] * 100))
}

# =============================================================================
# 5. RANK-ABUNDANCE DISTRIBUTION
# =============================================================================

cat("\n=== Rank-Abundance Analysis ===\n")

# Calculate rank-abundance
rank_abundance <- seine_data %>%
  filter(count > 0) %>%
  group_by(species_code) %>%
  summarize(total_abundance = sum(count), .groups = "drop") %>%
  arrange(desc(total_abundance)) %>%
  mutate(
    rank = row_number(),
    log_abundance = log10(total_abundance),
    proportion = total_abundance / sum(total_abundance),
    cumulative_proportion = cumsum(proportion)
  )

# Dominance metrics
dominance_1 <- rank_abundance$proportion[1]  # Single species dominance
dominance_3 <- sum(rank_abundance$proportion[1:3])  # Top 3 dominance
dominance_5 <- sum(rank_abundance$proportion[1:5])  # Top 5 dominance

cat(sprintf("  Top species dominance: %.1f%%\n", dominance_1 * 100))
cat(sprintf("  Top 3 species: %.1f%%\n", dominance_3 * 100))
cat(sprintf("  Top 5 species: %.1f%%\n", dominance_5 * 100))

# =============================================================================
# 6. INTERANNUAL VARIABILITY
# =============================================================================

cat("\n=== Interannual Variability ===\n")

# Calculate CV for total community
annual_totals <- seine_data %>%
  group_by(year) %>%
  summarize(total_count = sum(count), .groups = "drop")

community_cv <- sd(annual_totals$total_count) / mean(annual_totals$total_count)

# Stability metrics
stability_metrics <- list(
  community_cv = community_cv,
  mean_turnover = mean(turnover$turnover, na.rm = TRUE),
  max_turnover = max(turnover$turnover, na.rm = TRUE),
  min_turnover = min(turnover$turnover, na.rm = TRUE),
  turnover_trend = cor(turnover$year, turnover$turnover, use = "complete.obs")
)

cat(sprintf("  Community CV: %.3f\n", community_cv))
cat(sprintf("  Turnover trend: r = %.3f\n", stability_metrics$turnover_trend))

# =============================================================================
# 7. NURSERY FUNCTION ASSESSMENT
# =============================================================================

cat("\n=== Nursery Function Assessment ===\n")

# Calculate proportion of juvenile species (using marine migrants as proxy)
nursery_species <- c("ATAF", "POMY", "PACA", "PAMA", "URHA", "HYGU", "SPAR")

nursery_assessment <- seine_data %>%
  mutate(is_nursery = species_code %in% nursery_species) %>%
  group_by(year) %>%
  summarize(
    nursery_count = sum(count[is_nursery]),
    total_count = sum(count),
    nursery_proportion = nursery_count / total_count,
    nursery_species_richness = n_distinct(species_code[is_nursery & count > 0]),
    .groups = "drop"
  )

mean_nursery_prop <- mean(nursery_assessment$nursery_proportion, na.rm = TRUE)
cat(sprintf("  Mean nursery species proportion: %.1f%%\n", mean_nursery_prop * 100))

# =============================================================================
# 8. COMPILE AND SAVE ADVANCED RESULTS
# =============================================================================

cat("\n=== Saving Advanced Results ===\n")

advanced_results <- list(
  seasonality = list(
    monthly = monthly_abundance %>% select(month, month_name, cpue, n_samples),
    seasonal = seasonal_abundance,
    species_peaks = species_seasonality %>%
      group_by(species_code) %>%
      summarize(
        peak_month = first(peak_month),
        peak_month_name = month.abb[first(peak_month)],
        .groups = "drop"
      )
  ),

  stability = list(
    turnover = turnover,
    community_cv = community_cv,
    metrics = stability_metrics
  ),

  core_satellite = list(
    summary = core_satellite %>%
      group_by(category) %>%
      summarize(
        n_species = n(),
        mean_cv = mean(cv, na.rm = TRUE),
        .groups = "drop"
      ),
    species = core_satellite %>%
      select(species_code, occupancy, cv, category) %>%
      arrange(desc(occupancy))
  ),

  guilds = list(
    definitions = guild_definitions,
    feeding_trends = feeding_guild_trends,
    habitat_trends = habitat_guild_trends,
    feeding_summary = current_feeding_guilds,
    habitat_summary = current_habitat_guilds
  ),

  rank_abundance = list(
    data = rank_abundance %>% select(species_code, rank, total_abundance, proportion, log_abundance),
    dominance = list(
      top_1 = dominance_1,
      top_3 = dominance_3,
      top_5 = dominance_5
    )
  ),

  nursery = nursery_assessment
)

# Update the main results object
results$advanced <- advanced_results

# Save updated results
saveRDS(results, file.path(OUTPUT_DIR, "analysis_results.rds"))
cat("  Saved: analysis_results.rds (updated with advanced analyses)\n")

cat("\nAdvanced analysis complete.\n")
