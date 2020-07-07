#!/bin/sh

logger -t slurmctld_log -f <(
scontrol show job "$SLURM_JOB_ID" |paste -sd' ' |sed 's/  */ /g'
env |grep -e ^CUDA -e ^SLURM |paste -sd' '
)
