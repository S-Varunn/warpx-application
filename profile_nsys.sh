#!/bin/bash
# Profile with Nsight Systems (nsys)
# This will capture CUDA, MPI, OS Runtime, and NVTX events

echo "Starting Nsight Systems profiling..."

# Set output file base name to include Process ID
OUTPUT_FILE="warpx_nsys_profile_%p"

# Run mpiexec which spawns nsys on each rank
mpiexec -n 4 nsys profile \
    --trace=cuda,mpi,osrt,nvtx,cublas \
    --sample=cpu \
    --cpuctxsw=process-tree \
    --stats=true \
    --output="${OUTPUT_FILE}" \
    --force-overwrite=true \
    .venv/bin/python3 run_lwfa.py

echo "Nsight Systems profiling complete. Output files: warpx_nsys_profile_*.nsys-rep"
