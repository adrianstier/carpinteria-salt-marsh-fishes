# Carpinteria Salt Marsh Fish Observatory
# Makefile for automated data pipeline builds

.PHONY: all clean data api dashboard report serve help

# Default target
all: data api
	@echo "Build complete! Run 'make serve' to start the server."

# Help
help:
	@echo "Carpinteria Salt Marsh Fish Observatory - Build Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Run full pipeline (data + api)"
	@echo "  data      - Download data from EDI repository"
	@echo "  api       - Generate dashboard API JSON from data"
	@echo "  serve     - Start the FastAPI server (http://localhost:8000)"
	@echo "  report    - Render R Markdown report (requires R)"
	@echo "  clean     - Remove generated files"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Quick start:"
	@echo "  make all       # Build everything"
	@echo "  make serve     # Start the observatory server"

# Download data from EDI repository
data:
	@echo "Downloading data from EDI repository..."
	python3 -m src.etl.download
	@echo "Data download complete."

# Generate dashboard API JSON
api: outputs/api/dashboard_data.json

outputs/api/dashboard_data.json: data/raw/edi.648.8/*.csv data/raw/edi.647.8/*.csv src/export/dashboard_api.py
	@echo "Generating dashboard API..."
	@mkdir -p outputs/api outputs/stats
	python3 -m src.export.dashboard_api
	@echo "API generated: outputs/api/dashboard_data.json"

# Render R Markdown report (optional - requires R and rmarkdown)
report: carpinteria_salt_marsh_fishes.html

carpinteria_salt_marsh_fishes.html: carpinteria_salt_marsh_fishes.Rmd
	@echo "Rendering R Markdown report..."
	@if command -v Rscript >/dev/null 2>&1; then \
		Rscript -e "rmarkdown::render('carpinteria_salt_marsh_fishes.Rmd')"; \
	else \
		echo "Warning: R not found. Skipping report generation."; \
	fi

# Start the FastAPI server
serve:
	@echo "Starting Carpinteria Salt Marsh Fish Observatory..."
	@echo "Visit: http://localhost:8000"
	@echo "API Docs: http://localhost:8000/docs"
	@echo "Press Ctrl+C to stop"
	python3 -m src.api.server

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -rf outputs/api/*.json
	rm -rf outputs/stats/*.json
	rm -rf data/processed/*.parquet
	@echo "Clean complete."

# Deep clean - also remove downloaded data
clean-all: clean
	@echo "Removing downloaded data..."
	rm -rf data/raw/edi.648.8/*.csv
	rm -rf data/raw/edi.647.8/*.csv
	@echo "Deep clean complete."
