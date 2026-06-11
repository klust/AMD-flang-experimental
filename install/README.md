# Changes made

-   Probably to be undone again: Added various variables with the versions of the
    packages and names of the files to download, to easily re-use that in a 
    download script. However, the `install.therock.sh` script contains tricks
    further down in the script to extract versions of software.

-   Changed the modules of all packages except `therock` and `mpich`: Added a
    `depends_on` in the module file to load the previous package in the chain
    of dependencies. This was done by adapting the `*_setup_quick.sh` scripts.

    This may be a nice upstream contribution.
