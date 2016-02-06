#!/bin/bash
set -e
PYTHON_VERSIONS="2.6 2.7 3.3 3.4 3.5"
PANDAS_VERSIONS="0.10.0 0.10.1 0.11.0 0.12.0 0.13.0 0.13.1 \
    0.14.0 0.14.1 0.15.0 0.15.1 0.15.2 \
    0.16.0 0.16.1 0.16.2 \
    0.17.0 0.17.1"
MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

function lex_ver {
    # Echoes dot-separated version string padded with zeros
    # Thus:
    # 3.2.1 -> 003002001
    # 3     -> 003000000
    echo $1 | awk -F "." '{printf "%03d%03d%03d", $1, $2, $3}'
}

# Directory to store wheels
mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP=/opt/${PYTHON}/bin/pip
    for PANDAS in ${PANDAS_VERSIONS}; do
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] ; then
            np_ver=1.9.0
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ||
            [ $(lex_ver $PANDAS) -ge $(lex_ver 0.15) ] ; then
            np_ver=1.7.0
        else
            np_ver=1.6.1
        fi
        echo "Building pandas $PANDAS for Python $PYTHON"
        # Put numpy version into the wheelhouse to avoid rebuilding
        $PIP wheel -f $MANYLINUX_URL -w tmp "numpy==$np_ver"
        $PIP install -f tmp "numpy==$np_ver"
        # Add numpy to requirements to avoid upgrading numpy version
        $PIP wheel -f tmp -w unfixed_wheels "numpy==$np_ver" "pandas==$PANDAS"
    done
done

# Bundle external shared libraries into the wheels
for whl in unfixed_wheels/*.whl; do
    auditwheel repair $whl -w /io/wheelhouse/
done
