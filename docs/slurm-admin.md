  # Slurm admin

Table of Contents
=================
* [Issues](#issues)
* [Granting access](#granting-access)
* [Rebooting Crashed Nodes](#rebooting-crashed-nodes)
* [Maintenance](#maintenance)
* [Setup](#setup)
* [Upgrade](#upgrade)
* [Usage stats](#usage-stats)
  - [Calculate median wait time](#calculate-median-wait-time)

## Issues
All cluster issues should be tracked through the github issue tracker https://github.com/diku-dk/wiki/issues


## Granting access
1. Approve request through identity.ku.dk. Check that a mail was sent to `cluster-access@di.ku.dk`
2. Add user to mail list `cluster-users@di.ku.dk`
3. Add user to cluster db

You can use this script

    # filename: add_user.sh
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

There are scripts for installing and upgrading slurm in the github repo.

### Install slurm on gpu node

1. Create <server-name>-gres.conf file
2. Set paths in `install_slurm.gpu.sh`
3. `./install.slurm.gpu.sh <server-name>`

this have changed TODO get fixed so it is updated


## Install slurm on cpu node
TODO: make necesary adjustments to `install.slurm.gpu.sh` (maybe just get rid of gres part)


## Upgrade
Read the release notes carefully. Ensure that slurmdbd format is compatible.
Build the new slurm packages. There are upgrade scripts in the githun repo.


### Upgrade slurm on comnpute node

1. Set paths in `upgrade_slurm.gpu.sh`
2. `./upgrade_slurm.sh`


### Upgrade slurm on head node

1. Set paths in `upgrade_slurm.gpu.sh`
2. `./upgrade_slurm.sh`

## Usage stats
Use `sreport` and `sacct`.

### Calculate median wait time
Use `sacct` to get stats for 2020

    sudo sacct --starttime=2020-01-01 --format=submit,start --parsable2 > slurm/usage_stats/2020-01-01_2020-09-03_submit-start.csv

Use R to aggregate

    path <- 'slurm/usage_stats/2020-01-01_2020-09-03_submit-start.csv'
    x <- read.csv(, sep='|')
    x$Submit <- strptime(x$Submit, format="%Y-%m-%dT%H:%M:%S")
    x$Start <- strptime(x$Start, format="%Y-%m-%dT%H:%M:%S")
    x <- x[x$Submit$year == 120,] # For some reason we get stuff that is both submitted and started in 2019-12
    x$Wait <- x$Start - x$Submit
    x$SubmitMonth <- x$Submit$mon
    res <- aggregate(list(WaitTimeInSeconds=x$Wait), by=list(SubmitMonth=x$SubmitMonth), FUN=function(x) { quantile(x, probs=seq(0,1,0.1), na.rm=TRUE) } )
    print(data.frame(SubmitMonth=res$SubmitMonth, MedianWaitInSeconds=res$WaitTimeInSeconds[,6]))
    write.csv(res, file='2020_wait-time_by-month.csv', quote=F, row.names=F)
