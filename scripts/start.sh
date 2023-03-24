#!/bin/bash

module load openmpi cuda

export JULIA_CUDA_MEMORY_POOL=none
export IGG_CUDAAWARE_MPI=1
echo ready