#!/bin/bash

set -euo pipefail

# Submit the environment creation job and capture the job ID
echo "Submitting environment creation job..."
ENV_JOB_ID=$(sbatch create_env.sh | awk '{print $4}')
echo "Environment creation job ID: $ENV_JOB_ID"

# Submit the main job with dependency on the environment creation job
echo "Submitting main experiments job (depends on job $ENV_JOB_ID)..."
sbatch --dependency=afterok:$ENV_JOB_ID submit_experiments.sh

echo "Jobs submitted successfully!"
echo "Environment creation job ID: $ENV_JOB_ID"
echo "Main experiments job will start after environment creation completes."