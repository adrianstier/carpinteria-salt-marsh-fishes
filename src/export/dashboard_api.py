"""
Generate the dashboard API JSON file.

This is the SINGLE SOURCE OF TRUTH for dashboard data.
The frontend fetches this file - no hardcoding in HTML.
"""

import json
from datetime import datetime
from pathlib import Path
import sys
import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from src.config import API_DIR, STATS_DIR
from src.etl.extract import (
    load_performance_standards,
    load_enclosure_data,
    load_seine_data,
    filter_to_csm
)
from src.etl.transform import (
    transform_performance_standards,
    transform_enclosure_data,
    transform_seine_data,
    get_species_totals,
    aggregate_annual_trends
)
from src.analysis.statistics import (
    compare_habitats,
    analyze_temporal_trends,
    calculate_shannon_diversity,
    calculate_simpson_diversity,
    calculate_evenness
)


def generate_dashboard_data() -> dict:
    """
    Generate the complete dashboard data structure.

    Returns:
        Dictionary ready for JSON serialization
    """
    print("=" * 60)
    print("Generating Dashboard API Data")
    print("=" * 60)

    # Load and transform data
    print("\n1. Loading raw data...")
    ps_raw = load_performance_standards()
    enc_raw = load_enclosure_data()
    seine_raw = load_seine_data()

    # Filter to Carpinteria Salt Marsh
    print("\n2. Filtering to CSM...")
    ps_csm = filter_to_csm(ps_raw)
    enc_csm = filter_to_csm(enc_raw)
    seine_csm = filter_to_csm(seine_raw)

    # Transform
    print("\n3. Transforming data...")
    ps_df = transform_performance_standards(ps_csm)
    enc_df = transform_enclosure_data(enc_csm)
    seine_df = transform_seine_data(seine_csm)

    # Run analyses
    print("\n4. Running statistical analyses...")

    # Habitat comparison
    habitat_comparison = compare_habitats(ps_df)

    # Temporal trends
    temporal = analyze_temporal_trends(ps_df)

    # Species abundance
    species_totals = get_species_totals(enc_df, seine_df)
    top_species = species_totals.head(15)  # Top 15 species

    # Diversity indices (from all species)
    all_counts = species_totals["count"].values
    shannon = calculate_shannon_diversity(all_counts)
    simpson = calculate_simpson_diversity(all_counts)
    richness = len(species_totals[species_totals["count"] > 0])
    evenness = calculate_evenness(shannon, richness)

    # Annual trends by habitat
    annual_by_habitat = aggregate_annual_trends(ps_df)

    # Build the API response
    print("\n5. Building API response...")

    api_data = {
        "meta": {
            "generated_at": datetime.now().isoformat(),
            "data_source": "edi.648.8, edi.647.8",
            "wetland": "Carpinteria Salt Marsh (CSM)",
            "description": "SONGS Mitigation Monitoring Program fish community data"
        },
        "summary": {
            "years_of_data": int(ps_df["year"].nunique()),
            "year_range": [int(ps_df["year"].min()), int(ps_df["year"].max())],
            "total_species": int(richness),
            "mean_density": round(ps_df["count_per_m2"].mean(), 2),
            "total_samples": int(len(ps_df)),
            "total_enclosure_records": int(len(enc_df)),
            "total_seine_records": int(len(seine_df))
        },
        "model_results": {
            "habitat_comparison": habitat_comparison,
            "temporal_trends": temporal,
            "diversity_indices": {
                "shannon": round(shannon, 3),
                "simpson": round(simpson, 3),
                "evenness": round(evenness, 3),
                "richness": richness
            }
        },
        "charts": {
            "species_abundance": [
                {
                    "species_code": row["species_code"],
                    "species_name": f"{row['genus_name']} {row['species_name']}",
                    "count": int(row["count"])
                }
                for _, row in top_species.iterrows()
            ],
            "annual_trends": _build_annual_trends(ps_df, annual_by_habitat),
            "heatmap": _build_heatmap_data(enc_df, seine_df)
        }
    }

    return api_data


def _build_annual_trends(ps_df: pd.DataFrame, annual_by_habitat: pd.DataFrame) -> list:
    """Build annual trends data for line chart."""
    # Overall annual means
    overall = ps_df.groupby("year").agg({
        "count_per_m2": "mean",
        "species_count": "mean"
    }).reset_index()

    # By habitat
    tc_data = annual_by_habitat[annual_by_habitat["habitat_code"] == "TC"]
    mc_data = annual_by_habitat[annual_by_habitat["habitat_code"] == "BNMC"]

    trends = []
    for _, row in overall.iterrows():
        year = int(row["year"])
        tc_row = tc_data[tc_data["year"] == year]
        mc_row = mc_data[mc_data["year"] == year]

        trends.append({
            "year": year,
            "density": round(row["count_per_m2"], 2),
            "richness": round(row["species_count"], 1),
            "tc_density": round(tc_row["count_per_m2_mean"].values[0], 2) if len(tc_row) > 0 else None,
            "mc_density": round(mc_row["count_per_m2_mean"].values[0], 2) if len(mc_row) > 0 else None
        })

    return trends


def _build_heatmap_data(enc_df: pd.DataFrame, seine_df: pd.DataFrame) -> list:
    """Build species x year heatmap data."""
    # Combine datasets
    enc_yearly = enc_df.groupby(["year", "species_code"]).agg({"count": "sum"}).reset_index()
    seine_yearly = seine_df.groupby(["year", "species_code"]).agg({"count": "sum"}).reset_index()

    combined = pd.concat([enc_yearly, seine_yearly])
    yearly = combined.groupby(["year", "species_code"]).agg({"count": "sum"}).reset_index()

    # Get top species by total abundance
    top_species = yearly.groupby("species_code")["count"].sum().nlargest(10).index.tolist()

    # Filter to top species and pivot
    filtered = yearly[yearly["species_code"].isin(top_species)]
    pivot = filtered.pivot(index="species_code", columns="year", values="count").fillna(0)

    # Normalize by row (species max)
    normalized = pivot.div(pivot.max(axis=1), axis=0)

    heatmap = []
    for species in pivot.index:
        for year in pivot.columns:
            heatmap.append({
                "species": species,
                "year": int(year),
                "value": round(normalized.loc[species, year], 3),
                "count": int(pivot.loc[species, year])
            })

    return heatmap


def save_dashboard_api(api_data: dict, output_dir: Path = None):
    """
    Save the dashboard API data to JSON.

    Args:
        api_data: Dictionary to save
        output_dir: Output directory (defaults to API_DIR)
    """
    if output_dir is None:
        output_dir = API_DIR

    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / "dashboard_data.json"

    with open(output_path, "w") as f:
        json.dump(api_data, f, indent=2)

    print(f"\nSaved dashboard API to: {output_path}")
    print(f"  File size: {output_path.stat().st_size:,} bytes")


def save_stats_report(api_data: dict, output_dir: Path = None):
    """
    Save detailed statistics report.

    Args:
        api_data: Dashboard data
        output_dir: Output directory (defaults to STATS_DIR)
    """
    if output_dir is None:
        output_dir = STATS_DIR

    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / "analysis_results.json"

    with open(output_path, "w") as f:
        json.dump(api_data, f, indent=2)

    print(f"Saved stats report to: {output_path}")


def main():
    """Generate and save all dashboard data."""
    api_data = generate_dashboard_data()
    save_dashboard_api(api_data)
    save_stats_report(api_data)

    print("\n" + "=" * 60)
    print("Dashboard API generation complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
