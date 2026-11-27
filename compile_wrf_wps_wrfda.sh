#!/usr/bin/env bash
set -euo pipefail

# Base directory containing .wrfmodules, WRF/, WPS/, and WRFDA/
# Pass a custom path as $1 if your build directories are elsewhere.
BASE_DIR="${1:-$PWD}"
BASE_DIR="$(cd "$BASE_DIR" && pwd)"

MODULES_FILE="${2:-$BASE_DIR/.wrfmodules}"
WRF_DIR="$BASE_DIR/WRF"
WPS_DIR="$BASE_DIR/WPS"
WRFDA_DIR="$BASE_DIR/WRFDA"

# Optional: override parallel job count (default: all available cores via nproc)
NPROCS="${NPROCS:-$(nproc)}"
export J="-j ${NPROCS}"

LOG_DIR="$BASE_DIR/compile_logs_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"

require_dir() {
    if [ ! -d "$1" ]; then
        echo "ERROR: Required directory not found: $1" >&2
        exit 1
    fi
}

require_non_empty_file() {
    if [ ! -s "$1" ]; then
        echo "ERROR: Expected non-empty file missing: $1" >&2
        exit 1
    fi
}

if [ ! -f "$MODULES_FILE" ]; then
    echo "ERROR: .wrfmodules file not found at: $MODULES_FILE" >&2
    exit 1
fi

require_dir "$WRF_DIR"
require_dir "$WPS_DIR"
require_dir "$WRFDA_DIR"

echo "============================================================"
echo " WRF / WPS / WRFDA Automated Configuration & Compilation"
echo " Base Dir   : $BASE_DIR"
echo " Modules    : $MODULES_FILE"
echo " Jobs (J)   : $J"
echo " Logs       : $LOG_DIR"
echo "============================================================"

# ------------------------------------------------------------
# 0. Source .wrfmodules and clear dependency-only build flags
# ------------------------------------------------------------
echo ""
echo "[0/3] Sourcing $MODULES_FILE..."
# shellcheck disable=SC1090
source "$MODULES_FILE"

# Ensure build-only flags from dependency compilation do not leak into WRF/WPS/WRFDA
unset CC CXX FC FCFLAGS F77 FFLAGS LDFLAGS CPPFLAGS || true

# ------------------------------------------------------------
# 1. Configure and compile WRF (em_real -> option 34, basic 1)
# ------------------------------------------------------------
echo ""
echo "[1/3] Configuring and compiling WRF (em_real)..."
cd "$WRF_DIR"
./clean -a >/dev/null 2>&1 || true

# Option 34 = x86_64 Linux, gfortran (GNU) with dmpar; Option 1 = basic nesting
printf "34\n1\n" | ./configure 2>&1 | tee "$LOG_DIR/wrf_configure.log"

if [ ! -f "configure.wrf" ]; then
    echo "ERROR: WRF configure.wrf was not generated." >&2
    exit 1
fi

./compile em_real 2>&1 | tee "$LOG_DIR/wrf_compile.log"

echo ""
echo "--- Verifying WRF executables in $WRF_DIR/main/*.exe ---"
ls -ls "$WRF_DIR"/main/*.exe
for exe in wrf.exe real.exe ndown.exe tc.exe; do
    require_non_empty_file "$WRF_DIR/main/$exe"
done
echo "WRF verification passed (wrf.exe, real.exe, ndown.exe, tc.exe present)."

# ------------------------------------------------------------
# 2. Configure and compile WPS (WRF_DIR -> option 3)
# ------------------------------------------------------------
echo ""
echo "[2/3] Configuring and compiling WPS..."
export WRF_DIR
cd "$WPS_DIR"
./clean -a >/dev/null 2>&1 || true

printf "3\n" | ./configure 2>&1 | tee "$LOG_DIR/wps_configure.log"

if [ ! -f "configure.wps" ]; then
    echo "ERROR: WPS configure.wps was not generated." >&2
    exit 1
fi

./compile 2>&1 | tee "$LOG_DIR/wps_compile.log"

echo ""
echo "--- Verifying WPS executables and symlinks ---"
ls -ls "$WPS_DIR"/geogrid.exe "$WPS_DIR"/ungrib.exe "$WPS_DIR"/metgrid.exe
ls -ls "$WPS_DIR"/geogrid/src/geogrid.exe "$WPS_DIR"/ungrib/src/ungrib.exe "$WPS_DIR"/metgrid/src/metgrid.exe

for link in geogrid.exe ungrib.exe metgrid.exe; do
    if [ ! -L "$WPS_DIR/$link" ]; then
        echo "ERROR: Expected symlink missing: $WPS_DIR/$link" >&2
        exit 1
    fi
done
require_non_empty_file "$WPS_DIR/geogrid/src/geogrid.exe"
require_non_empty_file "$WPS_DIR/ungrib/src/ungrib.exe"
require_non_empty_file "$WPS_DIR/metgrid/src/metgrid.exe"
echo "WPS verification passed (geogrid.exe, ungrib.exe, metgrid.exe linked and non-empty)."

# ------------------------------------------------------------
# 3. Configure and compile WRFDA (all_wrfvar -> option 34)
# ------------------------------------------------------------
echo ""
echo "[3/3] Configuring and compiling WRFDA (all_wrfvar)..."
cd "$WRFDA_DIR"
./clean -a >/dev/null 2>&1 || true

printf "34\n" | ./configure wrfda 2>&1 | tee "$LOG_DIR/wrfda_configure.log"

if [ ! -f "configure.wrf" ]; then
    echo "ERROR: WRFDA configure.wrf was not generated." >&2
    exit 1
fi

GCC_MAJOR="$(gcc -dumpversion | cut -d. -f1)"
echo "Detected GCC major version for WRFDA: ${GCC_MAJOR}"

# Always update FCCOMPAT for gfortran compatibility
sed -i 's|^FCCOMPAT[[:space:]]*=.*|FCCOMPAT        =       -fallow-argument-mismatch -fallow-invalid-boz|' configure.wrf

# On GCC 15, also add -std=gnu17 to CFLAGS_LOCAL
if [ "$GCC_MAJOR" = "15" ]; then
    sed -i 's|^\(CFLAGS_LOCAL[[:space:]]*=.*\)$|\1 -std=gnu17|' configure.wrf
fi

./compile all_wrfvar >& "$LOG_DIR/wrfda_compile.out"
cat "$LOG_DIR/wrfda_compile.out"

echo ""
echo "--- Verifying WRFDA executables ---"
ls -l "$WRFDA_DIR"/var/build/*exe "$WRFDA_DIR"/var/obsproc/src/obsproc.exe

require_non_empty_file "$WRFDA_DIR/var/obsproc/src/obsproc.exe"
BUILD_EXE_COUNT=$(find "$WRFDA_DIR/var/build" -maxdepth 1 -type f -name '*exe' -size +0c | wc -l)
DA_LINK_COUNT=$(find "$WRFDA_DIR/var/da" -maxdepth 1 -type l -name '*exe' | wc -l)

echo "WRFDA var/build non-empty *.exe count : $BUILD_EXE_COUNT (expected 43)"
echo "WRFDA var/da symlink *.exe count      : $DA_LINK_COUNT (expected 43)"

if [ "$BUILD_EXE_COUNT" -lt 43 ]; then
    echo "ERROR: Expected 43 executables in $WRFDA_DIR/var/build, found $BUILD_EXE_COUNT. Inspect $LOG_DIR/wrfda_compile.out." >&2
    exit 1
fi

echo ""
echo "============================================================"
echo " All builds (WRF, WPS, WRFDA) completed and verified!"
echo " Logs saved under: $LOG_DIR"
echo "============================================================"
