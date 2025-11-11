#!/bin/bash

#SBATCH --job-name=lmms-vllm-experiments # job name
#SBATCH --array=1-36
#SBATCH --partition=m3-1536 #partition
#SBATCH --mem=500G 
#SBATCH --cpus-per-task=32 
#SBATCH --gres=gpu:2 
#SBATCH --time=1-00:00:00 # 1 days
#SBATCH --output=log/output-%A_%a.log # path of output log files
#SBATCH --error=log/error-%A_%a.log # path of error log files


set -euo pipefail

# Check if HF_TOKEN is set
if [[ -z "${HF_TOKEN:-}" ]]; then
  echo "Error: HF_TOKEN environment variable is not set." >&2
  echo "Please set it before running: export HF_TOKEN=your_huggingface_token_here" >&2
  exit 1
fi

source /etc/profile.d/modules.sh
module load singularity

# Environment
venv_name=venv/lmms-vllm-experiments
group=/lustre/share/self_improving/self_improving
# singularity image
sif_path=/lustre/share/self_improving/self_improving/singularity/rocm_amd_image_vllm-taro.sif

lmms_eval_repo_dir=~/repo/lmms-eval

# Define associative arrays
# models
declare -A models
models[1]=/group_path/models/gemma3/gemma-3-4b-it
models[2]=/group_path/models/gemma3/gemma-3-12b-it
models[3]=/group_path/models/gemma3/gemma-3-27b-it
models[4]=/group_path/models/Qwen/Qwen2.5-VL-7B-Instruct
models[5]=/group_path/models/Qwen/Qwen2.5-VL-32B-Instruct
models[6]=/group_path/models/Qwen/Qwen2.5-VL-72B-Instruct

# datasets
# infovqa_val,docvqa_val,mathvision_test,mmmu_pro,scienceqa_full,muirbench
declare -A datasets
datasets[1]=infovqa_val
datasets[2]=docvqa_val
datasets[3]=mathvision_test
datasets[4]=mmmu_pro
datasets[5]=scienceqa_full
datasets[6]=muirbench

# Calculate indices based on SLURM_ARRAY_TASK_ID
model_index=$(( (SLURM_ARRAY_TASK_ID - 1) / 6 + 1 ))
dataset_index=$(( ((SLURM_ARRAY_TASK_ID - 1) % 6) + 1 ))

# Get the values from the arrays
model="${models[$model_index]}"
dataset="${datasets[$dataset_index]}"

# Check if values are empty (for safety)
if [[ -z "$model" || -z "$dataset" ]]; then
  echo "Error: Invalid index. SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID" >&2
  exit 1
fi

echo "rocm-smi"
rocm-smi

# Print the configuration for this task
echo "SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"
echo "model_index: $model_index"
echo "dataset_index: $dataset_index"
echo "model: $model"
echo "dataset: $dataset"
pwd

singularity exec \
  -B "$HOME" \
  -B "$group":/group_path \
  --pwd "$lmms_eval_repo_dir" \
  --env USER="$USER" \
  --env HYDRA_FULL_ERROR=1 \
  --env LOG_LEVEL=INFO \
  --env HF_TOKEN="$HF_TOKEN" \
  "$sif_path" \
  /bin/bash << EOT
    source "$venv_name/bin/activate"
    # setup environment variables
    export CUDA_VISIBLE_DEVICES="$ROCR_VISIBLE_DEVICES"
    unset ROCR_VISIBLE_DEVICES

    # run experiments
    "reproduction/vllm_experiments.sh" "$model" "$dataset"
EOT
date