# LMMs-Eval Reproduction Environment

This directory contains reproduction scripts and environment setup for running LMMs-Eval experiments.

## Container Environment

The reproduction environment is based on:
```
From: rocm/vllm:rocm6.4.1_vllm_0.10.1_20250909
```
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


## Usage

The reproduction environment includes automated scripts to run experiments. All the setup procedures above are handled automatically by the `run.sh` script.

### Running Experiments

To run experiments using SLURM job scheduler:

```bash
sbatch run.sh
```

To run experiments directly (without SLURM):

```bash
bash run.sh
```

### What the script does

The `run.sh` script automatically:
1. Sets up the container environment
2. Installs all required dependencies
3. Configures environment variables
4. Runs the specified models on the specified datasets

## How to Add Models and Datasets

### Adding Models

To add new models that work with vLLM, edit the model definition section in `run.sh` (starting around line 28):

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

Supported model types:
- vLLM-compatible models

### Adding Datasets

To add new datasets, edit the dataset configuration section in `run.sh` (starting around line 39):

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

This is especially useful for:
- Verifying model and dataset compatibility
- Testing configuration changes
- Debugging issues before running full experiments
- Quick validation of new setups


This reproduction environment is designed to work with the main LMMs-Eval framework. Please refer to the main [LMMs-Eval documentation](../README.md) for detailed usage instructions.


## Related Projects

- [LMMs-Eval Main Repository](../README.md) - The main evaluation framework
- [AmalgamationAI](../../AmalgamationAI/README.md) - Self-improving ML framework