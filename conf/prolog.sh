#!/bin/bash
echo "export CUDA_DEVICE_ORDER=PCI_BUS_ID"

(
scontrol -o show job "$SLURM_JOB_ID"
env |grep -e ^CUDA -e ^SLURM |paste -sd' '
) 2>/dev/null |logger -t srunprolog -S 3072 >/dev/null 2>&1
