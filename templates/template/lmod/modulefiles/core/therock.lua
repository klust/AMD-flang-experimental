whatis("Name: therock-drop")
whatis("Version: __THEROCK_VERSION__")
whatis("Category: compiler")
whatis("URL: https://repo.radeon.com/rocm/misc/flang/__THEROCK__")

family("rocm_therock")
conflict("therock")
depends_on('__ROCM_BASE_MODULE__')

local base = "__THEROCK_DEST_DIR__"

prepend_path("LD_LIBRARY_PATH", pathJoin(base, "lib"))
prepend_path("LD_LIBRARY_PATH", pathJoin(base, "llvm/lib"))
prepend_path("LD_LIBRARY_PATH", pathJoin(base, "lib/rocm_sysdeps/lib"))

prepend_path("LIBRARY_PATH", pathJoin(base, "lib"))
prepend_path("LIBRARY_PATH", pathJoin(base, "llvm/lib"))
prepend_path("LIBRARY_PATH", pathJoin(base, "lib/rocm_sysdeps/lib"))

prepend_path("C_INCLUDE_PATH", pathJoin(base, "include"))
prepend_path("CPLUS_INCLUDE_PATH", pathJoin(base, "include"))
prepend_path("CPATH", pathJoin(base, "include"))
prepend_path("PATH", pathJoin(base, "bin"))
prepend_path("INCLUDE", pathJoin(base, "include"))
prepend_path("MANPATH", pathJoin(base, "share", "man"))

pushenv("DEVICE_LIB_PATH", pathJoin(base, "amdgcn/bitcode"))
pushenv("ROCM_PATH",base)
pushenv("LLVM_PATH", base)

setenv("HSA_ENABLE_IPC_MODE_LEGACY", "1")

setenv("HIPFORT_PATH", base)
setenv("HIPFORT_HOME", base)
setenv("HIPFORT_LIB", pathJoin(base, "lib"))
setenv("HIPFORT_INC", pathJoin(base, "include/hipfort/amdgcn"))

unsetenv("CC")
unsetenv("cc")
unsetenv("ftn")


