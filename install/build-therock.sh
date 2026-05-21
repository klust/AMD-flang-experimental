#!/bin/bash

### unpack the therock drop
export therock_dest_dir="${BASE_PREFIX}/therock/${version_name}"

# Only untar if not already extracted
if [ ! -d "${therock_dest_dir}/lib" ]; then
  mkdir -p ${therock_dest_dir}
  tar -xf $CACHE_DIR/$THEROCK -C ${therock_dest_dir} --strip-components=1
  cd ${therock_dest_dir}/lib && ln -sf /usr/lib64/libjson-c.so.5 ./libjson-c.so
fi


### set up therock modules and frankenstein the environment
mkdir -p ${TMPDIR}/tmp.therock && cd ${TMPDIR}/tmp.therock
cd ${TMPDIR}/tmp.therock
tar -xf ${CACHE_DIR}/templates.therock.tgz
if [[ $? -ne 0 ]]; then
        echo "Error: Failed to extract 'templates.therock.tgz'."
        exit 1
fi
cd ${TMPDIR}/tmp.therock/template/lmod/modulefiles/core
if [[ ! -f  therock.lua ]]; then
        echo "Error: therock.lua does not exist."
        exit 1
fi
sed -i "s%__THEROCK_DEST_DIR__%${therock_dest_dir}%g" therock.lua
sed -i "s%__THEROCK_VERSION__%${version_name}%g" therock.lua
sed -i "s%__THEROCK__%${THEROCK}%g" therock.lua
sed -i "s%__ROCM_BASE_MODULE__%${ROCM_BASE_MODULE}%g" therock.lua

mv therock.lua therock-${version_name}.lua
mkdir -p ${BASE_PREFIX}/modulefiles/${release_name}/therock
cp therock-${version_name}.lua ${BASE_PREFIX}/modulefiles/${release_name}/therock/${version_name}.lua
