#!/bin/bash
# upgrade_slurm.sh
# Upgrade slurm on DIKU head node
rpmdir=<path-to-dir-containing-slurm-rpms>
version=19.05.2-1.el7


# 1. Install new slurm packages
#    We want slurm and slurmd
if !( rpm --upgrade ${rpmdir}/slurm-${version}.x86_64.rpm \
                    ${rpmdir}/slurm-slurmd-${version}.x86_64.rpm \
                    ${rpmdir}/slurm-slurmctld-${version}.x86_64.rpm ); then
    echo "Failed to upgrade slurm"
    exit 1
fi

# 2. Start and enable slurmd
if !( systemctl start slurmctld && systemctl enable slurmctld ); then
    echo "Failed to start and enable slurmd"
    exit 2
fi

#3. Check we are running fine
systemctl status slurmctld
tail -n4 /var/log/slurm/slurmctld.log
