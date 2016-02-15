#!/bin/bash
# Build a miscellaneous collection of wheels
# These wheels do not depend on numpy or any external library.
# Wheels to build listed in "misc_requirements.txt"
#
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manlinux1_x86_64 /io/build_misc.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manlinux1_x86_64 /io/build_misc.sh
set -e
if [ -z $PYTHON_VERSIONS ]; then
    PYTHON_VERSIONS="2.6 2.7 3.3 3.4 3.5"
fi

MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux

# Add manylinux repo
mkdir ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
find-links = $MANYLINUX_URL
EOF

# Directory to store wheels
mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP=/opt/$PYTHON/bin/pip
    # To satisfy packages depending on numpy distuils in setup.py
    $PIP install numpy
    echo "Building for $PYTHON"
    while read req_line; do
        echo "Building $req_line"
        echo $req_line > requirements.txt
        $PIP wheel -w ../unfixed_wheels -r requirements.txt
    done < /io/misc_requirements.txt
done

# Bundle external shared libraries into the wheels
for whl in unfixed_wheels/*.whl; do
    auditwheel repair $whl -w /io/wheelhouse/
done
