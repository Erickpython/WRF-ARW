#!/usr/bin/env bash
set -euo pipefail

# Target build directory (defaults to current working directory or pass path as $1)
TARGET_DIR="${1:-$PWD}"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "Working in: $(pwd)"

# 1. Clone WPS (skip if already present)
if [ ! -d "WPS/.git" ]; then
    git clone https://github.com/wrf-model/WPS.git
else
    echo "WPS already exists, skipping clone."
fi

# 2. Clone WRF release-v4.8.1 with submodules
if [ ! -d "WRF/.git" ]; then
    git clone -b release-v4.8.1 --recurse-submodules https://github.com/wrf-model/WRF.git
else
    echo "WRF already exists, skipping clone."
fi

# 3. Clone WRFDA release-v4.8.1 with submodules into WRFDA/
if [ ! -d "WRFDA/.git" ]; then
    git clone -b release-v4.8.1 --recurse-submodules https://github.com/wrf-model/WRF.git WRFDA
else
    echo "WRFDA already exists, skipping clone."
fi

# 4. Download and extract static WPS geographical data into WPS_GEOG
GEOG_ARCHIVE="geog_high_res_mandatory.tar.gz"
if [ ! -d "WPS_GEOG" ]; then
    wget -c "https://www2.mmm.ucar.edu/wrf/src/wps_files/${GEOG_ARCHIVE}"
    tar -xzvf "$GEOG_ARCHIVE"

    # If the archive extracts into a differently named folder, normalize to WPS_GEOG
    if [ ! -d "WPS_GEOG" ] && [ -d "WPS_GEOG_HIGH_RES_MANDATORY" ]; then
        mv WPS_GEOG_HIGH_RES_MANDATORY WPS_GEOG
    fi

    rm -f "$GEOG_ARCHIVE"
else
    echo "WPS_GEOG already exists, skipping download and extraction."
fi

echo "Done. Contents of $(pwd):"
ls -la "$TARGET_DIR"
