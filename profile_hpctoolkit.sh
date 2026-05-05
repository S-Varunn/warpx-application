#!/bin/bash
# Profile with HPC-Toolkit
# This script measures the application performance using hpcrun

echo "Starting HPC-Toolkit profiling..."

# Automatically load Spack and HPCToolkit if available
if [ -f "$HOME/spack/share/spack/setup-env.sh" ]; then
    source "$HOME/spack/share/spack/setup-env.sh"
    # Load the specific +cuda +python version by its hash to resolve ambiguity
    spack load /pgyzjqo
fi

# Set environment variables for HPC-Toolkit (if needed)
export HPCRUN_EVENT_LIST="REALTIME@1000 gpu=cuda"

# Ensure Python can find WarpX when running this script standalone
export PYTHONPATH="$(pwd)/warpx_directory/WarpX/build/python_out:$PYTHONPATH"

# Step 1: Measure
# We profile the MPI execution using hpcrun
echo "Running hpcrun..."
hpcrun -o hpctoolkit-measurements -e REALTIME@1000 -e gpu=cuda mpiexec -n 4 .venv/bin/python3 run_lwfa.py

# Step 2: Analyze
# The measurement directory is now explicitly named 'hpctoolkit-measurements'
MEASUREMENT_DIR="hpctoolkit-measurements"

if [ ! -z "$MEASUREMENT_DIR" ]; then
    echo "Measurement directory found: $MEASUREMENT_DIR"
    echo "Running hpcstruct to analyze the executable..."
    # hpcstruct analyzes the application binary. For python scripts, it analyzes the python interpreter.
    hpcstruct $(which python3)
    
    echo "Running hpcprof to generate the database..."
    hpcprof -S python3.hpcstruct $MEASUREMENT_DIR
    
    echo "HPC-Toolkit profiling complete. Use hpcviewer to visualize the database."
else
    echo "HPC-Toolkit measurement directory not found. Please check hpcrun output."
fi
