# Slurm cluster

All Information on the page are subject to change! Especially hostnames are going to be replaced by nice alias names.

The cluster consists of three partitions:
* image1 with 11 compute nodes with 2x20 Intel-Cores each
* image2 with 1 compute nodes with 8x8 AMD cores each
* gpu hosting various servers with the following gpu cards:


| Name | Count |
|--------------|
| titanx | 11 |
| titanxp | 4 |
| testlak20 | 1 |
| testlak40 | 1 |
| gtx1080 | 1 |



Starting jobs outside the Slurm system is forbidden. The head-node must be kept available. Jobs that are not scheduled via slurm will get killed, either manually or automatically.


Table of Contents
=================

* [Slurm cluster](#slurm-cluster)
  * [Basic Access and First Time Setup](#basic-access-and-first-time-setup)
  * [General Information](#general-information)
    * [Files](#files)
    * [Old Home directories on GPU](#old-home-directories-on-gpu)
  * [Using Slurm](#using-slurm)
    * [Examples for BatchScripts](#examples-for-batchscripts)
      * [Minimal Example](#minimal-example)
      * [Start an Array of Jobs using Matlab](#start-an-array-of-jobs-using-matlab)
      * [Start a Job on the GPU cluster](#start-a-job-on-the-gpu-cluster)
    * [Administrative Commands](#administrative-commands)
      * [Rebooting Crashed Nodes](#rebooting-crashed-nodes)
      * [Maintenance](#maintenance)


## Basic Access and First Time Setup
For accessing the cluster, you need access to ssh-diku-image.science.ku.dk. Ask one of the Admins to grant you access.
The way to access the cluster is with <kuid> being your ku-username:

    ssh <kuid>@ssh-diku-image.science.ku.dk
    ssh a00552

The simplest way is to add an entry in .ssh/config

    Host gate-diku
        HostName ssh-diku-image.science.ku.dk
        User <kuid>
    Host cluster
        HostName a00552
        User <kuid>
        ProxyCommand ssh -q -W %h:%p gate-diku
    Host gpu*-diku-image
        User <kuid>
        ProxyCommand ssh -q -W %h:%p gate-diku

This also sets up your access to the gpu-machines gpu01-diku-image to gpu07-diku-image

With this in place, you can directly login at the cluster via

    ssh cluster

Or access the gpu-node gpu01-diku-image via

    ssh gpu01-diku-image

This will ask two times for your password.

After your first login, you have to setup a private key which allows password free login to any of the other nodes.
This is required for slurm to function properly! Simply execute the following. When asked for a password, leave blank:

    ssh-keygen
    ssh-copy-id a00553

## General Information

### ERDA
You can use sshfs to mount an ERDA directory. Note that you need to mount it on the machines that the job is submitted to. A simple approach is to make a script that mounts/unmounts the ERDA directory and call it in the slurm batch script. You can use an ssh key to login to ERDA.

    # file: mount_erda.sh
    #!/bin/bash
    sshfs -o IdentityFile=<path-to-ssh-key> <user>@io.erda.dk:<directory> <mount-point>

    # file: unmount_erda.sh
    #!/bin/bash
    fusermount -u <mount-point>

    # file: <your-slurm-batch-script>
    #!/bin/bash	
    # ...
    # ... Slurm parameters
    # ...
    ./mount_erda.sh
    <path-to-your-script>
    ./unmount_erda.sh


### Files

Using the .ssh/config comes in handy if you want to copy your files via scp

    scp -r my_file1 my_file2 my_folder/ cluster:~/Dir

This will copy my_file1 my_file2 and my_folder/ into the path /home/<kuid>/Dir/. All files in your home directory are available to all compute nodes and the gpu machines. You can also copy back simply by

    scp -r cluster:~/Dir ./

### Old Home directories on GPU
If you have an older user account, you might miss some of your data. This data is located at

    /science/home/<kuid>

You can not ls or use auto-completion in /science/home/, but cd or using direct file-paths work fine. 
WARNING: YOU CAN NOT USE THIS DIRECTORY FOR LONG RUNNING JOBS! COPY THE DATA YOU NEED TO YOUR HOME DIRECTORY!

## Using Slurm
Slurm is a Batch processing manager which allows you to submit tasks and request a specific amount of resources which have to be reserved for the job. Resources are for example Memory, number of processing cores, GPUs or even a number of machines. Moreover, Slurm allows you to start arrays of jobs easily, for example to Benchmark an algorithm with different parameter settings. When a job is submitted, it is enqueued to the waiting queue and will stay there until the required resources are available. Slurm is therefore perfectly suited for executing long-running tasks.

To see how many jobs are queued type

    squeue

To submit a job use

    sbatch sbatchScript.sh

Where the sbatchscript.sh file is a normal bash or sh script that also contains information about
the ressources to allocate. Jobs are run on the node in the same path as the path you were when you submitted the job.
This means that storing files relative to your current path will work flawlessly.

### Examples for BatchScripts

#### Minimal Example
A quite minimal script looks like:

    #!/bin/bash
    #SBATCH --job-name=MyJob
    #number of independent tasks we are going to start in this script
    #SBATCH --ntasks=1
    #number of cpus we want to allocate for each program
    #SBATCH --cpus-per-task=4
    #We expect that our program should not run longer than 2 days
    #Note that a program will be killed once it exceeds this time! 
    #SBATCH --time=2-00:00:00
    #Skipping many options! see man sbatch
    # From here on, we can start our program
    
    ./my_program option1 option2 option3
    ./some_post_processing

#### Start an Array of Jobs using Matlab
This is a another small script to start an array of several independent jobs using Matlab. The script assumes that in the current folder there
is a function called "myMatlabScript" which is taking the task number as a single argument. Internally the function will then assign the chosen hyper parameters based on 
the task number, e.g. by using it as an index in an array and then run the experiment.
Please take care that every task number saves the results in different files, otherwise the processes will overwrite each other.
In the script the number of cores is restricted to 4 for each task in the array, so the total script takes 28 cpres

    #!/bin/bash
    #SBATCH --job-name=ArrayMatlab
    # we start 7 tasks numbered 1-7
    #SBATCH --array 1-7
    #number of cpus we want to allocate for each task
    #SBATCH --cpus-per-task=4
    # max run time is 24 hours
    #SBATCH --time= 24:00:00
    # start matlab
    matlab -minimize -nosplash -nodesktop -r "myMatlabScript(${SLURM_ARRAY_TASK_ID})"

#### Start a Job on the GPU cluster
Asking for gpu resources requires running on the partition gpu and indicating which and how many gpus you need. the format is either --gres=gpu:number, e.g. --gres=gpu:2 or a specific gpu type like
--gres=gpu:titanx:2. An example script could look like

    #!/bin/bash
    # normal cpu stuff: allocate cpus, memory
    #SBATCH --ntasks=1 --cpus-per-task=10 --mem=6000M
    # we run on the gpu partition and we allocate 2 titanx gpus
    #SBATCH -p gpu --gres=gpu:titanx:2
    #We expect that our program should not run longer than 4 hours
    #Note that a program will be killed once it exceeds this time!
    #SBATCH --time=4:00:00
    
    #your script, in this case: write the hostname and the ids of the chosen gpus.
    hostname
    echo $CUDA_VISIBLE_DEVICES
    python3 yourScript.py

### Administrative Commands
Note: This section is for administrative purposes, once it becomes too big we will move it into another entry

#### Rebooting Crashed Nodes
After a crashed node got rebooted, Slurm will not trust it anymore, querying state will look like:

    $ sudo scontrol show node a00562
    NodeName=a00562 Arch=x86_64 CoresPerSocket=10
       ...
       State=DOWN 
       ...
       Reason=Node unexpectedly rebooted

If we are sure that there is no hardware fault, we can simply tell Slurm to Resume operations with this node:

    sudo scontrol update NodeName=a00562 State=RESUME

####  Maintenance
When a maintenance window is scheduled we want to drain the nodes, i.e. only jobs are allowed to run which will terminate before the maintenance starts.
This can be done using:

    sudo scontrol create reservation starttime=2017-10-12T16:00:00 duration=600 user=root flags=maint,ignore_jobs nodes=ALL

here we initialize a maintenance window for 600minutes starting from the 12th october 20117, 4pm. When the maintenance window arrives we can sutdown the server using

    sudo scontrol shutdown

When the machines get rebooted, the slurm daemons will also come up automatically.