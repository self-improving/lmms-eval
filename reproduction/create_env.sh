#!/bin/bash

#SBATCH --job-name=create-lmme-eval-env
#SBATCH --partition=m3-192 #partition
#SBATCH --mem=500G #2321978M #2.3TB memory
#SBATCH --cpus-per-task=32 # Number of CPU cores to allocate per task
#SBATCH --time=1:00:00 # 1 hour
#SBATCH --output=log/output-%A_%a.log # path of output log files
#SBATCH --error=log/error-%A_%a.log # path of error log files


set -euo pipefail

source /etc/profile.d/modules.sh
module load singularity

# Environment
venv_name=venv/lmms-vllm-experiments
group=/lustre/share/self_improving/self_improving
# singularity image
sif_path=/lustre/share/self_improving/self_improving/singularity/rocm_amd_image_vllm-taro.sif

lmms_eval_repo_dir=~/repo/lmms-eval

singularity exec \
  -B "$HOME" \
  -B "$group":/group_path \
  --pwd "$lmms_eval_repo_dir" \
  --env USER="$USER" \
  --env HYDRA_FULL_ERROR=1 \
  --env LOG_LEVEL=INFO \
  "$sif_path" \
  /bin/bash << EOT
    # clone shared environment and create venv (skip if already exists)
    if [ ! -d "shared-environment" ]; then
        echo "Cloning shared-environment repository..."
        git clone --branch v0.1.69 https://github.com/self-improving/shared-environment.git
    else
        echo "shared-environment repository already exists, skipping clone"
    fi
    
    if [ ! -d "$venv_name" ]; then
        echo "Creating virtual environment..."
        source shared-environment/amd/create_venv_from_lockfile.sh $venv_name shared-environment/amd/locks/base_amd.txt
        # Install additional dependencies
        echo "Installing additional dependencies..."
        uv pip install loguru evaluate sqlitedict tenacity decord pytablewriter latex2sympy2
    else
        echo "Virtual environment $venv_name already exists, skipping creation"
    fi
EOT
date