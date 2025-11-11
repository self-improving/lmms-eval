export NCCL_BLOCKING_WAIT=1
export NCCL_TIMEOUT=18000000
export NCCL_DEBUG=DEBUG

python3 -m lmms_eval \
    --model vllm \
    --model_args model=$1,tensor_parallel_size=2 \
    --tasks $2 \
    --batch_size 64 \
    --log_samples \
    --log_samples_suffix vllm \
    --output_path /group_path/experiments/output/$USER/lmms-eval/logs/vllm_experiments