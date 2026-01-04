"""
FastAPI backend for Carpinteria Salt Marsh Fish Observatory.

Provides:
- JSON data API
- Publication-quality figure generation
- Static file serving
"""

from fastapi import FastAPI, Response, Query
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
import json
import io
from typing import Optional
from enum import Enum

# Figure generation
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import numpy as np

import sys
sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from src.config import OUTPUTS_DIR, API_DIR

app = FastAPI(
    title="Carpinteria Salt Marsh Fish Observatory API",
    description="Data and figure generation for the CSM fish monitoring program",
    version="1.0.0"
)

# CORS for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Publication-quality figure settings
FIGURE_STYLE = {
    "font.family": "sans-serif",
    "font.size": 12,
    "axes.labelsize": 14,
    "axes.titlesize": 16,
    "xtick.labelsize": 11,
    "ytick.labelsize": 11,
    "legend.fontsize": 11,
    "figure.dpi": 150,
    "savefig.dpi": 300,
    "axes.spines.top": False,
    "axes.spines.right": False,
}

# Ocean color palette
COLORS = {
    "ocean": "#2171b5",
    "ocean_light": "#6baed6",
    "marsh": "#238b45",
    "marsh_light": "#74c476",
    "sand": "#fe9929",
    "accent": "#d94801",
}


class FigureFormat(str, Enum):
    png = "png"
    svg = "svg"
    pdf = "pdf"


def load_dashboard_data():
    """Load the dashboard JSON data."""
    json_path = API_DIR / "dashboard_data.json"
    if not json_path.exists():
        return None
    with open(json_path) as f:
        return json.load(f)


@app.get("/api/health")
async def health():
    """API health check."""
    return {"status": "ok", "service": "CSM Fish Observatory API"}


@app.get("/api/data")
async def get_data():
    """Return the full dashboard data JSON."""
    data = load_dashboard_data()
    if not data:
        return {"error": "Data not generated. Run: python -m src.export.dashboard_api"}
    return data


@app.get("/api/summary")
async def get_summary():
    """Return just the summary statistics."""
    data = load_dashboard_data()
    if not data:
        return {"error": "Data not found"}
    return data.get("summary", {})


@app.get("/api/figures/species-abundance")
async def figure_species_abundance(
    format: FigureFormat = FigureFormat.png,
    width: float = 10,
    height: float = 6,
    top_n: int = 10
):
    """Generate species abundance bar chart."""
    data = load_dashboard_data()
    if not data:
        return {"error": "Data not found"}

    species_data = data["charts"]["species_abundance"][:top_n]

    plt.style.use('seaborn-v0_8-whitegrid')
    plt.rcParams.update(FIGURE_STYLE)

    fig, ax = plt.subplots(figsize=(width, height))

    species = [s["species_code"] for s in species_data]
    counts = [s["count"] for s in species_data]

    bars = ax.barh(species[::-1], counts[::-1], color=COLORS["ocean"], edgecolor="white")

    ax.set_xlabel("Total Count (2012-2024)")
    ax.set_title("Top Fish Species at Carpinteria Salt Marsh", fontweight="bold", pad=20)
    ax.set_xlim(0, max(counts) * 1.1)

    # Add count labels
    for bar, count in zip(bars, counts[::-1]):
        ax.text(bar.get_width() + max(counts) * 0.02, bar.get_y() + bar.get_height()/2,
                f'{count:,}', va='center', fontsize=10)

    plt.tight_layout()

    # Save to buffer
    buf = io.BytesIO()
    fig.savefig(buf, format=format.value, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    buf.seek(0)

    media_types = {"png": "image/png", "svg": "image/svg+xml", "pdf": "application/pdf"}
    return Response(content=buf.getvalue(), media_type=media_types[format.value])


@app.get("/api/figures/temporal-trends")
async def figure_temporal_trends(
    format: FigureFormat = FigureFormat.png,
    width: float = 12,
    height: float = 5
):
    """Generate temporal trends line chart."""
    data = load_dashboard_data()
    if not data:
        return {"error": "Data not found"}

    trends = data["charts"]["annual_trends"]
    years = [t["year"] for t in trends]
    tc_density = [t["tc_density"] for t in trends]
    mc_density = [t["mc_density"] for t in trends]

    plt.style.use('seaborn-v0_8-whitegrid')
    plt.rcParams.update(FIGURE_STYLE)

    fig, ax = plt.subplots(figsize=(width, height))

    ax.plot(years, tc_density, 'o-', color=COLORS["marsh"], linewidth=2.5,
            markersize=8, label="Tidal Creek")
    ax.plot(years, mc_density, 's-', color=COLORS["ocean"], linewidth=2.5,
            markersize=8, label="Main Channel")

    ax.fill_between(years, tc_density, alpha=0.2, color=COLORS["marsh"])
    ax.fill_between(years, mc_density, alpha=0.2, color=COLORS["ocean"])

    ax.set_xlabel("Year")
    ax.set_ylabel("Fish Density (individuals/m²)")
    ax.set_title("Fish Density Trends by Habitat Type", fontweight="bold", pad=20)
    ax.legend(loc="upper right", frameon=True, fancybox=True)
    ax.set_xticks(years)
    ax.set_xticklabels(years, rotation=45, ha="right")

    plt.tight_layout()

    buf = io.BytesIO()
    fig.savefig(buf, format=format.value, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    buf.seek(0)

    media_types = {"png": "image/png", "svg": "image/svg+xml", "pdf": "application/pdf"}
    return Response(content=buf.getvalue(), media_type=media_types[format.value])


@app.get("/api/figures/habitat-comparison")
async def figure_habitat_comparison(
    format: FigureFormat = FigureFormat.png,
    width: float = 8,
    height: float = 6
):
    """Generate habitat comparison boxplot-style chart."""
    data = load_dashboard_data()
    if not data:
        return {"error": "Data not found"}

    habitat = data["model_results"]["habitat_comparison"]
    tc = habitat["tidal_creek"]
    mc = habitat["main_channel"]

    plt.style.use('seaborn-v0_8-whitegrid')
    plt.rcParams.update(FIGURE_STYLE)

    fig, axes = plt.subplots(1, 2, figsize=(width, height))

    # Density comparison
    ax1 = axes[0]
    x = [0, 1]
    means = [tc["mean_density"], mc["mean_density"]]
    stds = [tc["std_density"], mc["std_density"]]
    colors = [COLORS["marsh"], COLORS["ocean"]]

    bars = ax1.bar(x, means, yerr=stds, capsize=8, color=colors,
                   edgecolor="white", linewidth=2, error_kw={"linewidth": 2})
    ax1.set_xticks(x)
    ax1.set_xticklabels(["Tidal Creek", "Main Channel"])
    ax1.set_ylabel("Fish Density (individuals/m²)")
    ax1.set_title("Fish Density", fontweight="bold")

    # Add significance annotation
    p_val = habitat["density_test"]["p_value"]
    if p_val < 0.001:
        sig_text = "***"
    elif p_val < 0.01:
        sig_text = "**"
    elif p_val < 0.05:
        sig_text = "*"
    else:
        sig_text = "ns"

    y_max = max(means) + max(stds) + 5
    ax1.plot([0, 0, 1, 1], [y_max-2, y_max, y_max, y_max-2], 'k-', linewidth=1.5)
    ax1.text(0.5, y_max + 1, sig_text, ha='center', fontsize=14, fontweight='bold')

    # Richness comparison
    ax2 = axes[1]
    means = [tc["mean_richness"], mc["mean_richness"]]
    stds = [tc["std_richness"], mc["std_richness"]]

    bars = ax2.bar(x, means, yerr=stds, capsize=8, color=colors,
                   edgecolor="white", linewidth=2, error_kw={"linewidth": 2})
    ax2.set_xticks(x)
    ax2.set_xticklabels(["Tidal Creek", "Main Channel"])
    ax2.set_ylabel("Species Richness")
    ax2.set_title("Species Richness", fontweight="bold")

    fig.suptitle("Habitat Comparison: Carpinteria Salt Marsh",
                 fontsize=16, fontweight="bold", y=1.02)

    plt.tight_layout()

    buf = io.BytesIO()
    fig.savefig(buf, format=format.value, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    buf.seek(0)

    media_types = {"png": "image/png", "svg": "image/svg+xml", "pdf": "application/pdf"}
    return Response(content=buf.getvalue(), media_type=media_types[format.value])


@app.get("/api/figures/heatmap")
async def figure_heatmap(
    format: FigureFormat = FigureFormat.png,
    width: float = 14,
    height: float = 8
):
    """Generate species-year heatmap."""
    data = load_dashboard_data()
    if not data:
        return {"error": "Data not found"}

    heatmap_data = data["charts"]["heatmap"]
    years = sorted(set(h["year"] for h in heatmap_data))
    species = sorted(set(h["species"] for h in heatmap_data))

    # Build matrix
    matrix = np.zeros((len(species), len(years)))
    for h in heatmap_data:
        i = species.index(h["species"])
        j = years.index(h["year"])
        matrix[i, j] = h["value"]

    plt.style.use('seaborn-v0_8-whitegrid')
    plt.rcParams.update(FIGURE_STYLE)

    fig, ax = plt.subplots(figsize=(width, height))

    im = ax.imshow(matrix, cmap="YlGnBu", aspect="auto")

    ax.set_xticks(range(len(years)))
    ax.set_xticklabels(years, rotation=45, ha="right")
    ax.set_yticks(range(len(species)))
    ax.set_yticklabels(species)

    ax.set_xlabel("Year")
    ax.set_ylabel("Species")
    ax.set_title("Species Abundance Heatmap (Normalized)", fontweight="bold", pad=20)

    cbar = plt.colorbar(im, ax=ax, shrink=0.8)
    cbar.set_label("Relative Abundance", rotation=270, labelpad=20)

    plt.tight_layout()

    buf = io.BytesIO()
    fig.savefig(buf, format=format.value, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    buf.seek(0)

    media_types = {"png": "image/png", "svg": "image/svg+xml", "pdf": "application/pdf"}
    return Response(content=buf.getvalue(), media_type=media_types[format.value])


@app.get("/api/figures/diversity")
async def figure_diversity(
    format: FigureFormat = FigureFormat.png,
    width: float = 8,
    height: float = 6
):
    """Generate diversity indices visualization."""
    data = load_dashboard_data()
    if not data:
        return {"error": "Data not found"}

    div = data["model_results"]["diversity_indices"]

    plt.style.use('seaborn-v0_8-whitegrid')
    plt.rcParams.update(FIGURE_STYLE)

    fig, ax = plt.subplots(figsize=(width, height))

    indices = ["Shannon H'", "Simpson D", "Evenness J'"]
    values = [div["shannon"], div["simpson"], div["evenness"]]
    colors = [COLORS["ocean"], COLORS["marsh"], COLORS["sand"]]

    bars = ax.bar(indices, values, color=colors, edgecolor="white", linewidth=2)

    # Add value labels
    for bar, val in zip(bars, values):
        ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.05,
                f'{val:.2f}', ha='center', fontsize=14, fontweight='bold')

    ax.set_ylabel("Index Value")
    ax.set_title(f"Community Diversity Indices\n({div['richness']} species)",
                 fontweight="bold", pad=20)
    ax.set_ylim(0, max(values) * 1.3)

    plt.tight_layout()

    buf = io.BytesIO()
    fig.savefig(buf, format=format.value, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    buf.seek(0)

    media_types = {"png": "image/png", "svg": "image/svg+xml", "pdf": "application/pdf"}
    return Response(content=buf.getvalue(), media_type=media_types[format.value])


# Static files setup
PROJECT_ROOT = Path(__file__).parent.parent.parent


@app.get("/", response_class=HTMLResponse)
async def serve_observatory():
    """Serve the main observatory page."""
    html_path = PROJECT_ROOT / "observatory.html"
    if html_path.exists():
        return FileResponse(html_path)
    return HTMLResponse("<h1>Observatory not found</h1><p>Run the build first.</p>")


@app.get("/observatory.html", response_class=HTMLResponse)
async def serve_observatory_explicit():
    """Serve observatory.html explicitly."""
    return FileResponse(PROJECT_ROOT / "observatory.html")


@app.get("/dashboard.html", response_class=HTMLResponse)
async def serve_dashboard():
    """Serve legacy dashboard."""
    return FileResponse(PROJECT_ROOT / "dashboard.html")


# Mount static directories
app.mount("/outputs", StaticFiles(directory=PROJECT_ROOT / "outputs"), name="outputs")
app.mount("/data", StaticFiles(directory=PROJECT_ROOT / "data"), name="data")
app.mount("/assets", StaticFiles(directory=PROJECT_ROOT / "assets"), name="assets")


if __name__ == "__main__":
    import uvicorn
    print("Starting CSM Fish Observatory API...")
    print("API docs: http://localhost:8000/docs")
    print("Observatory: http://localhost:8000/observatory.html")
    print("Figures: http://localhost:8000/api/figures/species-abundance")
    uvicorn.run(app, host="0.0.0.0", port=8000)
