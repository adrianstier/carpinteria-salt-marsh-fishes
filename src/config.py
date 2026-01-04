"""
Configuration and path management for the CSM Fish Observatory pipeline.
"""

from pathlib import Path

# Project root
ROOT_DIR = Path(__file__).parent.parent

# Data paths
DATA_DIR = ROOT_DIR / "data"
RAW_DATA_DIR = DATA_DIR / "raw"
PROCESSED_DATA_DIR = DATA_DIR / "processed"

# EDI dataset paths
EDI_648_DIR = RAW_DATA_DIR / "edi.648.8"  # Performance standards (summarized)
EDI_647_DIR = RAW_DATA_DIR / "edi.647.8"  # Time series (raw surveys)

# Output paths
OUTPUTS_DIR = ROOT_DIR / "outputs"
API_DIR = OUTPUTS_DIR / "api"
STATS_DIR = OUTPUTS_DIR / "stats"

# Frontend paths
FRONTEND_DIR = ROOT_DIR / "frontend"

# Analysis parameters
ALPHA = 0.05  # Significance level
REFERENCE_WETLAND = "CSM"  # Carpinteria Salt Marsh

# Habitat codes
HABITAT_CODES = {
    "TC": "Tidal Creek",
    "BNMC": "Main Channel"
}

# Species guilds (based on ecological function)
ECOLOGICAL_GUILDS = {
    "Resident Specialist": [
        "CLMU", "ACAL", "ILPA", "QUYC", "GIMI"  # Gobies, killifish
    ],
    "Marine Migrant": [
        "ATHE", "MUSP", "HYSP", "EMJA"  # Topsmelt, mullet, surfperch
    ],
    "Nursery User": [
        "PASP", "PLSP", "CYSP"  # Flatfish, halibut
    ],
    "Visitor": [
        "MYSP", "TRSP", "URSP"  # Rays, sharks
    ]
}
