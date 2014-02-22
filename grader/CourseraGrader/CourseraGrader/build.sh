#!/bin/sh

nvcc -arch=sm_20 -lrt -DWB_USE_JSON -DWB_USE_COURSERA -DWB_USE_CUSTOM_MALLOC -O0 -g -ljansson program.cu -o program -L $HOME/Dropbox/wbGPU/c-tools/Linux-x86-64 -I $HOME/Dropbox/wbGPU/c-tools $HOME/Dropbox/wbGPU/c-tools/Linux-x86-64/libwb.a -lcuda 2>&1

