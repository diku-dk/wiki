#!/bin/bash
echo "export CUDA_DEVICE_ORDER=PCI_BUS_ID"

(
scontrol -o show job "$SLURM_JOB_ID" |sed -e 's/\(UserId\|Account\|WorkDir\|JobName\|Command\)=[^ ]*//g'
env |grep -e ^CUDA -e ^SLURM |grep -ve SLURM_JOB_USER= -e SLURM_SUBMIT_DIR= -e SLURM_JOB_ACCOUNT= -e SLURM_JOB_NAME= |paste -sd' '
) 2>/dev/null |logger -t srunprolog -S 3072 >/dev/null 2>&1
