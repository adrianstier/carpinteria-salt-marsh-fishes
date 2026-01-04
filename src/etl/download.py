"""
Download data from the Environmental Data Initiative (EDI) repository.

EDI Package IDs:
- edi.648.8: Performance standards (summarized fish abundance and richness)
- edi.647.8: Time series (raw enclosure and seine survey data)
"""

import urllib.request
import os
from pathlib import Path
import sys

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from src.config import RAW_DATA_DIR

# EDI Data Portal base URL
EDI_BASE_URL = "https://portal.edirepository.org/nis/dataviewer"

# Dataset definitions with entity IDs from EDI
DATASETS = {
    "edi.648.8": {
        "description": "Performance Standards - Fish Abundance and Richness",
        "entities": {
            "fish_abundance_richness": {
                "entity_id": "a573e343e096c65ba5bc58ca25f48fa0",
                "filename": "wetland_ps_fish_abundance_and_richness.csv"
            }
        }
    },
    "edi.647.8": {
        "description": "Time Series - Raw Survey Data",
        "entities": {
            "enclosure_trap": {
                "entity_id": "6cf8d8a2c5de5f5f5f5f5f5f5f5f5f5f",  # Placeholder
                "filename": "wetland_ts_fish_enclosure.csv"
            },
            "beach_seine": {
                "entity_id": "7df9e9b3d6ef6f6f6f6f6f6f6f6f6f6f",  # Placeholder
                "filename": "wetland_ts_fish_seine.csv"
            }
        }
    }
}


def download_edi_entity(package_id: str, entity_id: str, output_path: Path) -> bool:
    """
    Download a single data entity from EDI.

    Args:
        package_id: EDI package identifier (e.g., 'edi.648.8')
        entity_id: Entity identifier within the package
        output_path: Where to save the downloaded file

    Returns:
        True if successful, False otherwise
    """
    url = f"{EDI_BASE_URL}?packageid={package_id}&entityid={entity_id}"

    print(f"Downloading: {url}")
    print(f"  -> {output_path}")

    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        urllib.request.urlretrieve(url, output_path)
        print(f"  Success: {output_path.stat().st_size:,} bytes")
        return True
    except Exception as e:
        print(f"  Failed: {e}")
        return False


def download_all_datasets():
    """Download all EDI datasets for the project."""

    print("=" * 60)
    print("EDI Data Download")
    print("=" * 60)

    for package_id, package_info in DATASETS.items():
        print(f"\nPackage: {package_id}")
        print(f"  {package_info['description']}")

        package_dir = RAW_DATA_DIR / package_id

        for entity_name, entity_info in package_info["entities"].items():
            output_path = package_dir / entity_info["filename"]
            download_edi_entity(
                package_id,
                entity_info["entity_id"],
                output_path
            )

    print("\n" + "=" * 60)
    print("Download complete")
    print("=" * 60)


if __name__ == "__main__":
    download_all_datasets()
