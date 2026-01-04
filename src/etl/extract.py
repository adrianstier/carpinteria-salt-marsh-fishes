"""
Extract data from EDI CSV files.

This module handles loading raw data from the Environmental Data Initiative:
- edi.648.8: Performance standards (summarized fish abundance and richness)
- edi.647.8: Time series (raw enclosure trap and beach seine survey data)
"""

import pandas as pd
from pathlib import Path
from typing import Optional
import sys

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from src.config import RAW_DATA_DIR, REFERENCE_WETLAND


def load_performance_standards(filepath: Optional[Path] = None) -> pd.DataFrame:
    """
    Load the edi.648.8 performance standards dataset.

    This contains annual summary data for fish abundance (count_per_m2)
    and species richness across multiple wetlands and habitats.

    Args:
        filepath: Path to CSV. If None, searches in RAW_DATA_DIR/edi.648.8/

    Returns:
        DataFrame with columns:
        - year, wetland_code, module_code, tc_mc_code, habitat_code
        - count_per_m2, species_count

    Raises:
        FileNotFoundError: If CSV file not found
    """
    if filepath is None:
        search_path = RAW_DATA_DIR / "edi.648.8"
        csv_files = list(search_path.glob("*fish_abundance*.csv"))
        if not csv_files:
            raise FileNotFoundError(
                f"No performance standards CSV found in {search_path}. "
                "Run `python -m src.etl.download` to fetch data from EDI."
            )
        filepath = csv_files[0]

    print(f"Loading performance standards: {filepath}")
    df = pd.read_csv(filepath)
    print(f"  {len(df)} records, years {df['year'].min()}-{df['year'].max()}")
    print(f"  Wetlands: {df['wetland_code'].unique().tolist()}")

    return df


def load_enclosure_data(filepath: Optional[Path] = None) -> pd.DataFrame:
    """
    Load the edi.647.8 enclosure trap survey data.

    Enclosure traps (0.43 m2) capture small benthic gobies.
    Multiple hauls per trap until 3 consecutive passes with no fish.

    Args:
        filepath: Path to CSV. If None, searches in RAW_DATA_DIR/edi.647.8/

    Returns:
        DataFrame with columns:
        - year, date, survey, wetland_code, module_code, habitat_code
        - enclosure_number, depth, haul_no
        - species_id, species_code, genus_name, species_name
        - count, enclosure_area

    Raises:
        FileNotFoundError: If CSV file not found
    """
    if filepath is None:
        search_path = RAW_DATA_DIR / "edi.647.8"
        csv_files = list(search_path.glob("*enclosure*.csv"))
        if not csv_files:
            raise FileNotFoundError(
                f"No enclosure CSV found in {search_path}. "
                "Run `python -m src.etl.download` to fetch data from EDI."
            )
        filepath = csv_files[0]

    print(f"Loading enclosure data: {filepath}")
    df = pd.read_csv(filepath)
    print(f"  {len(df)} records")

    return df


def load_seine_data(filepath: Optional[Path] = None) -> pd.DataFrame:
    """
    Load the edi.647.8 beach seine survey data.

    Beach seines (~100 m2) capture larger mobile fishes.
    5 hauls per location.

    Args:
        filepath: Path to CSV. If None, searches in RAW_DATA_DIR/edi.647.8/

    Returns:
        DataFrame with columns:
        - year, date, survey, wetland_code, module_code, habitat_code
        - seine_section_code, seine_label, seine_sample_area
        - species_id, species_code, genus_name, species_name
        - count

    Raises:
        FileNotFoundError: If CSV file not found
    """
    if filepath is None:
        search_path = RAW_DATA_DIR / "edi.647.8"
        csv_files = list(search_path.glob("*seine*.csv"))
        if not csv_files:
            raise FileNotFoundError(
                f"No seine CSV found in {search_path}. "
                "Run `python -m src.etl.download` to fetch data from EDI."
            )
        filepath = csv_files[0]

    print(f"Loading seine data: {filepath}")
    df = pd.read_csv(filepath)
    print(f"  {len(df)} records")

    return df


def filter_to_csm(df: pd.DataFrame, wetland_col: str = "wetland_code") -> pd.DataFrame:
    """
    Filter data to Carpinteria Salt Marsh (CSM) only.

    Args:
        df: DataFrame with wetland_code column
        wetland_col: Name of wetland code column

    Returns:
        Filtered DataFrame
    """
    csm_df = df[df[wetland_col] == REFERENCE_WETLAND].copy()
    print(f"  Filtered to {REFERENCE_WETLAND}: {len(csm_df)} records")
    return csm_df


if __name__ == "__main__":
    # Test the extract functions
    print("=" * 60)
    print("Testing EDI Data Extraction")
    print("=" * 60)

    print("\n1. Performance Standards (edi.648.8)")
    print("-" * 40)
    ps_data = load_performance_standards()
    print(ps_data.head())

    print("\n2. Enclosure Data (edi.647.8)")
    print("-" * 40)
    enclosure_data = load_enclosure_data()
    print(enclosure_data.head())

    print("\n3. Seine Data (edi.647.8)")
    print("-" * 40)
    seine_data = load_seine_data()
    print(seine_data.head())

    print("\n4. Filter to Carpinteria Salt Marsh")
    print("-" * 40)
    csm_ps = filter_to_csm(ps_data)
    csm_enclosure = filter_to_csm(enclosure_data)
    csm_seine = filter_to_csm(seine_data)

    print("\n" + "=" * 60)
    print("Extraction complete!")
    print("=" * 60)
