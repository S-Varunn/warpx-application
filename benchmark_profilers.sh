#!/bin/bash
# Script to benchmark the overhead and performance of various profilers
# This helps in comparing PInsight with Nsight Systems, HPCToolkit, and PyTorch Profiler

echo "=========================================================="
echo "    PROFILER OVERHEAD & RESOURCE BENCHMARKING SCRIPT      "
echo "=========================================================="
echo "This script calculates execution time, peak memory usage, "
echo "and trace file sizes to compare profiler overhead."
echo "=========================================================="

# Ensure output files from previous runs are removed
rm -f warpx_nsys_profile_*.nsys-rep warpx_pytorch_trace.json
rm -rf hpctoolkit-python3-measurements-* hpctoolkit-python3-database

# Export PYTHONPATH to include the CMake-built WarpX bindings
export PYTHONPATH="$(pwd)/warpx_directory/WarpX/build/python_out:$PYTHONPATH"

# Function to run and measure a command
time_command() {
    local profiler_name=$1
    shift
    
    echo ""
    echo "----------------------------------------------------------"
    echo "▶ Running: $profiler_name"
    echo "----------------------------------------------------------"
    
    # We use /usr/bin/time to get wall clock time and peak memory
    # Format string outputs: Wall clock time in seconds, Max Resident Set Size in KB
    # Output to a temporary file so we can parse it
    if ! /usr/bin/time -f "%e|%M" -o time_out.tmp "$@"; then
        echo "  [!] Command failed to execute properly."
        rm -f time_out.tmp
        if [ "$profiler_name" == "Baseline (No Profiler)" ]; then
            BASELINE_TIME=0
        fi
        return 1
    fi
    
    # Read the output
    IFS='|' read -r wall_time peak_memory < time_out.tmp
    rm -f time_out.tmp
    
    # Validate parsed time
    if ! [[ $wall_time =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "  [!] Failed to parse timing output."
        if [ "$profiler_name" == "Baseline (No Profiler)" ]; then
            BASELINE_TIME=0
        fi
        return 1
    fi
    
    # Print metrics
    echo "✔ Completed: $profiler_name"
    echo "  - Wall Clock Time : $wall_time seconds"
    echo "  - Peak Memory (RSS): $peak_memory KB"
    
    # Save times for later overhead calculation
    if [ "$profiler_name" == "Baseline (No Profiler)" ]; then
        BASELINE_TIME=$wall_time
    else
        # Calculate overhead percentage: (Profiler Time - Baseline Time) / Baseline Time * 100
        if [ "$BASELINE_TIME" != "0" ] && [ -n "$BASELINE_TIME" ]; then
            OVERHEAD=$(awk -v t1="$wall_time" -v t2="$BASELINE_TIME" 'BEGIN { printf "%.2f", ((t1 - t2) / t2) * 100 }')
            echo "  - Time Overhead    : $OVERHEAD %"
        else
            echo "  - Time Overhead    : N/A (Baseline failed)"
        fi
    fi
}

# 1. Baseline
time_command "Baseline (No Profiler)" mpiexec -n 4 python3 run_lwfa.py

# 2. PyTorch Profiler
time_command "PyTorch Profiler" mpiexec -n 4 python3 run_lwfa_pytorch_profiler.py
# Check trace size
if [ -f warpx_pytorch_trace.json ]; then
    SIZE=$(du -sh warpx_pytorch_trace.json | cut -f1)
    echo "  - Trace File Size  : $SIZE (warpx_pytorch_trace.json)"
else
    echo "  - Trace File Size  : N/A (Failed to generate trace)"
fi

# 3. Nsight Systems (Maximized)
time_command "Nsight Systems (nsys)" ./profile_nsys.sh
if ls warpx_nsys_profile_*.nsys-rep 1> /dev/null 2>&1; then
    SIZE=$(du -ch warpx_nsys_profile_*.nsys-rep | grep total | cut -f1)
    echo "  - Trace File Size  : $SIZE (Total across all ranks)"
else
    echo "  - Trace File Size  : N/A (Failed to generate trace)"
fi

# 4. HPC-Toolkit (Maximized)
time_command "HPC-Toolkit" ./profile_hpctoolkit.sh
MEASUREMENT_DIR=$(ls -d hpctoolkit-python3-measurements-* 2>/dev/null | tail -n 1)
if [ ! -z "$MEASUREMENT_DIR" ]; then
    SIZE=$(du -sh $MEASUREMENT_DIR | cut -f1)
    echo "  - Trace File Size  : $SIZE (Measurement Directory)"
else
    echo "  - Trace File Size  : N/A (Failed to generate measurements)"
fi

echo ""
echo "=========================================================="
echo " Benchmarking complete. Use these metrics (Time Overhead, "
echo " Peak Memory, and Trace File Size) to compare against PInsight."
echo "=========================================================="
