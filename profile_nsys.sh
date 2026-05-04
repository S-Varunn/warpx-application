#!/bin/bash
# Profile with Nsight Systems (nsys)
# This will capture CUDA, MPI, OS Runtime, and NVTX events

echo "Starting Nsight Systems profiling..."

# Set output file base name
OUTPUT_FILE="warpx_nsys_profile_%q{OMPI_COMM_WORLD_RANK}"

# Run nsys with MPI
nsys profile \
    --trace=cuda,mpi,osrt,nvtx,cublas \
    --sample=cpu \
    --cpuctxsw=true \
    --stats=true \
    --output="${OUTPUT_FILE}" \
    --force-overwrite=true \
    mpiexec -n 4 python3 run_lwfa.py

echo "Nsight Systems profiling complete. Output files: warpx_nsys_profile_*.nsys-rep"
