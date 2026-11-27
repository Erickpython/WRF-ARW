```markdown
# Automated WRF, WPS, and WRFDA Build Suite (`WRF-ARW`)

This repository provides automated shell scripts to download, configure, compile, and verify the **Weather Research and Forecasting (WRF-ARW)** model, the **WRF Preprocessing System (WPS)**, and **WRF Data Assimilation (WRFDA)** on Linux using the **GNU (`gcc` / `g++` / `gfortran`)** compiler suite.

These scripts are designed for **GNU/gfortran** compilers and have been tested with GCC versions **v11.4.0**, **v11.5.0**, and **v15.2.0** (including GCC 15 compatibility handling for legacy code such as `jasper-1.900.1` and `WRFDA`).

---

## Quick Start

1. **Clone the repository and enter the directory:**
   ```bash
   git clone [https://github.com/Erickpython/WRF-ARW.git](https://github.com/Erickpython/WRF-ARW.git)
   cd WRF-ARW

```

Right after cloning, the directory contains only the shell scripts (`master.sh`, `build_wrfdependencies.sh`, `get_wrf_sources.sh`, `compile_wrf_wps_wrfda.sh`) and `README.md`.

2. **Run `master.sh`:**
You can run it directly with `bash`:
```bash
bash master.sh

```


Or make the scripts executable first and run `./master.sh`:
```bash
chmod +x *.sh
./master.sh

```



### Installing in Another Location

If you want to build WRF, WPS, and WRFDA in a different directory (for example, `~/Build_Wrf` or a scratch/storage partition), copy the scripts there and run `master.sh` from that folder:

```bash
mkdir -p ~/Build_Wrf
cp *.sh ~/Build_Wrf/
cd ~/Build_Wrf
./master.sh

```

*(Alternatively, if you already have `master.sh` in `WRF-ARW`, you can pass a target directory argument such as `./master.sh /path/to/target_dir`.)*

---

## Directory Structure (Before & After Build)

### Fresh Clone

```text
WRF-ARW/
├── README.md
├── build_wrfdependencies.sh
├── compile_wrf_wps_wrfda.sh
├── get_wrf_sources.sh
└── master.sh

```

### After Running `master.sh`

Everything—compiled libraries, model source trees, static geography data, `.wrfmodules`, and logs—is placed inside the build directory:

```text
WRF-ARW/
├── README.md
├── build_wrfdependencies.sh
├── compile_wrf_wps_wrfda.sh
├── get_wrf_sources.sh
├── master.sh
├── .wrfmodules
├── wrf_dependencies/
├── WRF/
├── WPS/
├── WRFDA/
├── WPS_GEOG/
├── wrf_setup_YYYYMMDD_HHMMSS.log
└── compile_logs_YYYYMMDD_HHMMSS/

```

---

## What Gets Built & Downloaded

### 1. Core Dependencies (`build_wrfdependencies.sh`)

Compiled and installed into `wrf_dependencies/` (with `grib2`, `netcdf`, and `mpich` prefixes):

* **zlib:** `1.3.2`
* **HDF5:** `1.14.5`
* **netCDF-C:** `4.10.0`
* **netCDF-Fortran:** `4.6.2`
* **MPICH:** `5.0.0`
* **libpng:** `1.6.56`
* **JasPer:** `1.900.1`

### 2. Model Sources & Static Geography (`get_wrf_sources.sh`)

* **WRF (`v4.8.1`):** Cloned from `https://github.com/wrf-model/WRF.git` (`release-v4.8.1` with submodules) into `WRF/`.
* **WPS (`v4.7.0`):** Cloned from `https://github.com/wrf-model/WPS.git` into `WPS/`.
* **WRFDA:** Cloned from `https://github.com/wrf-model/WRF.git` (`release-v4.8.1` with submodules) into `WRFDA/`.
* **Important Note on 3DVAR vs. 4DVAR:** This build setup is specifically for **3DVAR** data assimilation (`all_wrfvar`) and **cannot** be used to run **4DVAR**—only **3DVAR**.


* **WPS Static Geographical Data (`WPS_GEOG/`):** Downloads and extracts the **high-resolution mandatory** static geography dataset (`geog_high_res_mandatory.tar.gz`) into `WPS_GEOG/` for domain creation with `geogrid.exe`.

---

## Setting Up Your Environment (`.wrfmodules` and `~/.bashrc`)

`build_wrfdependencies.sh` generates a `.wrfmodules` file containing the environment variables (`DIR`, `NETCDF`, `MPICH`, `LD_LIBRARY_PATH`, `PATH`, `JASPERLIB`, `JASPERINC`) required to run the compiled tools.

Whenever you open a new shell to run WPS, WRF, or WRFDA, load the environment using either method below:

### Option A: Source `.wrfmodules` When Needed

```bash
source .wrfmodules

```

### Option B: Persist in `~/.bashrc` (Recommended for Frequent Use)

Open `.wrfmodules`, copy or append its contents into `~/.bashrc`, and reload `~/.bashrc`:

```bash
cat .wrfmodules >> ~/.bashrc
source ~/.bashrc

```

---

## Expected Build Completion & Verification Output

When `compile_wrf_wps_wrfda.sh` (invoked by `master.sh`) finishes compiling and verifying **WRF** (`em_real`), **WPS**, and **WRFDA** (`all_wrfvar`), you will see verification output ending with:

```text
WRFDA var/build non-empty *.exe count : 43 (expected 43)
WRFDA var/da symlink *.exe count      : 43 (expected 43)

============================================================
 All builds (WRF, WPS, WRFDA) completed and verified!
 Logs saved under: /home/ubuntu/Build_Wrf/compile_logs_20261127_163411
============================================================

```

---

## Managing Build & Setup Log Files

Once you have confirmed that everything compiled and passed verification cleanly, you can either **keep** the log files (`wrf_setup_*.log` and `compile_logs_*`) for future reference or **delete** them to free up disk space:

```bash
# Optional: remove setup and compilation logs after confirming success
rm -rf wrf_setup_*.log compile_logs_*

```

---

## References & Acknowledgments

These scripts were built with guidance from official NCAR/MMM documentation:

* **WRF & WPS Compilation Tutorial:** [https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php](https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php)
* **WRFDA Data Assimilation User's Guide:** [https://www2.mmm.ucar.edu/wrf/users/docs/user_guide_v4/v4.4/users_guide_chap6.html#_Introduction_2](https://www2.mmm.ucar.edu/wrf/users/docs/user_guide_v4/v4.4/users_guide_chap6.html#_Introduction_2)

```

### Save and Push to GitHub

1. Save the text above as `README.md` in your repository root (`WRF-ARW/README.md`), then stage, commit, and push:
   ```bash
   git add README.md
   git commit -m "Add comprehensive README documenting WRF, WPS, and WRFDA build pipeline"
   git push

```

*Verification:* Run `git status` to confirm no untracked or leftover files remain, and check your repository page on GitHub to verify `README.md` renders cleanly.