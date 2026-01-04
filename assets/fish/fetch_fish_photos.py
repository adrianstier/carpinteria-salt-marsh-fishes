#!/usr/bin/env python3
"""
Fetch fish photos using iNaturalist API for proper URLs.
"""

import urllib.request
import json
import os
import time

# Species to fetch (scientific name -> local filename)
SPECIES = {
    "Atherinops affinis": "topsmelt",           # Topsmelt
    "Fundulus parvipinnis": "killifish",        # California Killifish  
    "Clevelandia ios": "arrow_goby",            # Arrow Goby
    "Leptocottus armatus": "sculpin",           # Staghorn Sculpin
    "Gillichthys mirabilis": "mudsucker",       # Longjaw Mudsucker
    "Paralichthys californicus": "halibut",     # California Halibut
    "Urolophus halleri": "stingray",            # Round Stingray
    "Cymatogaster aggregata": "shiner_perch",   # Shiner Perch
    "Paralabrax maculatofasciatus": "sand_bass", # Spotted Sand Bass
}

script_dir = os.path.dirname(os.path.abspath(__file__))

for scientific, filename in SPECIES.items():
    print(f"Fetching {filename} ({scientific})...")
    
    # Get taxon info from iNaturalist API
    try:
        query = scientific.replace(" ", "%20")
        api_url = f"https://api.inaturalist.org/v1/taxa?q={query}&per_page=1"
        
        req = urllib.request.Request(api_url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.loads(response.read())
        
        if data['results'] and data['results'][0].get('default_photo'):
            photo_url = data['results'][0]['default_photo']['medium_url']
            print(f"  Photo URL: {photo_url}")
            
            # Download the photo
            filepath = os.path.join(script_dir, f"{filename}.jpg")
            photo_req = urllib.request.Request(photo_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(photo_req, timeout=30) as photo_response:
                with open(filepath, 'wb') as f:
                    f.write(photo_response.read())
            print(f"  ✓ Saved to {filepath}")
        else:
            print(f"  ✗ No photo found")
            
    except Exception as e:
        print(f"  ✗ Failed: {e}")
    
    time.sleep(0.5)  # Be nice to the API

print("\nDone!")
