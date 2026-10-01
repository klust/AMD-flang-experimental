#! /bin/bash

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
cd $(dirname $0)

gtar -cf templates.tar template
gzip -9 templates.tar
mv templates.tar.gz ../downloads/templates.therock.tgz
