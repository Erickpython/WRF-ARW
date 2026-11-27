#!/usr/bin/env bash
set -euo pipefail

# Resolve the directory where master.sh lives so it works regardless of where it is called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Optional target directory argument (defaults to current working directory)
TARGET_DIR="${1:-$PWD}"
mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

DEP_SCRIPT="$SCRIPT_DIR/build_wrfdependencies.sh"
SRC_SCRIPT="$SCRIPT_DIR/get_wrf_sources.sh"
CMP_SCRIPT="$SCRIPT_DIR/compile_wrf_wps_wrfda.sh"
LOG_FILE="$TARGET_DIR/wrf_setup_$(date +%Y%m%d_%H%M%S).log"

# Verify required scripts exist
for script in "$DEP_SCRIPT" "$SRC_SCRIPT" "$CMP_SCRIPT"; do
    if [ ! -f "$script" ]; then
        echo "ERROR: Required script not found: $script" >&2
        exit 1
    fi
done

# Ensure executable permissions for users who just cloned/forked the repo
chmod +x "$DEP_SCRIPT" "$SRC_SCRIPT" "$CMP_SCRIPT"

echo "============================================================"
echo " Starting WRF-ARW Full Environment, Source & Build Setup"
echo " Target Directory : $TARGET_DIR"
echo " Log File         : $LOG_FILE"
echo "============================================================"

cd "$TARGET_DIR"

# Step 1: Build the 7 core libraries and generate .wrfmodules
# Executed in a subshell so temporary build flags (CPPFLAGS, LDFLAGS, etc.) do not leak.
echo ""
echo "[1/3] Building WRF dependencies (zlib, hdf5, netcdf-c, netcdf-fortran, mpich, libpng, jasper)..."
bash "$DEP_SCRIPT" "$TARGET_DIR/.wrfmodules" 2>&1 | tee -a "$LOG_FILE"

if [ ! -f "$TARGET_DIR/.wrfmodules" ]; then
    echo "ERROR: .wrfmodules was not generated. Check $LOG_FILE for build errors." >&2
    exit 1
fi

# Step 2: Clone WRF, WRFDA, WPS and download WPS_GEOG static data
echo ""
echo "[2/3] Fetching WRF v4.8.1, WRFDA, WPS sources and high-res WPS_GEOG data..."
bash "$SRC_SCRIPT" "$TARGET_DIR" 2>&1 | tee -a "$LOG_FILE"

# Step 3: Configure and compile WRF, WPS, and WRFDA
echo ""
echo "[3/3] Configuring and compiling WRF, WPS, and WRFDA..."
bash "$CMP_SCRIPT" "$TARGET_DIR" "$TARGET_DIR/.wrfmodules" 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "============================================================"
echo " Full Setup & Compilation Complete!"
echo " Load your environment in any new shell with:"
echo "   source \"$TARGET_DIR/.wrfmodules\""
echo "============================================================"
