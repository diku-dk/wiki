#!/bin/bash
# install.slurm.gpu.sh
# Install slurm and dependencies on DIKU GPU cluster machines
machine="${1}"
mungekey=<path-to-munge.key>
confdir=<path-to-slurm-conf-dir>
rpmdir=<path-to-dir-containing-slurm-rpms>
version=19.05.2-1.el7 # Slurm version to install

# 0. Check we have a gres.conf for this machine
if [ ! -f "${confdir}/${machine}-gres.conf" ] ; then
    echo "Missing gres.conf for machine ${machine}"
    exit 8
fi


# 1. Add groups and users
if !( groupadd --system --gid 989 slurm && \
    useradd --system --uid 992 --gid 989 slurm && \
    groupadd --system --gid 990 munge && \
    useradd --system --uid 993 --gid 990 munge ); then
    echo "Failed to add groups and users"
    exit 1
fi


# 2. Install munge
if !( yum install munge munge-libs munge-devel readline-devel openssl-devel perl-ExtUtils-MakeMaker pam-devel ); then
    echo "Failed to install munge and dependencies"
    exit 2
fi

## Copy munge.key and chown
if !( cp ${mungekey} /etc/munge/munge.key && \
    chown munge:munge /etc/munge/munge.key ); then
    echo "Failed to copy munge.key"
    exit 2
fi


# 3. Start and enable munge
if !( systemctl start munge && systemctl enable munge ); then
    echo "Failed to start and enable munge"
    exit 3
fi


# 4. Install slurm
if !( rpm --install ${rpmdir}/slurm-${version}.x86_64.rpm ${rpmdir}/slurm-slurmd-${version}.x86_64.rpm ); then
    echo "Failed to install slurm"
    exit 4
fi


# 5. Create and chown slurm directories
if !( mkdir -p /etc/slurm /var/spool/slurmd /var/log/slurm && \
    chown slurm:slurm /var/spool/slurmd /var/log/slurm ); then
    echo "Failed to create and chown slurm directoies"
    exit 5
fi


# 6. Copy slurm config
if !( cp ${confdir}/{slurm.conf,cgroup.conf} /etc/slurm ); then
    echo "Failed to copy slurm config"
    exit 6
fi


# 7. copy gres.conf
if !( cp "${confdir}/${machine}-gres.conf" /etc/slurm/gres.conf ); then
    echo "Failed to copy gres config"
    exit 7
fi


# 8. Start and enable slurmd
if !( systemctl start slurmd && systemctl enable slurmd ); then
    echo "Failed to start and enable slurmd"
    exit 8
fi


# 9. Check we are running fine
systemctl status slurmd
tail -n4 /var/log/slurm/slurmd.log
