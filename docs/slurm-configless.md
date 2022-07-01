# Slurm Configless configuration

## About
This document describes the basic configuration of the cluster. We use SLURMs configless mode of operation where the head-node distributes all config files
to the compute nodes. This means that setting up a node does only require installation of the packages (likely via KU-IT) and then only the head-node configuration
files need to be updated.


Related reading materials are:

https://slurm.schedmd.com/configless_slurm.html

## Setup

Currently, configless is used to copy the contents of `slurm.conf` and `gres.conf` to all compute nodes. On the head node,
they are still located in the directory `/etc/slurm`, while the compute nodes might not even have an `/etc/slurm directory`

### Contacting the Head Node
When a compute node boots up it normally first checks whether it can find a local configuration file. If that is not the case, it enters configless node in which
it tries to find and contact the shead server and obtian all config files. For this, there are two options supported by slurm: either, a config option is provided when slurm starts up,
or a DNS SRV entry can be queried. The DNS SRV entry must be configured by KU-IT and reads:

    _slurmctld._tcp 3600 IN SRV 0 0 6817 hendrixhead01fl.science.domain

where the last two entries describe the SLURM headnode port and the address of the headnode. If this entry is not set,
the option must be provided manually. Since we use systemd to control slurmd, we need to add the config options to `/etc/sysconfig/slurmd`

    SLURMD_OPTIONS=--conf-server hendrixhead01fl.science.domain:6817
    
Here `SLURMD_OPTIONS` is the envronment variable that systemd uses to provide additional options to slurmd and `--conf-server`
is the option that we set to the value of host address and port. We currently use this option but we will change this as soon as the DNS SRV entry is set.


## GRES.conf

to write a gres.conf that is usable for all servers, one has to add the respective NodeName to the config file to indicate which line belongs to which node.
An example for this is

    NodeName=hendrixgpu01fl Name=gpu Type=a100 File=/dev/nvidia[0-7]
    NodeName=hendrixgpu02fl Name=gpu Type=a100 File=/dev/nvidia[0-1]

The first line indicates that the Node hendrixgpu01fl has a single gpu gres type consisting of eight 
a100 cards which belong to the file path /dev/nvidia0 to /dev/nvidia7. When reading the gres.conf, the node hendrixgpu01fl will ignore all lines that are not
especially targeting it (or targeting all nodes).
