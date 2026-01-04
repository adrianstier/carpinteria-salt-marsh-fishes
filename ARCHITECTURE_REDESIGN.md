# Carpinteria Salt Marsh Fish Observatory - Architecture Redesign

## Status: IMPLEMENTED

This architecture has been fully implemented as of January 2026. The project now uses:
- Real EDI data (edi.647.8 and edi.648.8 CSVs)
- Python ETL pipeline in `src/etl/`
- Statistical analysis module in `src/analysis/`
- JSON API export in `src/export/`
- Dashboard fetches data from `outputs/api/dashboard_data.json`
- Makefile for automated builds

Run `make all` to rebuild the entire pipeline.

---

## If Starting From Scratch: A Data Scientist's Perspective

This document outlines how I would rebuild this platform with proper data engineering practices, reproducible analysis, and scalable frontend/backend integration.

---

## Current State Assessment

### What Works Well
- Publication-quality D3.js visualizations
- Comprehensive R Markdown report
- Good statistical analysis (t-tests, Mann-Kendall, regression)
- Clean ocean color palette and responsive design

### What's Problematic
1. **Data is hardcoded** in dashboard.html - updating requires manual copy/paste
2. **Two separate data pipelines** - Python analysis.py and R Markdown don't share outputs
3. **No single source of truth** - analysis_results.json exists but isn't actually loaded by dashboard
4. **Simulated data** - analysis.py generates fake data instead of using real EDI CSVs
5. **No reproducibility** - no environment management, no data validation

---

## Proposed Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   EDI Repository (edi.647.8, edi.648.8)                            │
│         │                                                           │
│         ▼                                                           │
│   ┌─────────────┐                                                  │
│   │ data/raw/   │  ← Raw CSVs (never modified)                     │
│   └─────────────┘                                                  │
│         │                                                           │
│         ▼                                                           │
│   ┌─────────────────────────────────────────────────┐              │
│   │            ETL Pipeline (Python)                 │              │
│   │  - Validate schema                               │              │
│   │  - Handle missing data                           │              │
│   │  - Standardize species names                     │              │
│   │  - Calculate derived metrics                     │              │
│   └─────────────────────────────────────────────────┘              │
│         │                                                           │
│         ▼                                                           │
│   ┌─────────────┐                                                  │
│   │data/processed│  ← Clean, analysis-ready data                   │
│   └─────────────┘                                                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      ANALYSIS LAYER                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌─────────────────────────────────────────────────┐              │
│   │         Statistical Analysis (Python)            │              │
│   │  - Descriptive statistics                        │              │
│   │  - Hypothesis tests (Welch's t, Mann-Kendall)    │              │
│   │  - Diversity indices (Shannon, Simpson)          │              │
│   │  - Regression models                             │              │
│   │  - Cluster analysis                              │              │
│   └─────────────────────────────────────────────────┘              │
│         │                                                           │
│         ▼                                                           │
│   ┌─────────────────────┐                                          │
│   │ outputs/            │                                          │
│   │   ├── api.json      │  ← Dashboard-ready JSON                  │
│   │   ├── stats.json    │  ← Statistical test results              │
│   │   ├── models.pkl    │  ← Fitted model objects                  │
│   │   └── figures/      │  ← Static plots for report               │
│   └─────────────────────┘                                          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌───────────────────┐  ┌───────────────────┐                     │
│   │   Dashboard       │  │   R Markdown      │                     │
│   │   (JavaScript)    │  │   Report          │                     │
│   │                   │  │                   │                     │
│   │  fetch('api.json')│  │  read_json(...)   │                     │
│   │        │          │  │        │          │                     │
│   │        ▼          │  │        ▼          │                     │
│   │   D3.js renders   │  │  knitr renders    │                     │
│   │   charts          │  │  tables/plots     │                     │
│   └───────────────────┘  └───────────────────┘                     │
│            │                      │                                 │
│            └──────────┬───────────┘                                 │
│                       ▼                                             │
│              ┌─────────────────┐                                   │
│              │   Portal Page   │                                   │
│              │   (index.html)  │                                   │
│              └─────────────────┘                                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Detailed Implementation Plan

### 1. Project Structure

```
carpinteria-salt-marsh-fishes/
│
├── data/
│   ├── raw/                      # Original EDI downloads (gitignored)
│   │   ├── edi.647.8/           # Time series (enclosure + seine)
│   │   └── edi.648.8/           # Performance standards
│   ├── processed/               # Clean analysis-ready data
│   │   ├── fish_abundance.parquet
│   │   ├── species_lookup.json
│   │   └── site_metadata.json
│   └── schemas/                 # Data validation schemas
│       └── abundance_schema.json
│
├── src/
│   ├── __init__.py
│   ├── config.py                # Paths, constants, parameters
│   ├── etl/
│   │   ├── __init__.py
│   │   ├── extract.py           # Load raw CSVs
│   │   ├── transform.py         # Clean, standardize
│   │   └── validate.py          # Schema validation
│   ├── analysis/
│   │   ├── __init__.py
│   │   ├── descriptive.py       # Summary stats
│   │   ├── hypothesis.py        # Statistical tests
│   │   ├── diversity.py         # Ecological indices
│   │   ├── regression.py        # Predictive models
│   │   └── clustering.py        # Community analysis
│   └── export/
│       ├── __init__.py
│       ├── dashboard_api.py     # Generate dashboard JSON
│       └── report_data.py       # Generate R-ready data
│
├── outputs/
│   ├── api/
│   │   └── dashboard_data.json  # Single source of truth for frontend
│   ├── stats/
│   │   └── analysis_results.json
│   └── figures/
│       └── *.png
│
├── frontend/
│   ├── index.html               # Portal/landing page
│   ├── dashboard.html           # Interactive D3 dashboard
│   ├── js/
│   │   ├── data-loader.js       # Fetch and cache API data
│   │   ├── charts/
│   │   │   ├── abundance.js
│   │   │   ├── trends.js
│   │   │   ├── habitat.js
│   │   │   └── heatmap.js
│   │   └── utils.js
│   └── css/
│       └── styles.css
│
├── reports/
│   ├── carpinteria_salt_marsh_fishes.Rmd
│   └── _output/
│       └── carpinteria_salt_marsh_fishes.html
│
├── tests/
│   ├── test_etl.py
│   ├── test_analysis.py
│   └── test_export.py
│
├── Makefile                     # Build automation
├── pyproject.toml               # Python dependencies
├── renv.lock                    # R dependencies
├── .env.example                 # Environment template
└── README.md
```

### 2. Data Pipeline (Python)

```python
# src/etl/transform.py

import pandas as pd
import numpy as np
from pathlib import Path
from .validate import validate_schema

def load_performance_standards(raw_path: Path) -> pd.DataFrame:
    """Load and clean the edi.648.8 performance standards data."""

    # Find the CSV file
    csv_files = list(raw_path.glob("wetland_ps_fish_abundance*.csv"))
    if not csv_files:
        raise FileNotFoundError(f"No performance standards CSV in {raw_path}")

    df = pd.read_csv(csv_files[0])

    # Standardize column names
    df.columns = df.columns.str.lower().str.replace(' ', '_')

    # Filter to Carpinteria Salt Marsh only
    df = df[df['wetland_code'] == 'CSM'].copy()

    # Create habitat categories
    df['habitat'] = df['habitat_code'].map({
        'TC': 'Tidal Creek',
        'BNMC': 'Main Channel'
    })

    # Validate against schema
    validate_schema(df, 'abundance_schema')

    return df


def calculate_annual_summaries(df: pd.DataFrame) -> pd.DataFrame:
    """Aggregate data to annual level for dashboard."""

    annual = df.groupby(['year', 'habitat']).agg({
        'count_per_m2': ['mean', 'std', 'count'],
        'species_count': ['mean', 'std']
    }).reset_index()

    # Flatten column names
    annual.columns = ['_'.join(col).strip('_') for col in annual.columns]

    return annual
```

### 3. Analysis Module (Python)

```python
# src/analysis/hypothesis.py

import numpy as np
from scipy import stats
from dataclasses import dataclass
from typing import Tuple

@dataclass
class WelchTestResult:
    """Results from Welch's t-test."""
    t_statistic: float
    p_value: float
    cohens_d: float
    ci_lower: float
    ci_upper: float
    significant: bool

    def to_dict(self) -> dict:
        return {
            't_statistic': round(self.t_statistic, 3),
            'p_value': round(self.p_value, 6),
            'cohens_d': round(self.cohens_d, 3),
            'ci_95': [round(self.ci_lower, 3), round(self.ci_upper, 3)],
            'significant': self.significant
        }


def welch_t_test(
    group1: np.ndarray,
    group2: np.ndarray,
    alpha: float = 0.05
) -> WelchTestResult:
    """
    Perform Welch's t-test for unequal variances.

    Used for comparing fish density between Tidal Creek and Main Channel.
    """
    t_stat, p_val = stats.ttest_ind(group1, group2, equal_var=False)

    # Cohen's d effect size
    pooled_std = np.sqrt((group1.std()**2 + group2.std()**2) / 2)
    cohens_d = (group1.mean() - group2.mean()) / pooled_std

    # 95% CI for difference in means
    se = np.sqrt(group1.var()/len(group1) + group2.var()/len(group2))
    diff = group1.mean() - group2.mean()
    ci_lower = diff - 1.96 * se
    ci_upper = diff + 1.96 * se

    return WelchTestResult(
        t_statistic=t_stat,
        p_value=p_val,
        cohens_d=cohens_d,
        ci_lower=ci_lower,
        ci_upper=ci_upper,
        significant=p_val < alpha
    )
```

### 4. Dashboard Data Export

```python
# src/export/dashboard_api.py

import json
from pathlib import Path
from datetime import datetime
from ..analysis import descriptive, hypothesis, diversity

def generate_dashboard_json(df, output_path: Path):
    """
    Generate the single JSON file that powers the dashboard.

    This is the ONLY place where dashboard data is defined.
    The frontend fetches this file - no hardcoding.
    """

    # Run all analyses
    habitat_comparison = hypothesis.compare_habitats(df)
    temporal_trends = descriptive.annual_trends(df)
    species_abundance = descriptive.species_totals(df)
    diversity_indices = diversity.calculate_indices(df)

    # Structure for frontend
    api_data = {
        'meta': {
            'generated_at': datetime.now().isoformat(),
            'data_version': 'edi.648.8',
            'years': sorted(df['year'].unique().tolist()),
            'n_samples': len(df)
        },
        'summary': {
            'years_of_data': df['year'].nunique(),
            'total_species': df['species_code'].nunique(),
            'mean_density': round(df['count_per_m2'].mean(), 2),
            'total_samples': len(df)
        },
        'model_results': {
            'habitat_comparison': habitat_comparison.to_dict(),
            'diversity': diversity_indices.to_dict(),
            'temporal_trend': temporal_trends.trend_test.to_dict()
        },
        'charts': {
            'species_abundance': species_abundance.to_list(),
            'annual_trends': temporal_trends.to_list(),
            'heatmap': generate_heatmap_data(df)
        }
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(api_data, f, indent=2)

    return api_data
```

### 5. Frontend Data Loading

```javascript
// frontend/js/data-loader.js

/**
 * Centralized data loading for the dashboard.
 *
 * KEY PRINCIPLE: Dashboard NEVER contains hardcoded data.
 * All data comes from the generated API JSON file.
 */

class DataLoader {
    constructor() {
        this.cache = null;
        this.apiUrl = './api/dashboard_data.json';
    }

    async load() {
        if (this.cache) return this.cache;

        try {
            const response = await fetch(this.apiUrl);
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            this.cache = await response.json();

            // Validate required fields
            this.validate(this.cache);

            return this.cache;
        } catch (error) {
            console.error('Failed to load dashboard data:', error);
            throw error;
        }
    }

    validate(data) {
        const required = ['meta', 'summary', 'model_results', 'charts'];
        for (const key of required) {
            if (!(key in data)) {
                throw new Error(`Missing required field: ${key}`);
            }
        }
    }
}

// Singleton instance
export const dataLoader = new DataLoader();
```

```javascript
// frontend/js/charts/abundance.js

import { dataLoader } from '../data-loader.js';

export async function renderAbundanceChart(containerId) {
    const data = await dataLoader.load();
    const species = data.charts.species_abundance;

    // Now render with D3...
    const container = d3.select(`#${containerId}`);
    // ... rest of D3 code using `species` array
}
```

### 6. Build Automation (Makefile)

```makefile
# Makefile

.PHONY: all data analysis dashboard report clean

# Default target
all: data analysis dashboard report

# Extract and transform data
data:
	python -m src.etl.pipeline

# Run statistical analysis
analysis: data
	python -m src.analysis.run_all
	@echo "Analysis complete. Results in outputs/stats/"

# Generate dashboard JSON
dashboard: analysis
	python -m src.export.dashboard_api
	@echo "Dashboard API generated at outputs/api/dashboard_data.json"

# Render R Markdown report
report: analysis
	Rscript -e "rmarkdown::render('reports/carpinteria_salt_marsh_fishes.Rmd')"
	@echo "Report generated at reports/_output/"

# Run tests
test:
	pytest tests/ -v

# Clean generated files
clean:
	rm -rf outputs/
	rm -rf reports/_output/
	rm -rf data/processed/

# Development server
serve:
	python -m http.server 8000 --directory frontend
```

### 7. Continuous Integration

```yaml
# .github/workflows/build.yml

name: Build and Deploy

on:
  push:
    branches: [main]
  schedule:
    # Rebuild weekly to check for data updates
    - cron: '0 0 * * 0'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Setup R
        uses: r-lib/actions/setup-r@v2

      - name: Install dependencies
        run: |
          pip install -e .
          Rscript -e "renv::restore()"

      - name: Download latest EDI data
        run: python scripts/download_edi.py

      - name: Run pipeline
        run: make all

      - name: Run tests
        run: make test

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./frontend
```

---

## Key Improvements Over Current State

| Aspect | Current | Proposed |
|--------|---------|----------|
| Data source | Simulated in Python | Real EDI CSVs |
| Data location | Hardcoded in HTML | Single JSON API file |
| Update process | Manual copy/paste | `make dashboard` |
| R/Python sharing | None | Shared JSON outputs |
| Validation | None | Schema validation |
| Testing | None | pytest + testthat |
| Reproducibility | Poor | Makefile + CI/CD |
| Deployment | Manual | GitHub Actions |

---

## Migration Steps

1. **Create directory structure** (30 min)
2. **Move existing EDI data** to `data/raw/` (5 min)
3. **Write ETL pipeline** to load real CSVs (2 hrs)
4. **Refactor analysis.py** into modular functions (2 hrs)
5. **Create dashboard_api.py** export (1 hr)
6. **Refactor dashboard.html** to fetch JSON (1 hr)
7. **Update R Markdown** to read processed data (1 hr)
8. **Write tests** (2 hrs)
9. **Set up CI/CD** (1 hr)

**Total estimated effort: ~12 hours**

---

## Conclusion

The current implementation is a solid MVP, but it has architectural debt that makes updates painful. By separating data, analysis, and presentation into distinct layers with a single JSON API as the interface, we get:

1. **Single source of truth** - Change data in one place
2. **Reproducibility** - `make all` rebuilds everything
3. **Testability** - Unit tests for each component
4. **Maintainability** - Clear module boundaries
5. **Scalability** - Easy to add new analyses or charts

This is the architecture I would build from day one if starting fresh.
