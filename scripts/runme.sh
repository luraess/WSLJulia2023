#!/bin/bash

source start.sh

nprocs=$1

julia8="/soft/julia/julia-1.8.5/bin/julia"

mpirun -np $nprocs --bind-to socket $julia8 --project -O3 tiny_diff3D_mpi.jl