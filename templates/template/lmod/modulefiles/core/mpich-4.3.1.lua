whatis("Name: mpich-4.3.1")
whatis("Version: 4.3.1")
whatis("Category: compiler")
whatis("URL: https://www.mpich.org/static/downloads/4.3.1")

local base = "__MPICH_DEST_DIR__"

depends_on('therock/__THEROCK_VERSION__')

setenv("CRAY_MPICH_VER","__CRAY_MPICH_VER__")
setenv("CRAY_MPICH_VERSION","__CRAY_MPICH_VERSION__")
-- Don't need this as we are not using the craype wrappers anyway.
-- setenv("CRAY_MPICH_ROOTDIR","__CRAY_MPICH_ROOTDIR__")
-- setenv("CRAY_MPICH_BASEDIR","__CRAY_MPICH_BASEDIR__")
-- setenv("CRAY_MPICH_DIR","__CRAY_MPICH_DIR__")
-- setenv("CRAY_MPICH_PREFIX","__CRAY_MPICH_PREFIX__")
-- prepend_path("MANPATH","__CRAY_MPICH_ROOTDIR__/man/mpich")
-- prepend_path("MANPATH","__CRAY_MPICH_ROOTDIR__/ofi/man")
-- prepend_path("PATH","__CRAY_MPICH_ROOTDIR__/bin")
-- prepend_path("PATH","__CRAY_MPICH_PREFIX__/bin")
-- prepend_path("LD_LIBRARY_PATH","__CRAY_MPICH_PREFIX__/lib")
setenv("MPICH_DIR","__MPICH_DIR__")
prepend_path("LD_LIBRARY_PATH", pathJoin(base, "lib"))
prepend_path("LIBRARY_PATH", pathJoin(base, "lib"))
prepend_path("PATH", pathJoin(base, "bin"))
prepend_path("INCLUDE", pathJoin(base, "include"))

