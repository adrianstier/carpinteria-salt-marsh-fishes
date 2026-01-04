"""
Transform and clean EDI data for analysis.

This module transforms raw EDI data into analysis-ready formats.
"""

import pandas as pd
import numpy as np
from pathlib import Path
from typing import Tuple
import sys

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from src.config import PROCESSED_DATA_DIR, HABITAT_CODES


def transform_performance_standards(df: pd.DataFrame) -> pd.DataFrame:
    """
    Transform performance standards data.

    - Standardize column names
    - Add habitat labels
    - Calculate derived metrics

    Args:
        df: Raw performance standards DataFrame

    Returns:
        Transformed DataFrame
    """
    df = df.copy()

    # Add readable habitat names
    df["habitat"] = df["habitat_code"].map(HABITAT_CODES)

    # Ensure numeric types
    df["count_per_m2"] = pd.to_numeric(df["count_per_m2"], errors="coerce")
    df["species_count"] = pd.to_numeric(df["species_count"], errors="coerce")

    # Remove any rows with missing values in key columns
    df = df.dropna(subset=["count_per_m2", "species_count"])

    return df


def transform_enclosure_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Transform enclosure trap data.

    - Filter to actual fish catches (count > 0)
    - Calculate density per m2
    - Add habitat labels

    Args:
        df: Raw enclosure DataFrame

    Returns:
        Transformed DataFrame
    """
    df = df.copy()

    # Add readable habitat names
    df["habitat"] = df["habitat_code"].map(HABITAT_CODES)

    # Convert date
    df["date"] = pd.to_datetime(df["date"])

    # Calculate density (count / area)
    df["density_per_m2"] = df["count"] / df["enclosure_area"]

    return df


def transform_seine_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Transform beach seine data.

    - Filter to actual fish catches
    - Calculate density per m2
    - Add habitat labels

    Args:
        df: Raw seine DataFrame

    Returns:
        Transformed DataFrame
    """
    df = df.copy()

    # Add readable habitat names
    df["habitat"] = df["habitat_code"].map(HABITAT_CODES)

    # Convert date
    df["date"] = pd.to_datetime(df["date"])

    # Calculate density (count / area)
    df["density_per_m2"] = df["count"] / df["seine_sample_area"]

    return df


def aggregate_species_by_year(
    enclosure_df: pd.DataFrame,
    seine_df: pd.DataFrame
) -> pd.DataFrame:
    """
    Aggregate species counts by year across both sampling methods.

    Args:
        enclosure_df: Transformed enclosure data
        seine_df: Transformed seine data

    Returns:
        DataFrame with species abundance by year
    """
    # Aggregate enclosure data
    enc_agg = enclosure_df.groupby(["year", "species_code", "genus_name", "species_name"]).agg({
        "count": "sum"
    }).reset_index()
    enc_agg["method"] = "enclosure"

    # Aggregate seine data
    seine_agg = seine_df.groupby(["year", "species_code", "genus_name", "species_name"]).agg({
        "count": "sum"
    }).reset_index()
    seine_agg["method"] = "seine"

    # Combine
    combined = pd.concat([enc_agg, seine_agg], ignore_index=True)

    # Total by species and year
    totals = combined.groupby(["year", "species_code", "genus_name", "species_name"]).agg({
        "count": "sum"
    }).reset_index()

    return totals


def aggregate_annual_trends(ps_df: pd.DataFrame) -> pd.DataFrame:
    """
    Calculate annual trends from performance standards data.

    Args:
        ps_df: Transformed performance standards DataFrame

    Returns:
        DataFrame with annual summary statistics
    """
    annual = ps_df.groupby(["year", "habitat_code", "habitat"]).agg({
        "count_per_m2": ["mean", "std", "count"],
        "species_count": ["mean", "std"]
    }).reset_index()

    # Flatten column names
    annual.columns = [
        "_".join(col).strip("_") if isinstance(col, tuple) else col
        for col in annual.columns
    ]

    return annual


def get_species_totals(
    enclosure_df: pd.DataFrame,
    seine_df: pd.DataFrame
) -> pd.DataFrame:
    """
    Get total counts for each species across all years.

    Args:
        enclosure_df: Transformed enclosure data
        seine_df: Transformed seine data

    Returns:
        DataFrame with species sorted by total abundance
    """
    # Combine both datasets
    enc_totals = enclosure_df.groupby(["species_code", "genus_name", "species_name"]).agg({
        "count": "sum"
    }).reset_index()

    seine_totals = seine_df.groupby(["species_code", "genus_name", "species_name"]).agg({
        "count": "sum"
    }).reset_index()

    # Merge
    all_species = pd.concat([enc_totals, seine_totals], ignore_index=True)
    totals = all_species.groupby(["species_code", "genus_name", "species_name"]).agg({
        "count": "sum"
    }).reset_index()

    # Sort by abundance
    totals = totals.sort_values("count", ascending=False).reset_index(drop=True)

    return totals


def save_processed_data(
    ps_df: pd.DataFrame,
    enclosure_df: pd.DataFrame,
    seine_df: pd.DataFrame
):
    """
    Save processed data to parquet files.

    Args:
        ps_df: Transformed performance standards
        enclosure_df: Transformed enclosure data
        seine_df: Transformed seine data
    """
    PROCESSED_DATA_DIR.mkdir(parents=True, exist_ok=True)

    ps_df.to_parquet(PROCESSED_DATA_DIR / "performance_standards.parquet", index=False)
    enclosure_df.to_parquet(PROCESSED_DATA_DIR / "enclosure_surveys.parquet", index=False)
    seine_df.to_parquet(PROCESSED_DATA_DIR / "seine_surveys.parquet", index=False)

    print(f"Saved processed data to {PROCESSED_DATA_DIR}")


if __name__ == "__main__":
    from src.etl.extract import (
        load_performance_standards,
        load_enclosure_data,
        load_seine_data,
        filter_to_csm
    )

    print("=" * 60)
    print("Testing Data Transformation")
    print("=" * 60)

    # Load raw data
    ps_raw = load_performance_standards()
    enc_raw = load_enclosure_data()
    seine_raw = load_seine_data()

    # Filter to CSM
    ps_csm = filter_to_csm(ps_raw)
    enc_csm = filter_to_csm(enc_raw)
    seine_csm = filter_to_csm(seine_raw)

    # Transform
    print("\nTransforming data...")
    ps_df = transform_performance_standards(ps_csm)
    enc_df = transform_enclosure_data(enc_csm)
    seine_df = transform_seine_data(seine_csm)

    # Aggregate
    print("\nCalculating aggregations...")
    annual = aggregate_annual_trends(ps_df)
    print(f"\nAnnual trends ({len(annual)} rows):")
    print(annual.head(10))

    species_totals = get_species_totals(enc_df, seine_df)
    print(f"\nTop 10 species by abundance:")
    print(species_totals.head(10))

    # Save
    print("\nSaving processed data...")
    save_processed_data(ps_df, enc_df, seine_df)

    print("\n" + "=" * 60)
    print("Transformation complete!")
    print("=" * 60)
