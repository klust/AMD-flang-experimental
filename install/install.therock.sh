#!/bin/bash 
set -x

umask 0022

#export BASE_PREFIX=/opt/hlrs/testing/unsupported
cd "$(dirname $0)"
export BASE_PREFIX="$(pwd)"
export TMPDIR=/tmp
export CACHE_DIR="$(pwd)/../cache"
mkdir -p $TMPDIR

export THEROCK="therock-afar-23.2.1-gfx90a-7.13.0-7357b5084b.tar.bz2"

export MPICH_VERSION='3.4a2'
export HDF5_VERSION='1.14.6'
export NETCDF_C_VERSION='4.9.3'
export NETCDF_FORTRAN_VERSION='4.6.2'
export PNETCDF_VERSION='1.14.1'
export FFTW_VERSION='3.3.10'
export LAPACK_VERSION='3.12.1'

# GPU architecture (LLVM/AMDGPU target). Consumed by:
#   - build.mpich-3.4a2.sh  (--with-hip-sm=${GPU_ARCH})
#   - rocm-libs.sh          (--offload-arch=${GPU_ARCH} in the cxxflags written
#                            into the rocm-libs modulefile)
# Override on the command line with -a|--arch <name>, e.g. gfx942 (MI300X),
# gfx1100 (RDNA3 7900-class), gfx1151, etc.
# Note: this is independent of the GPU arch baked into the TheRock drop
# filename ($THEROCK above). If you change GPU_ARCH you typically also need
# a matching TheRock drop built for that target.
export GPU_ARCH="gfx90a"
export MPICH_RELEASE="mpich-$MPICH_VERSION.tar.gz"
export HDF5_RELEASE="hdf5-$HDF5_VERSION.tar.gz"
export NETCDF_C_RELEASE="netcdf-c-$NETCDF_C_VERSION.tar.gz"
export NETCDF_FORTRAN_RELEASE="netcdf-fortran-$NETCDF_FORTRAN_VERSION.tar.gz"
export PNETCDF_RELEASE="pnetcdf-$PNETCDF_VERSION.tar.gz"
export FFTW_RELEASE="fftw-$FFTW_VERSION.tar.gz"
export THRUST_RELEASE="thrust-4.0.0.tgz"
export ROCPRIM_RELEASE="rocprim-4.0.0.tgz"
export LAPACK_RELEASE="lapack-$LAPACK_VERSION.tar.gz"

###############################################################################
# Component selection
#
# All components are built by default. Use --components/--only to build a
# specific subset, or --skip to exclude some. Components are listed in
# build order; the script will still load the upstream modules for any
# selected component, even if the component that produced those modules
# was skipped in this run. This is important because some component
# scripts read environment variables exported by upstream modulefiles
# (e.g. netcdf_c / netcdf_fortran read HDF5_DIR from the hdf5-parallel
# modulefile), and some scripts need mpicc/mpifort/etc. on PATH (set by
# the mpich modulefile) and ROCM_PATH (set by the therock modulefile).
#
# Available components (in build order):
#   therock   - unpack TheRock drop and generate the therock modulefile
#   mpich     - build MPICH 3.4a2 wrappers + libmpifort + module
#   hdf5      - build parallel HDF5 + module (produces HDF5_DIR)
#   pnetcdf   - build PnetCDF + module (produces PNETCDF_DIR)
#   netcdf_c  - build NetCDF-C + module (needs HDF5_DIR, pnetcdf)
#   netcdf_fortran - build NetCDF-Fortran + module (needs HDF5_DIR, netcdf_c)
#   fftw      - build FFTW + module
#   lapack    - build Reference LAPACK + module
#   rocm-libs - unpack thrust/rocprim into the therock tree + module
#
# Notes on dependencies:
#   * Every component (except therock itself) needs the therock module
#     loaded so ROCM_PATH and the compiler PATH are correct.
#   * Every component except therock and rocm-libs needs the mpich module
#     loaded so mpicc/mpifort/mpic++/mpif77 resolve to the wrappers we
#     installed. mpich's modulefile prepends our install/bin to PATH
#     after Cray's, which is exactly what the per-component configures
#     expect.
#   * netcdf_c and netcdf_fortran reference $HDF5_DIR directly; that
#     variable is set by the hdf5-parallel modulefile, so this script
#     always loads hdf5-parallel before those components, regardless of
#     whether hdf5 was (re)built in the same run.
#   * netcdf_fortran indirectly uses netcdf_c through linker paths
#     exposed by the netcdf_c modulefile.
###############################################################################

ALL_COMPONENTS=(therock mpich hdf5 pnetcdf netcdf_c netcdf_fortran fftw lapack rocm-libs)
SELECTED_COMPONENTS=("${ALL_COMPONENTS[@]}")
SKIP_COMPONENTS=()

usage() {
    cat <<EOF
Usage: $0 [options]
  -f, --file <name>        TheRock drop tarball (default: $THEROCK)
  -d, --dir <path>         Install prefix (default: $BASE_PREFIX)
  -a, --arch <name>        GPU target architecture (default: $GPU_ARCH).
                           Examples: gfx90a (MI200), gfx942 (MI300X),
                           gfx1100 (RDNA3), gfx1151. Consumed by mpich (HIP)
                           and rocm-libs (--offload-arch in the modulefile).
  -c, --components <list>  Comma-separated list of components to (re)build.
      --only <list>        Alias for --components.
      --skip <list>        Comma-separated list of components to skip.
      --list               Print the available components in build order and exit.
  -h, --help               Show this help and exit.

Components (in build order):
  ${ALL_COMPONENTS[*]}

Examples:
  # Default: build everything for gfx90a
  $0
  # Build everything targeting MI300X
  $0 --arch gfx942
  # Only rebuild hdf5 and downstream netcdf bits
  $0 --components hdf5,netcdf_c,netcdf_fortran
  # Rebuild everything except therock + mpich
  $0 --skip therock,mpich
EOF
}

# Parse comma-separated component list into an array (validated against ALL_COMPONENTS)
parse_component_list() {
    local raw="$1"
    local IFS=','
    read -ra _parsed <<< "$raw"
    for c in "${_parsed[@]}"; do
        local found=0
        for valid in "${ALL_COMPONENTS[@]}"; do
            if [[ "$c" == "$valid" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            local IFS=' '
            echo "Error: unknown component '$c'. Available: ${ALL_COMPONENTS[*]}" >&2
            exit 1
        fi
    done
}

DOWNLOAD=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            THEROCK="$2"
            shift 2
            ;;
        -d|--dir)
            BASE_PREFIX="$2"
            shift 2
            ;;
        -a|--arch)
            GPU_ARCH="$2"
            shift 2
            ;;
        -c|--components|--only)
            parse_component_list "$2"
            SELECTED_COMPONENTS=("${_parsed[@]}")
            shift 2
            ;;
        --skip)
            parse_component_list "$2"
            SKIP_COMPONENTS=("${_parsed[@]}")
            shift 2
            ;;
        --list)
            echo "Available components (in build order):"
            for c in "${ALL_COMPONENTS[@]}"; do echo "  $c"; done
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Compute final selection: SELECTED_COMPONENTS minus SKIP_COMPONENTS
is_selected() {
    local target="$1"
    local s
    for s in "${SKIP_COMPONENTS[@]}"; do
        [[ "$s" == "$target" ]] && return 1
    done
    for s in "${SELECTED_COMPONENTS[@]}"; do
        [[ "$s" == "$target" ]] && return 0
    done
    return 1
}

echo "==> GPU architecture: $GPU_ARCH"
echo "==> Components selected for this run:"
for c in "${ALL_COMPONENTS[@]}"; do
    if is_selected "$c"; then
        echo "    [build] $c"
    else
        echo "    [skip ] $c"
    fi
done

if [[ -z "$THEROCK" || -z "$BASE_PREFIX" ]]; then
    usage
    exit 1
fi

# Validate GPU_ARCH (LLVM/AMDGPU target names: gfx<digits/letters>).
# We accept anything that looks like "gfx<alnum>" to keep this future-proof,
# but require non-empty.
if [[ -z "$GPU_ARCH" ]]; then
    echo "Error: GPU_ARCH is empty. Pass --arch <name> or set GPU_ARCH in the environment."
    exit 1
fi
if [[ ! "$GPU_ARCH" =~ ^gfx[0-9a-fA-F]+$ ]]; then
    echo "Warning: GPU_ARCH='$GPU_ARCH' does not look like a typical AMDGPU target (gfx<hex>)."
    echo "         Continuing anyway; make sure your compiler supports it."
fi
# Re-export in case it was set via CLI after the initial export at the top.
export GPU_ARCH

# Sanity-check that the chosen TheRock drop targets the same GPU architecture.
# TheRock drop filenames embed the arch token, e.g.
#   therock-afar-23.2.1-gfx90a-7.13.0-7357b5084b.tar.bz2
# Building MPICH (--with-hip-sm) or rocm-libs (--offload-arch) for a different
# arch than what the drop was built for will produce a stack that either fails
# to link or silently produces unrunnable code, so refuse to proceed.
#
# This is intentionally a hard error rather than a warning: when it triggers,
# it's almost always a mistake (either pass the right --file or change --arch).
# If you have a custom drop whose filename does not embed the arch, set
# THEROCK_SKIP_ARCH_CHECK=1 in the environment to bypass.
if [[ -z "$THEROCK_SKIP_ARCH_CHECK" ]]; then
    therock_file_arch=$(echo "$THEROCK" | grep -oE 'gfx[0-9a-fA-F]+' | head -1)
    if [[ -z "$therock_file_arch" ]]; then
        echo "Error: could not extract a gfx<arch> token from THEROCK filename '$THEROCK'."
        echo "       Expected a name like 'therock-afar-<ver>-gfx90a-...tar.bz2'."
        echo "       Set THEROCK_SKIP_ARCH_CHECK=1 to bypass this check."
        exit 1
    fi
    if [[ "$therock_file_arch" != "$GPU_ARCH" ]]; then
        echo "Error: GPU_ARCH ('$GPU_ARCH') does not match the architecture of the"
        echo "       TheRock drop ('$therock_file_arch' in '$THEROCK')."
        echo "       Either pass --arch $therock_file_arch, or pass --file with a"
        echo "       drop built for $GPU_ARCH."
        echo "       Set THEROCK_SKIP_ARCH_CHECK=1 to bypass this check."
        exit 1
    fi
fi

if [[ -z $TMPDIR ]]; then
        echo "Error: TMPDIR has not been set."
        exit 1
fi

if [[ -z $CRAY_MPICH_PREFIX ]]; then
        echo "Error: CRAY_MPICH_PREFIX has not been set."
        exit 1
fi

export MPICH_DIR_CCE=$CRAY_MPICH_PREFIX
export ROCM_BASE_MODULE="rocm/6.3.4"

module unload cray-mpich
#module unload rocm
module unload cray-libsci
module unload cce
module unload craype

## set current working directory
wd=$(pwd)

if [[ ! -d $BASE_PREFIX ]]; then
        echo "Error: Directory '$BASE_PREFIX' does not exist."
        exit 1
fi
# Check if the destination directory is an absolute path
if [[ $BASE_PREFIX != /* ]]; then
        echo "Error: Destination directory '$BASE_PREFIX' is not an absolute path."
        exit 1
fi
# Check if the destination directory is writable
if [[ ! -w $BASE_PREFIX ]]; then
        echo "Error: Destination directory '$BASE_PREFIX' is not writable."
        exit 1
fi

# Cache-file existence checks. We always need templates + the therock drop
# in order to derive version_name / release_name (used by every component's
# install path and modulefile). The other tarballs are only required if the
# corresponding component is selected.
if [[ ! -f $CACHE_DIR/templates.therock.tgz ]]; then
        echo "Error: File '$CACHE_DIR/templates.therock.tgz' does not exist."
        exit 1
fi
if [[ ! -f $CACHE_DIR/$THEROCK ]]; then
        echo "Error: File '$CACHE_DIR/$THEROCK' does not exist."
        exit 1
fi
if is_selected mpich && [[ ! -f $CACHE_DIR/$MPICH_RELEASE ]]; then
        echo "Error: File '$CACHE_DIR/$MPICH_RELEASE' does not exist."
        exit 1
fi
if is_selected hdf5 && [[ ! -f $CACHE_DIR/$HDF5_RELEASE ]]; then
        echo "Error: File '$CACHE_DIR/$HDF5_RELEASE' does not exist."
        exit 1
fi
if is_selected pnetcdf && [[ ! -f $CACHE_DIR/$PNETCDF_RELEASE ]]; then
        echo "Error: File '$CACHE_DIR/$PNETCDF_RELEASE' does not exist."
        exit 1
fi
if is_selected netcdf_c && [[ ! -f $CACHE_DIR/$NETCDF_C_RELEASE ]]; then
        echo "Error: File '$CACHE_DIR/$NETCDF_C_RELEASE' does not exist."
        exit 1
fi
if is_selected netcdf_fortran && [[ ! -f $CACHE_DIR/$NETCDF_FORTRAN_RELEASE ]]; then
        echo "Error: File '$CACHE_DIR/$NETCDF_FORTRAN_RELEASE' does not exist."
        exit 1
fi
if is_selected fftw && [[ ! -f $CACHE_DIR/$FFTW_RELEASE ]]; then
        echo "Error: File '$CACHE_DIR/$FFTW_RELEASE' does not exist."
        exit 1
fi
if is_selected lapack && [[ ! -f $CACHE_DIR/$LAPACK_RELEASE ]]; then
        echo "Error: File '$CACHE_DIR/$LAPACK_RELEASE' does not exist."
        exit 1
fi

### naming conventions
# These derivations must always run, regardless of which components are
# selected, because every downstream step (and the modulefile loads that
# we use to populate the environment for skipped-but-still-needed
# components) references *_therock_version and release_name.
export release_name=$(tar -tf $CACHE_DIR/$THEROCK | head -1 | sed 's%^.*/\([^/]*\)/%\1%' | tr -d '/' | cut -d'-' -f1-3)
export mpich_release_dir=$(tar -tf $CACHE_DIR/$MPICH_RELEASE | head -1 | sed 's%^.*/\([^/]*\)/%\1%' | tr -d '/')
export hdf5_release_dir=$(tar -tf $CACHE_DIR/$HDF5_RELEASE | head -1 | sed 's%^.*/\([^/]*\)/%\1%' | tr -d '/')
export netcdf_c_release_dir=$(tar -tf $CACHE_DIR/$NETCDF_C_RELEASE | head -1 | sed 's%^.*/\([^/]*\)/%\1%' | tr -d '/')
export netcdf_fortran_release_dir=$(tar -tf $CACHE_DIR/$NETCDF_FORTRAN_RELEASE | head -1 | sed 's%^.*/\([^/]*\)/%\1%' | tr -d '/') 
export pnetcdf_release_dir=$(tar -tf $CACHE_DIR/$PNETCDF_RELEASE | head -1 | sed 's%^.*/\([^/]*\)/%\1%' | tr -d '/')
export fftw_release_dir=$(tar -tf $CACHE_DIR/$FFTW_RELEASE | head -1 | sed 's%^.*/\([^/]*\)/%\1%' | tr -d '/')
export lapack_release_dir=$(tar -tf $CACHE_DIR/$LAPACK_RELEASE | head -1 | sed 's%^.*/\([^/]*\)/%\1%' | tr -d '/')

export version_name=$(echo ${release_name} | sed 's/therock-afar-//g')
export mpich_therock_version=$(echo ${mpich_release_dir} | sed 's/mpich-//g')
export hdf5_therock_version=$(echo ${hdf5_release_dir} | sed 's/hdf5-//g')
export netcdf_c_therock_version=$(echo ${netcdf_c_release_dir} | sed 's/netcdf-c-//g')
export netcdf_fortran_therock_version=$(echo ${netcdf_fortran_release_dir} | sed 's/netcdf-fortran-//g')
export pnetcdf_therock_version=$(echo ${pnetcdf_release_dir} | sed 's/pnetcdf-//g')
export fftw_therock_version=$(echo ${fftw_release_dir} | sed 's/fftw-//g')
export lapack_therock_version=$(echo ${lapack_release_dir} | sed 's/lapack-//g')

#export version_name="${version_name}-hipstdpar-5538"
export rocm_libs_version="4.0.0"

# Make the locally-installed modulefile tree visible to Lmod. This must
# happen before any module load below, regardless of which components are
# selected, because we *load* upstream modules even for skipped components
# in order to populate the environment for selected downstream components.
module use ${BASE_PREFIX}/modulefiles/${release_name}
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to set module path."
    exit 1
fi

### -------------------- therock --------------------
# (Re)unpack the therock drop and install/refresh its modulefile.
# Even when skipped, downstream steps need ROCM_PATH from the therock module,
# which we load just below.
if is_selected therock; then
    cd $wd
    . ./build-therock.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build therock."
        exit 1
    fi
fi

# therock module is needed by every other component (provides ROCM_PATH and
# the amdclang/amdflang compilers on PATH). Load it now and only once.
# We do this unconditionally as long as ANY non-therock component is selected.
need_any_post_therock=0
for c in mpich hdf5 pnetcdf netcdf_c netcdf_fortran fftw lapack rocm-libs; do
    if is_selected "$c"; then need_any_post_therock=1; fi
done
if [[ $need_any_post_therock -eq 1 ]]; then
    module load therock/${version_name}
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to load therock module."
        exit 1
    fi
fi

### -------------------- mpich --------------------
if is_selected mpich; then
    cd $wd
    . ./build.mpich-3.4a2.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build MPICH."
        exit 1
    fi
fi

# mpich module supplies mpicc/mpifort/... on PATH; every component below
# (hdf5..lapack) calls those wrappers in its configure. Load it once if
# any of those components is selected.
need_any_mpich_user=0
for c in hdf5 pnetcdf netcdf_c netcdf_fortran fftw lapack; do
    if is_selected "$c"; then need_any_mpich_user=1; fi
done
if [[ $need_any_mpich_user -eq 1 ]]; then
    module load mpich/${mpich_therock_version}
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to load mpich module."
        exit 1
    fi
fi

### -------------------- hdf5 (parallel) --------------------
if is_selected hdf5; then
    cd $wd
    . ./hdf5_setup_quick.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set up HDF5."
        exit 1
    fi
fi

# hdf5-parallel module exports HDF5_DIR which is read literally by the
# netcdf_c and netcdf_fortran configure invocations (CPPFLAGS=-I$HDF5_DIR/include
# LDFLAGS=-L$HDF5_DIR/lib). Load it for any selected downstream component
# that needs it. pnetcdf does not strictly need HDF5_DIR for its own configure
# but the original script loaded hdf5-parallel before pnetcdf, so we keep
# that ordering (harmless: just adds HDF5 to LD_LIBRARY_PATH).
need_hdf5_module=0
for c in pnetcdf netcdf_c netcdf_fortran; do
    if is_selected "$c"; then need_hdf5_module=1; fi
done
if [[ $need_hdf5_module -eq 1 ]]; then
    module load hdf5-parallel/${hdf5_therock_version}
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to load hdf5-parallel module."
        exit 1
    fi
fi

### -------------------- pnetcdf --------------------
if is_selected pnetcdf; then
    cd $wd
    . ./pnetcdf_setup_quick.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set up PnetCDF."
        exit 1
    fi
fi

# pnetcdf module exports PNETCDF_DIR and puts pnetcdf libs on LD_LIBRARY_PATH;
# netcdf_c configures with --enable-pnetcdf and links against it.
need_pnetcdf_module=0
for c in netcdf_c netcdf_fortran; do
    if is_selected "$c"; then need_pnetcdf_module=1; fi
done
if [[ $need_pnetcdf_module -eq 1 ]]; then
    module load pnetcdf/${pnetcdf_therock_version}
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to load pnetcdf module."
        exit 1
    fi
fi

### -------------------- netcdf_c --------------------
if is_selected netcdf_c; then
    cd $wd
    . ./netcdf_c_setup_quick.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set up NetCDF C."
        exit 1
    fi
fi

# netcdf_c module exports NETCDF_DIR and puts the netcdf C lib on
# LD_LIBRARY_PATH / LIBRARY_PATH; needed when (re)building netcdf_fortran.
# Note: the previous version of this script had a typo here
# (netcdfc_therock_version), which silently expanded to an empty string,
# causing this module load to be a no-op. The correct variable is
# netcdf_c_therock_version (with underscore), exported above.
if is_selected netcdf_fortran; then
    module load netcdf_c/${netcdf_c_therock_version}
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to load netcdf_c module."
        exit 1
    fi
fi

### -------------------- netcdf_fortran --------------------
if is_selected netcdf_fortran; then
    cd $wd
    . ./netcdf_fortran_setup_quick.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set up NetCDF Fortran."
        exit 1
    fi
fi

### -------------------- fftw --------------------
if is_selected fftw; then
    cd $wd
    . ./fftw_setup_quick.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set up FFTW."
        exit 1
    fi
fi

### -------------------- lapack --------------------
if is_selected lapack; then
    cd $wd
    . ./lapack_setup_quick.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set up LAPACK."
        exit 1
    fi
fi

### -------------------- rocm-libs --------------------
if is_selected rocm-libs; then
    cd $wd
    . ./rocm-libs.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set up ROCm libraries."
        exit 1
    fi
fi

#cd ${TMPDIR}
#rm -rf template tmp.* build-lapack
