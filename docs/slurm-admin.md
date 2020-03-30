# Slurm admin

Table of Contents
=================
* [Issues](#issues)
* [Granting access](#granting-access)
* [Rebooting Crashed Nodes](#rebooting-crashed-nodes)
* [Maintenance](#maintenance)

## Issues
All cluster issues should be tracked through the github issue tracker https://github.com/diku-dk/wiki/issues


## Granting access
1. Approve request through identity.ku.dk. Check that a mail was sent to `cluster-access@di.ku.dk`
2. Add user to mail list `cluster-users@di.ku.dk`
3. Add user to cluster db with the following script

    # filename: add_user.sh
    #!/bin/bash
    user=${1}
    echo ${user}
    sacctmgr add account ${user} Description="none" Organization="diku" Cluster=cluster Parent=users
    sacctmgr add user ${user} Account=${user} DefaultAccount=${user}

    sudo ./add_user.sh <ku-id>

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
