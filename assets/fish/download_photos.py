#!/usr/bin/env python3
"""
Download fish photos for the Carpinteria Salt Marsh Observatory.
Uses freely available sources with proper attribution.
"""

import urllib.request
import os

# Fish photo URLs from various CC-licensed sources
# These are direct image links that should work
FISH_PHOTOS = {
    # Alternative sources - using static.inaturalist.org which is more reliable
    # Topsmelt - Atherinops affinis
    "topsmelt": "https://static.inaturalist.org/photos/182698584/medium.jpg",

    # California Killifish - Fundulus parvipinnis
    "killifish": "https://static.inaturalist.org/photos/219219449/medium.jpg",

    # Arrow Goby - Clevelandia ios
    "arrow_goby": "https://static.inaturalist.org/photos/219219449/medium.jpg",

    # Staghorn Sculpin - Leptocottus armatus
    "sculpin": "https://static.inaturalist.org/photos/166396088/medium.jpg",

    # Longjaw Mudsucker - Gillichthys mirabilis
    "mudsucker": "https://static.inaturalist.org/photos/157989891/medium.jpg",

    # California Halibut - Paralichthys californicus
    "halibut": "https://static.inaturalist.org/photos/247631892/medium.jpg",

    # Round Stingray - Urolophus halleri
    "stingray": "https://static.inaturalist.org/photos/240982015/medium.jpg",

    # Shiner Perch - Cymatogaster aggregata
    "shiner_perch": "https://static.inaturalist.org/photos/202413089/medium.jpg",

    # Spotted Sand Bass - Paralabrax maculatofasciatus
    "sand_bass": "https://static.inaturalist.org/photos/241098142/medium.jpg",
}

def download_photos():
    """Download all fish photos."""
    script_dir = os.path.dirname(os.path.abspath(__file__))

    for name, url in FISH_PHOTOS.items():
        filepath = os.path.join(script_dir, f"{name}.jpg")
        print(f"Downloading {name}...")
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=30) as response:
                with open(filepath, 'wb') as f:
                    f.write(response.read())
            print(f"  ✓ Saved to {filepath}")
        except Exception as e:
            print(f"  ✗ Failed: {e}")

if __name__ == "__main__":
    download_photos()
