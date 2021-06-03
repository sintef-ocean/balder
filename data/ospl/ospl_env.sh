#!/bin/bash

my_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
my_base="$(readlink -f "${my_dir}/../usr")"

if [ -z ${OSPL_URI+x} ]; then
    export OSPL_URI="file://${my_base}/share/ospl.xml"
else
    echo "OSPL_URI already set: ${OSPL_URI}"
fi

export OSPL_HOME="${my_base}/lib"

# How to properly set fonts.conf
#export FONTCONFIG_PATH=${my_base}/share/fonts
export FONTCONFIG_PATH=/etc/fonts
