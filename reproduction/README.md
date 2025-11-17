# LMMs-Eval Reproduction Environment

This directory contains reproduction scripts and environment setup for running LMMs-Eval experiments.

## Version of lmms-eval

This reproduction environment used **lmms-eval v0.5**, which is _not_ the version of main forked here.

- **Release**: [v0.5](https://github.com/EvolvingLMMs-Lab/lmms-eval/releases/tag/v0.5)
- **Code Repository**: [EvolvingLMMs-Lab/lmms-eval (v0.5 branch)](https://github.com/EvolvingLMMs-Lab/lmms-eval/tree/v0.5)

To use this specific version, clone the repository and checkout the v0.5 tag:

```bash
git clone https://github.com/EvolvingLMMs-Lab/lmms-eval.git
cd lmms-eval
git checkout v0.5
```

## Container Environment

The reproduction environment uses a Singularity container based on the ROCm vLLM image:

**Base Image**: `rocm/vllm:rocm6.4.1_vllm_0.10.1_20250909`

To build the Singularity image, use the definition file from the shared-environment repository:

**Definition File**: [shared_env.def](https://github.com/self-improving/shared-environment/blob/cf66dfefe1471bbcd1723c3450d29c55e8932d1a/amd/shared_env.def)

**Build Command**:
```bash
singularity build your_image.sif shared_env.def
```

**Note**: The pre-built image path used in the experiments is specified in `create_env.sh` and `submit_experiments.sh` (default: `/lustre/share/self_improving/self_improving/singularity/rocm_amd_image_vllm-taro.sif`). This default image is available on the **Ashitaka** cluster. If you're running on a different system or have built your own image, make sure to update the path in `create_env.sh` and `submit_experiments.sh`.

## Shared Environment

This reproduction environment uses the shared environment from the AmalgamationAI project:

- **Repository**: [self-improving/shared-environment](https://github.com/self-improving/shared-environment)
- **Version**: [v0.1.69](https://github.com/self-improving/shared-environment/releases/tag/v0.1.69)
- **Commit Hash**: `1e16cf3cf29b624dffd6cd93f51507a90ee6b25e`

This shared environment provides consistent dependencies and configurations across different AmalgamationAI experiments.

## Required Dependencies

Install the following packages using `uv`:

```bash
uv pip install loguru evaluate sqlitedict tenacity decord pytablewriter latex2sympy2
```

## Environment Variables

Make sure to set the following environment variables before running experiments:

**Get your Hugging Face token**: Go to [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) and create a new token.

**Set it inline when running commands**:
```bash
HF_TOKEN=your_huggingface_token_here bash run.sh
```

## Usage

The reproduction environment includes automated scripts to orchestrate the entire experiment workflow. The main `run.sh` script coordinates environment setup and experiment execution.

### Running Experiments

To run the complete experiment pipeline, you need to provide your Hugging Face token. The token is required to access Hugging Face model repositories and datasets.

**Prerequisites**: Navigate to the `reproduction` directory first:
```bash
cd reproduction
```

**Option 1: Set token inline (recommended for one-time runs)**
```bash
HF_TOKEN=your_huggingface_token_here bash run.sh
```

**Option 2: Export token first (recommended for multiple runs)**
```bash
export HF_TOKEN=your_huggingface_token_here
bash run.sh
```

**Note**: If `HF_TOKEN` is not set, the script will exit with an error message. Make sure you have created a token at [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) before running.

The script will:
1. Submit a SLURM job to create the environment (if not already created)
2. Submit experiment jobs that depend on the environment creation job
3. Run all model-dataset combinations as defined in `submit_experiments.sh`

Check job status with:
```bash
squeue -u $USER
```

### What the script does

The `run.sh` script orchestrates a two-stage process:

1. **Environment Creation** (`create_env.sh`):
   - Sets up the container environment
   - Clones the shared-environment repository (if not exists)
   - Creates virtual environment (if not exists)
   - Installs all required dependencies

2. **Experiment Execution** (`submit_experiments.sh`):
   - Waits for environment creation to complete successfully
   - Activates the virtual environment
   - Configures environment variables
   - Runs the specified models on the specified datasets

### Job Dependencies

The script uses SLURM job dependencies to ensure proper execution order:
- Environment creation job runs first
- Experiment jobs only start after environment setup completes successfully
- If environment creation fails, experiments won't run (prevents wasted compute)

## How to Add Models and Datasets

### Adding Models

To add new models that work with vLLM, edit the model definition section in `submit_experiments.sh` (starting around line 28):

```bash
# models
declare -A models
models[1]=/group_path/models/gemma3/gemma-3-4b-it
models[2]=/group_path/models/gemma3/gemma-3-12b-it
models[3]=/group_path/models/gemma3/gemma-3-27b-it
models[4]=/group_path/models/Qwen/Qwen2.5-VL-7B-Instruct
models[5]=/group_path/models/Qwen/Qwen2.5-VL-32B-Instruct
models[6]=/group_path/models/Qwen/Qwen2.5-VL-72B-Instruct

# To add a new model, simply add another line:
# models[7]=/path/to/your/new/model
```

You need to change number of job array and indices.

Supported model types:
- vLLM-compatible models

### Adding Datasets

To add new datasets, edit the dataset configuration section in `submit_experiments.sh` (starting around line 39):

```bash
declare -A datasets
datasets[1]=infovqa_val
datasets[2]=docvqa_val
datasets[3]=mathvision_test
datasets[4]=mmmu_pro
datasets[5]=scienceqa_full
datasets[6]=muirbench

# To add a new dataset, simply add another line:
# datasets[7]=your_new_dataset_name
```

You need to change number of job array and indices.

Supported dataset types:
- Vision-Language datasets (VQA, image captioning, etc.)
- Text datasets (reasoning, math, etc.)
- Video datasets (video understanding, etc.)
- Audio datasets (speech recognition, etc.)

**Important**: The dataset name must match the YAML configuration file name in `lmms-eval/tasks/`. For example:
- `infovqa_val` corresponds to `lmms-eval/tasks/infovqa/infovqa_val.yaml`
- `scienceqa_full` corresponds to `lmms-eval/tasks/scienceqa/scienceqa_full.yaml`

To find available datasets, check the `lmms-eval/tasks/` directory for YAML files.

### Configuration Tips

- Ensure model and dataset paths are accessible from the container
- Check that the model format is compatible with vLLM
- Verify dataset format matches LMMs-Eval requirements
- Test with a small subset before running full experiments

### Testing with Small Subsets

Before running full experiments, you can test with a small subset of data to verify your configuration:

```bash
# Edit the last line of vllm_experiments.sh to add --limit flag
# Example: --limit 10 (runs only 10 samples)
python -m lmms_eval --model vllm --model_args model=your_model --tasks your_dataset --limit 10
```

**Note**: The `vllm_experiments.sh` script is called from within `submit_experiments.sh`, so you can also modify the experiment parameters directly in that file.

This is especially useful for:
- Verifying model and dataset compatibility
- Testing configuration changes
- Debugging issues before running full experiments
- Quick validation of new setups


This reproduction environment is designed to work with the main LMMs-Eval framework. Please refer to the main [LMMs-Eval documentation](../README.md) for detailed usage instructions.


## Related Projects

- [LMMs-Eval Main Repository](../README.md) - The main evaluation framework
- [AmalgamationAI](../../AmalgamationAI/README.md) - Self-improving ML framework
