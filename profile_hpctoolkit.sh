#!/bin/bash
# Profile with HPC-Toolkit
# This script measures the application performance using hpcrun

echo "Starting HPC-Toolkit profiling..."

# Automatically load Spack and HPCToolkit if available
if [ -f "$HOME/spack/share/spack/setup-env.sh" ]; then
    source "$HOME/spack/share/spack/setup-env.sh"
    # Load the latest installed version (which should be the one with +cuda +python)
    spack load hpctoolkit
fi

# Set environment variables for HPC-Toolkit (if needed)
export HPCRUN_EVENT_LIST="REALTIME@1000 WALLCLOCK@1000 CPUTIME@1000 gpu=nvidia"

# Step 1: Measure
# We profile the MPI execution using hpcrun
echo "Running hpcrun..."
hpcrun -e REALTIME@1000 -e WALLCLOCK@1000 -e CPUTIME@1000 -e gpu=nvidia mpiexec -n 4 python3 run_lwfa.py

# Step 2: Analyze
# Assuming hpctoolkit measurement directory is generated as hpctoolkit-python3-measurements
MEASUREMENT_DIR=$(ls -d hpctoolkit-python3-measurements-* 2>/dev/null | tail -n 1)

if [ ! -z "$MEASUREMENT_DIR" ]; then
    echo "Measurement directory found: $MEASUREMENT_DIR"
    echo "Running hpcstruct to analyze the executable..."
    # hpcstruct analyzes the application binary. For python scripts, it analyzes the python interpreter.
    hpcstruct $(which python3)
    
    echo "Running hpcprof to generate the database..."
    hpcprof -S python3.hpcstruct -I . $MEASUREMENT_DIR
    
    echo "HPC-Toolkit profiling complete. Use hpcviewer to visualize the database."
else
    echo "HPC-Toolkit measurement directory not found. Please check hpcrun output."
fi
