# Slurm admin

Table of Contents
=================
* [Issues](#issues)
* [Granting access](#granting-access)
* [Rebooting Crashed Nodes](#rebooting-crashed-nodes)
* [Maintenance](#maintenance)
* [Setup](#setup)

## Issues
All cluster issues should be tracked through the github issue tracker https://github.com/diku-dk/wiki/issues


## Granting access
1. Approve request through identity.ku.dk. Check that a mail was sent to `cluster-access@di.ku.dk`
2. Add user to mail list `cluster-users@di.ku.dk`
3. Add user to cluster db with the following script

    #filename: add_user.sh
    #!/bin/bash
    user=${1}
    echo ${user}
    sacctmgr add account ${user} Description="none" Organization="diku" Cluster=cluster Parent=users
    sacctmgr add user ${user} Account=${user} DefaultAccount=${user}

    $ sudo ./add_user.sh <ku-id>

You then say yes to the two prompts. NOTE: This needs to be changed when students have separate resources.


## Rebooting Crashed Nodes
After a crashed node got rebooted, Slurm will not trust it anymore, querying state will look like:

    $ sudo scontrol show node a00562
    NodeName=a00562 Arch=x86_64 CoresPerSocket=10
       ...
       State=DOWN 
       ...
       Reason=Node unexpectedly rebooted

If we are sure that there is no hardware fault, we can simply tell Slurm to Resume operations with this node:

    sudo scontrol update NodeName=a00562 State=RESUME


##  Maintenance
When a maintenance window is scheduled we want to drain the nodes, i.e. only jobs are allowed to run which will terminate before the maintenance starts.
This can be done using:

    sudo scontrol create reservation starttime=2017-10-12T16:00:00 duration=600 user=root flags=maint,ignore_jobs nodes=ALL

here we initialize a maintenance window for 600minutes starting from the 12th october 20117, 4pm. When the maintenance window arrives we can sutdown the server using

    sudo scontrol shutdown

When the machines get rebooted, the slurm daemons will also come up automatically.


## Setup

How to build (strg+f rpm) https://slurm.schedmd.com/quickstart_admin.html 
Use the rpmbuild option!
Install mariadb-devel so we can build slurmdbd with database accounting
On a compute node we need
slurm, slurmd

On head node we need
slurm, slurmctld, slurmd

Same gid/uid is not required for munge. TODO: Check if needed for slurm.

1. Create munge and slurm users
```
groupadd --system --gid 989 slurm
useradd --system --uid 992 --gid 989 slurm
groupadd --system --gid 990 munge
useradd --system --uid 993 --gid 990 munge
```

2. Install munge
```
yum install munge munge-libs munge-devel
yum install readline-devel openssl-devel perl-ExtUtils-MakeMaker pam-devel
```
copy /etc/munge/munge.key from head node
munge must own /etc/munge/munge.key /var/lib/munge /var/log/munge
Check that munge.key are identical
Check uid/gid match with head node

3. Start and enable munged daemon via systemctl 
```
systemctl start munge
systemctl enable munge
```

4. Install slurm
Packages for version 17.11.5-1 are currently located in /home/pcn178/rpmbuild/RPMS/x86_64
```
rpm --install slurm-17.11.5-1.el7.x86_64.rpm slurm-slurmd-17.11.5-1.el7.x86_64.rpm
```

5. Create and chown slurm directories
```
mkdir /etc/slurm /var/spool/slurmd /var/log/slurm
chown slurm:slurm /var/spool/slurmd /var/log/slurm
```
Check if more is needed for JobCheckpointDir if we want that

6. Copy and update slurm config from head node
 - /etc/slurm/slurm.conf
Add node to list at the bottom of config and add node to partition. Updated slurm.conf should be distributed to all other nodes

 - /etc/slurm/cgroup.conf
No change is necesary

7. If machine is gpu add
/etc/slurm/gres.conf (Adapt to each gpu machine)
```
# Example config. Update Type and File to match the machine
# Configure support for our four GPUs
Name=gpu Type=titanxp File=/dev/nvidia[0-2]
Name=gpu Type=titanx File=/dev/nvidia3
```

8. start and enable slurmd daemon via systemctl 
```
systemctl start slurmd
systemctl enable slurmd
```

9. Check that new node is reachable and working
```
#!/bin/bash
# Test script for gpu nodes. Add lines for new nodes
srun -p gpu --gres=gpu:titanxp:3 --exclusive show_device.sh &
srun -p gpu --gres=gpu:titanx:1  --exclusive show_device.sh &
srun -p gpu --gres=gpu:teslak20:1 --exclusive show_device.sh &
wait
```
```
#!/bin/bash
# show_device.sh
echo ${CUDA_VISIBLE_DEVICES}
```
