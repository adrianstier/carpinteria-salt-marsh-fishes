# Carpinteria Salt Marsh Fish Community Data

## Overview

This repository contains long-term monitoring data of fish communities from California coastal wetlands, collected as part of the **SONGS (San Onofre Nuclear Generating Station) Mitigation Monitoring Program** by UC Santa Barbara's Marine Science Institute. The data span **2012-2024** and include four reference wetlands.

## Study Context

The SONGS Mitigation Monitoring Program was established to evaluate the San Dieguito Wetland restoration project. Fish communities are monitored at the restoration site and reference wetlands to assess whether restoration meets biological performance standards. **Carpinteria Salt Marsh (CSM)** serves as one of the primary reference wetlands representing relatively undisturbed, natural tidal wetlands within the Southern California Bight.

## Data Files

### Directory: `edi.648.8/` - Performance Standard Data (Summarized)

| File | Description |
|------|-------------|
| `wetland_ps_fish_abundance_and_richness-*.csv` | **Annual summary data** of fish density (individuals/m²) and species richness at each sampling location. Combines enclosure trap and beach seine data. |

**Variables:**
- `year`: Survey year (2012-2024)
- `wetland_code`: CSM (Carpinteria), MUL (Mugu Lagoon), SDW (San Dieguito), TJE (Tijuana), LPL (Los Penasquitos - 2024 only)
- `module_code`: Spatial module within wetland
- `tc_mc_code`: Tidal creek (TC) or main channel (MC) location identifier
- `habitat_code`: TC = Tidal Creek, BNMC = Basin/Main Channel
- `count_per_m2`: Fish density (individuals per square meter)
- `species_count`: Number of unique species observed

### Directory: `edi.647.8/` - Raw Survey Data

| File | Description |
|------|-------------|
| `wetland_ts_fish_enclosure-*.csv` | **Enclosure trap data** - Raw counts of gobies (small, benthic fishes) from 0.43 m² circular enclosure traps. Five enclosures per location. |
| `wetland_ts_fish_seine-*.csv` | **Beach seine data** - Raw counts of larger, mobile fishes from ~100 m² beach seine hauls. |

**Enclosure Data Variables:**
- `year`, `date`, `survey`: Temporal identifiers
- `wetland_code`, `habitat_code`, `tc_mc_code`: Spatial identifiers
- `enclosure_number`, `sampling_station_label`: Replicate identifiers
- `depth`: Water depth (cm)
- `haul_no`: Sequential haul number
- `species_id`, `species_code`, `genus_name`, `species_name`: Taxonomic identifiers
- `count`: Number of individuals
- `enclosure_area`: Area sampled (0.43 m²)

**Seine Data Variables:**
- Similar spatial/temporal variables as enclosure data
- `seine_section_code`, `seine_label`: Seine replicate identifiers
- `seine_sample_width`, `seine_sample_length`, `seine_sample_area`: Sampling dimensions

## Sampling Methods

### Enclosure Traps
- **Target**: Small benthic gobies (Gobiidae)
- **Design**: 0.43 m² × 0.9 m circular enclosure traps
- **Protocol**: 5 enclosures per location, spaced ~10 m apart
- **Sampling**: Multiple hauls with BINCKE net until 3 consecutive passes with no fish

### Beach Seines
- **Target**: Larger, mobile fishes
- **Design**: 2 m × 7.62 m beach seine with blocking nets
- **Protocol**: 5 hauls through blocked area (~100 m²)
- **Sampling**: Non-goby fishes identified, counted, and released

## Fish Species Recorded

### Gobies (Enclosure Sampling)
| Scientific Name | Common Name | Code |
|----------------|-------------|------|
| *Clevelandia ios* | Arrow Goby | CLIO |
| *Ilypnus gilberti* | Cheekspot Goby | ILGI |
| *Quietula y-cauda* | Shadow Goby | QUYC |
| *Gillichthys mirabilis* | Longjaw Mudsucker | GIMI |
| *Acanthogobius flavimanus* | Yellowfin Goby | ACFV |

### Seine Species (Selection)
| Scientific Name | Common Name | Code |
|----------------|-------------|------|
| *Atherinops affinis* | Topsmelt | ATAF |
| *Fundulus parvipinnis* | California Killifish | FUPA |
| *Paralichthys californicus* | California Halibut | PACA |
| *Hypsopsetta guttulata* | Diamond Turbot | HYGU |
| *Syngnathus leptorhynchus* | Bay Pipefish | SYLE |
| *Mugil cephalus* | Striped Mullet | MUCE |
| *Leptocottus armatus* | Staghorn Sculpin | LEAR |
| *Myliobatis californicus* | Bat Ray | MYCA |
| *Urolophus halleri* | Round Stingray | URHA |

## Study Sites

| Code | Wetland | Location | Coordinates |
|------|---------|----------|-------------|
| **CSM** | Carpinteria Salt Marsh | Santa Barbara County, CA | 34.401°N, 119.538°W |
| MUL | Mugu Lagoon | Ventura County, CA | 34.102°N, 119.097°W |
| SDW | San Dieguito Wetland | San Diego County, CA | 32.970°N, 117.260°W |
| TJE | Tijuana Estuary | San Diego County, CA | 32.570°N, 117.127°W |
| LPL | Los Penasquitos Lagoon | San Diego County, CA | 32.931°N, 117.252°W |

*Note: Tijuana Estuary (TJE) was replaced by Los Penasquitos Lagoon (LPL) in 2024.*

## Data Citation

**Performance Standard Data:**
> Schroeter, S., H. Page, D. Reed, K. Beheshti, R. Smith, and D. Huang. 2025. UCSB SONGS Mitigation Monitoring: Wetland Performance Standard - Fish Abundance and Species Richness. Environmental Data Initiative. DOI: 10.6073/pasta/a573e343e096c65ba5bc58ca25f48fa0

**Survey Data:**
> Schroeter, S., H. Page, D. Reed, K. Beheshti, R. Smith, and D. Huang. 2025. UCSB SONGS Mitigation Monitoring: Wetland Survey - Fish Abundance. Environmental Data Initiative. DOI: 10.6073/pasta/643f86b3043a15cb7d597e10fcff47a2

## License

Data released under **Creative Commons Attribution 4.0 International (CC BY 4.0)**

## Contact

SONGS Mitigation Monitoring Project
Marine Science Institute, UC Santa Barbara
Email: songsmmp@lifesci.ucsb.edu
Website: http://marinemitigation.msi.ucsb.edu/
