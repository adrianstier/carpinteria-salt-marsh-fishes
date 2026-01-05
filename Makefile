# Carpinteria Salt Marsh Fish Observatory
# Makefile for R-based data pipeline

.PHONY: all clean data analysis json serve help

# Default target
all: json
	@echo "Build complete! Run 'make serve' to view the observatory."

# Help
help:
	@echo "Carpinteria Salt Marsh Fish Observatory - Build Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Run full R pipeline (data → analysis → json)"
	@echo "  data      - Download data from EDI repository"
	@echo "  analysis  - Run statistical analyses in R"
	@echo "  json      - Export analysis results to JSON for D3"
	@echo "  serve     - Start local HTTP server (http://localhost:8000)"
	@echo "  clean     - Remove generated outputs"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Quick start:"
	@echo "  make all       # Run full pipeline"
	@echo "  make serve     # View the observatory"

# Download data from EDI repository
data: data/raw/edi.648.8/wetland_ts_fish_enclosure_trap.csv

data/raw/edi.648.8/wetland_ts_fish_enclosure_trap.csv:
	@echo "Downloading data from EDI repository..."
	Rscript R/01_download_data.R
	@echo "Data download complete."

# Run statistical analyses
analysis: outputs/analysis_results.rds

outputs/analysis_results.rds: data R/02_analysis.R
	@echo "Running statistical analyses..."
	Rscript R/02_analysis.R
	@echo "Analysis complete."

# Export to JSON for D3 dashboard
json: outputs/dashboard_data.json

outputs/dashboard_data.json: outputs/analysis_results.rds R/03_export_json.R R/04_advanced_analysis.R R/05_export_advanced_json.R
	@echo "Exporting JSON for D3 dashboard..."
	Rscript R/03_export_json.R
	@echo "Running advanced analyses..."
	Rscript R/04_advanced_analysis.R
	Rscript R/05_export_advanced_json.R
	@echo "JSON export complete: outputs/dashboard_data.json"

# Start local HTTP server for static site
serve:
	@echo "Starting Carpinteria Salt Marsh Fish Observatory..."
	@echo "Visit: http://localhost:8000"
	@echo "Press Ctrl+C to stop"
	python3 -m http.server 8000

# Clean generated files
clean:
	@echo "Cleaning generated outputs..."
	rm -f outputs/dashboard_data.json
	rm -f outputs/analysis_results.rds
	@echo "Clean complete."

# Deep clean - also remove downloaded data
clean-all: clean
	@echo "Removing downloaded data..."
	rm -rf data/raw/edi.648.8/*.csv
	rm -rf data/raw/edi.647.8/*.csv
	@echo "Deep clean complete."
