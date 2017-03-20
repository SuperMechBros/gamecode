#!/usr/bin/env bash
cd ${0%[\\/]*}
set -eu

declare base=qcsrc

: ${PROGS_OUT:=$PWD}
export PROGS_OUT

: ${QCC:=$PWD/gmqcc/gmqcc}
export QCC

export QCCFLAGS_WATERMARK=Super Mechanical Brothers Alpha

relpath() {
    b=; s=$(cd $(readlink -f ${1%%/}); pwd); d=$(cd $2; pwd)
    while [ "${d#$s/}" == "${d}" ]; do s=$(dirname ${s}); b="../${b}"; done
    echo ${b}${d#${s}/}
}

export XONOTIC=1
make -C ${base}
