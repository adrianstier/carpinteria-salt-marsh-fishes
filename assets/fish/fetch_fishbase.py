#!/usr/bin/env python3
"""
Fetch fish photos from FishBase for missing species.
"""

import urllib.request
import re
import os
import time

# Species to fetch from FishBase (scientific name -> local filename)
SPECIES = {
    "Porichthys myriaster": "midshipman",      # Specklefin Midshipman
    "Acanthogobius flavimanus": "yellowfin_goby",  # Yellowfin Goby
    "Quietula y-cauda": "shadow_goby",         # Shadow Goby
    "Ilypnus gilberti": "cheekspot_goby",      # Cheekspot Goby
}

script_dir = os.path.dirname(os.path.abspath(__file__))

def get_fishbase_image(scientific_name):
    """Scrape FishBase page to find main image URL."""
    # Convert name to URL format
    url_name = scientific_name.replace(" ", "-")
    url = f"https://www.fishbase.org/summary/{url_name}.html"
    
    print(f"  Fetching: {url}")
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    
    with urllib.request.urlopen(req, timeout=30) as response:
        html = response.read().decode('utf-8', errors='ignore')
    
    # Look for og:image meta tag which has the thumbnail
    match = re.search(r'<meta property="og:image" content="([^"]+)"', html)
    if match:
        thumb_url = match.group(1)
        # Convert thumbnail to full-size image
        # tn_Pomyr_u0.jpg -> Pomyr_u0.jpg
        full_url = thumb_url.replace('/thumbnails/', '/species/').replace('tn_', '')
        return full_url
    
    # Alternative: look for main species image
    match = re.search(r'/images/species/[^"\']+\.(?:jpg|gif|png)', html, re.IGNORECASE)
    if match:
        return f"https://www.fishbase.org{match.group(0)}"
    
    return None

for scientific, filename in SPECIES.items():
    print(f"Fetching {filename} ({scientific})...")
    
    try:
        image_url = get_fishbase_image(scientific)
        
        if image_url:
            print(f"  Image URL: {image_url}")
            
            # Download the image
            filepath = os.path.join(script_dir, f"{filename}.jpg")
            img_req = urllib.request.Request(image_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(img_req, timeout=30) as img_response:
                with open(filepath, 'wb') as f:
                    f.write(img_response.read())
            print(f"  ✓ Saved to {filepath}")
        else:
            print(f"  ✗ No image found on FishBase")
            
    except Exception as e:
        print(f"  ✗ Failed: {e}")
    
    time.sleep(1)  # Be nice to FishBase

print("\nDone!")
