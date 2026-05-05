# Profiling Commands Reference

This document serves as a cheat sheet for all the terminal commands required to reproduce the profiling benchmarks, manage the environment, and securely copy trace files from the remote VM to the local host machine.

## 1. Environment Setup (Run in VM)

Before running any profiling scripts, you must activate the Python virtual environment and load the Spack-built HPCToolkit into your shell.

```bash
# Navigate to the workspace
cd ~/warpx-application

# 1. Activate the Python virtual environment (needed for pywarpx and torch)
source .venv/bin/activate

# 2. Initialize Spack
source ~/spack/share/spack/setup-env.sh

# 3. Load the specific HPCToolkit build (with +cuda +python support)
spack load /pgyzjqo
```

## 2. Running the Benchmark Suite (Run in VM)

Once the environment is set up, you can execute the master orchestration script. This script automatically runs Baseline, PyTorch Profiler, Nsight Systems, HPCToolkit, and PInsight.

```bash
# Run the benchmark script
./benchmark_profilers.sh
```
*Note: The script will automatically log its stdout/stderr to `benchmark_profilers_run.log` so you don't lose the metrics in your terminal buffer.*

## 3. Downloading Traces to Local Host (Run on Local Machine)

To analyze the generated traces in GUI tools (Nsight Systems, Eclipse Trace Compass), you must download the files from the remote VM to your local host machine. **Run these commands in your local machine's terminal.**

```bash
# Navigate to your local workspace
cd /home/varun/work-directory/master-thesis/warpx-application

# 1. Download the benchmark metrics log and Nsight Systems traces (.nsys-rep)
scp "vsureshk@cci-aries:/home/vsureshk/warpx-application/benchmark_profilers_run.log" "vsureshk@cci-aries:/home/vsureshk/warpx-application/warpx_nsys_profile_*.nsys-rep" ./

# 2. Download the PInsight (LTTng) trace folders
scp -r "vsureshk@cci-aries:/home/vsureshk/lttng-traces/warpx-trace-session-benchmark-*" ./
```

## 4. Cleaning Up Old Traces (Run on Local Machine or VM)

If you are running the benchmark multiple times, you should delete the old traces so they don't get mixed up. 

**Local Cleanup (To clear space before a fresh SCP):**
```bash
rm -rf warpx_nsys_profile_*.nsys-rep warpx_nsys_profile_*.sqlite warpx-trace-session-benchmark-* hpctoolkit-python3-* benchmark_profilers_run.log
```

**VM Cleanup (To free up disk space on the remote server):**
```bash
rm -rf ~/warpx-application/warpx_nsys_profile_* ~/warpx-application/hpctoolkit-python3-* ~/lttng-traces/warpx-trace-session-benchmark-*
```
