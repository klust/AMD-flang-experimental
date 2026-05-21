# README for the experimental flang installation

From the mail:

Past, current and future tar.gz of relatively new therock-afar (full pre-release rocm) and the previous afar (only compiler with a selection of libraries) are available [here: https://repo.radeon.com/rocm/misc/flang/](https://repo.radeon.com/rocm/misc/flang/).

The versions I can currently truly recommend are afar 22.2.0 (prior to a major rework of mapping) and 23.2.1 (what we have now on LUMI). If something works with version 22.2.0 but not 23.2.1 or something is broken in 23.2.1 please reach out to me so I can coordinate that the compiler team can fix it.

If you just need the compiler: untar and you are done (maybe you like to produce a module so it is easier to find things when compiling).

If you are interested in the full installation with MPICH and some more modules I did on LUMI:
It assumes as a starting point you have a reasonable combination of CPE modules loaded to compile something for GPUs.
Then run:

```
/projappl/project_462000125/jopotyka/Fortran-Drop-23.2.1/install/install.therock.sh
```

calls other .sh scripts in the same folder to install the modules. If you find some issues with those, please also tell me, so I can improve it.

I'm also still working to get the same scripts running on both Hunter and LUMI. I had to adapt the Hunter scripts slightly for LUMI, so now I still plan to try if the LUMI scripts are now applicable. Note that the dependency versions are currently fixed to what works with cray-mpich 8.1.33. Note that the mpich version used to build the Fortran modules must match the cray-mpich version otherwise the Fortran modules produced may not work.