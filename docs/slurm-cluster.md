# Slurm cluster

All Information on the page are subject to change!

The cluster consists of three partitions:
* image1 with 11 compute nodes with 2x20 Intel-Cores each
* image2 with 1 compute nodes with 8x8 AMD cores each
* gpu with 12 nodes with the following gpu cards:


| Name            | Count  |
|--------------------------|
| titanrtx        |     32 |
| titanx (X/Xp/v) |     24 |
| testlak40       |      2 |
| testlak20       |      1 |
| gtx1080         |      4 |



Starting jobs outside the Slurm system is forbidden. The head-node must be kept available. Jobs that are not scheduled via slurm will get killed, either manually or automatically.


Table of Contents
=================

* [Getting access](#getting-access)
  * [Corona project users](#corona-project-users)
* [Support](#support)
* [Basic Access and First Time Setup](#basic-access-and-first-time-setup)
* [General Information](#general-information)
  * [ERDA](#erda)
  * [SIF](#sif)
  * [Files](#files)
  * [sshfs](#sshfs)
  * [ssh tunnelling and port forwarding](#ssh-tunnelling-and-port-forwarding)
  * [Using a more mordern compiler](#using-a-more-mordern-compiler)
  * [Old Home directories on GPU](#old-home-directories-on-gpu)
* [Using Slurm](#using-slurm)
  * [Examples for BatchScripts](#examples-for-batchscripts)
    * [Minimal Example](#minimal-example)
    * [Start an Array of Jobs using Matlab](#start-an-array-of-jobs-using-matlab)
    * [Start a Job on the GPU cluster](#start-a-job-on-the-gpu-cluster)


## Getting access
1. Request "SCI-DIKU-IMAGE-users" through identity.ku.dk
2.  * Employees should send a mail to cluster-access@di.ku.dk
    * Students should have their supervisor send a mail to cluster-access@di.ku.dk

### Corona project users
Some resources are reserved for Corona related projects. If you need access to these resources send an email to [oswin.krause@di.ku.dk](mailto:oswin.krause@di.ku.dk).

## Support
All support requests should be by mail to cluster-support@di.ku.dk


## Basic Access and First Time Setup
For accessing the cluster, you need access to ssh-diku-image.science.ku.dk.
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
    Host *-diku-image
        User <kuid>
        ProxyCommand ssh -q -W %h:%p gate-diku
    Host *-diku-nlp
        User <kuid>
        ProxyCommand ssh -q -W %h:%p gate-diku

This also sets up your access to the gpu-machines gpu01-diku-image to gpu11-diku-image as well as gpu01-diku-nlp to gpu02-diku-nlp.

With this in place, you can directly login at the cluster via

    ssh cluster

Or access the gpu-node gpu01-diku-image via

    ssh gpu01-diku-image

This will ask two times for your password.

After your first login, you have to setup a private key which allows password free login to any of the other nodes.
This is required for slurm to function properly! Simply execute the following. When asked for a password, leave blank:

    ssh-keygen
    ssh-copy-id cluster

On Windows 10 installations the configuration file should be placed in C:/Users/YOUR_WINDOWS_USER/.ssh/ and named config (without extension). If you encounter an error like

> ssh cluster
CreateProcessW failed error:2
posix_spawn: No such file or directory

you need to replace all three occasions of "ssh" in the ProxyCommand options with C:\Windows\System32\OpenSSH\ssh.exe , e.g.

ProxyCommand C:\Windows\System32\OpenSSH\ssh.exe -q -W %h:%p gate-diku


## General Information

### ERDA
Go to [https://erda.dk](https://erda.dk) for access to ERDA.

You can use sshfs to mount an ERDA directory. Once you have access to ERDA, create a new public/private key pair. Go to `Setup > SFTP` to add the public key to ERDA and put the private key in `~/.ssh` in your home dir on the cluster.

 Note that you need to mount ERDA directories on the machines that the job is submitted to. A simple approach is to make scripts that mounts/unmounts the ERDA directory and call it in the slurm batch script.

`mount_erda.sh`

    # file: mount_erda.sh
    #!/bin/bash
    key=<path-to-ssh-key>
    user=<kuid>
    erdadir=<erda-dir-to-mount>
    mnt=<mount-location>
    if [ -f "$key" ]
    then
        mkdir -p ${mnt}
        sshfs ${user}@io.erda.dk:${erdadir} ${mnt} -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -o IdentityFile=${key} 
    else
        echo "'${key}' is not an ssh key"
    fi

`unmount_erda.sh`

    # file: unmount_erda.sh
    #!/bin/bash
    fusermount -u <mount-point>

`your-slurm-script.sh`

    # file: <your-slurm-batch-script>
    #!/bin/bash
    # ...
    # ... Slurm parameters
    # ...
    ./mount_erda.sh
    <path-to-your-script>
    ./unmount_erda.sh

### SIF
[https://diku-dk.github.io/wiki/slurm-sif](https://diku-dk.github.io/wiki/slurm-sif)

### Files
Using the .ssh/config comes in handy if you want to copy your files via scp

    scp -r my_file1 my_file2 my_folder/ cluster:~/Dir

This will copy my_file1 my_file2 and my_folder/ into the path /home/<kuid>/Dir/. All files in your home directory are available to all compute nodes and the gpu machines. You can also copy back simply by

    scp -r cluster:~/Dir ./

### sshfs
Directories accessible from the cluster can be mounted locally on your workstation via sshfs. Assuming an appropriate ssh client configuration, mounting can be done with the following command:

    sshfs compute01-diku-image:the-folder-you-want-to-mount /path-to-local-mount-point

Remember to install sshfs and on macOS also osxfuse (on Yosemite this must be done via https://osxfuse.github.io/).

###ssh-tunnelling-and-port-forwarding
You can use ssh tunnelling / port forwarding to expose network services on remote servers directly on the local system.

For example,

    ssh -L 15000:cluster:22 gate-diku -N

establishes a tunnel forwarding connections to the local port 15000 (WARNING: in practice, use a unique, unoccupied port above 1023) to cluster:22 via gate-diku (as configued in the ssh client configuration recommended above). This allows copying files using scp from your local machine using

    scp -P 15000 file_to_copy localhost:directory_on_cluster_head/

If used in connection with key-based authentication, your KU password needs only to be entered once, namely when establishing the tunnel.

Port forwarding can simplify access to non-public svn/git repositories. For svn, this can be done by adding a new protocol to your svn configuration in ~/.subversion/config :

    [tunnels]
    ### 'svn+sshtunnel':
    sshtunnel = ssh -qp 15573

Again, remember to change the port number. After opening the ssh tunnel on this port with

    ssh -L 15573:repo_server:22 gate-diku -N

you can checkout the remote repository on repo_server using

    svn checkout svn+sshtunnel://localhost/svn/MyRepos/trunk .

Once you are done, you can close the tunnel using Ctrl-C.

### Using a more mordern compiler
Our operating system is RHEL 7, which by default comes with some old packages. For some packages it is possible to instead use a newer version, which is done via the scl command line tool. For example, to enable a modern set of development tools, including the compiler, run

    source scl_source enable devtoolset-7

This will change the default compiler in your current session to the newer gcc 7.3. If you also want this as a permanent change in your sessions, add this command to your .bash_profile.

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
