#!/bin/bash
# scripts/utils/backup.sh
set -e

BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup database
docker-compose exec -T db pg_dump -U postgres app > "$BACKUP_DIR/db.sql"

# Backup configurations
cp -r config/ "$BACKUP_DIR/config"

# Backup media files
cp -r media/ "$BACKUP_DIR/media"

# Create archive
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"

#!/bin/bash
# scripts/utils/cleanup.sh
set -e

echo "Cleaning up environment..."

# Remove temporary files
rm -rf temp/*
rm -rf __pycache__
rm -rf .pytest_cache
rm -rf .coverage
rm -rf htmlcov

# Clean Docker
docker system prune -f

# Clean Android builds if present
if [ -f "gradlew" ]; then
    ./gradlew clean
fi

#!/bin/bash
# scripts/utils/generate_docs.sh
set -e

echo "Generating documentation..."

# Generate API documentation
sphinx-build -b html docs/source docs/build

# Generate Android documentation if present
if [ -f "gradlew" ]; then
    ./gradlew dokka
fi

# Build MkDocs site
mkdocs build

# Create PDF documentation
scripts/utils/generate_pdf_docs.sh