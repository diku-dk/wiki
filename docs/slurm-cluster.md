# Slurm cluster

All Information on the page are subject to change!

The cluster consists of three partitions:
* image1 with 11 compute nodes with 2x20 Intel-Cores each
* image2 with 1 compute nodes with 8x8 AMD cores each
* gpu with 14 nodes with the following gpu cards:


| Name            | Model                       | Count |
|-----------------|-----------------------------|-------|
| titanrtx        | Titan RTX + Quadro RTX 6000 |    48 |
| titanx          | Titan X/Xp/V                |    24 |
| testlak40       | Tesla K40                   |     2 |
| testlak20       | Tesla K20                   |     1 |
| gtx1080         | GTX 1080                    |     4 |



Starting jobs outside the Slurm system is forbidden. The head-node must be kept available. Jobs that are not scheduled via slurm will get killed, either manually or automatically.


Table of Contents
=================

* [Getting access](#getting-access)
  * [Corona project users](#corona-project-users)
  * [External guests](#external-guests)
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
  * [Scheduling many tasks](#scheduling-many-tasks)
  * [Determining memory requirements](#determining-memory-requirements)
* [Behind the Scenes](#behind-the-scenes)
  * [Scheduling](#scheduling)


## Getting access
1. Request "SCI-DIKU-IMAGE-users" through identity.ku.dk
2.  * Employees should send a mail to cluster-access@di.ku.dk
    * Students should have their supervisor send a mail to cluster-access@di.ku.dk
    * remember in both cases to include the KU-ID \<xxx000\>

### Corona project users
Some resources are reserved for Corona related projects. If you need access to these resources send an email to [oswin.krause@di.ku.dk](mailto:oswin.krause@di.ku.dk).

### External guests
Access to external guests is not available at the moment. KU-IT has identified the root cause and is waiting for the changes required to be implemented.

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
        ProxyJump gate-diku
    Host *-diku-image
        User <kuid>
        ProxyJump gate-diku
    Host *-diku-nlp
        User <kuid>
        ProxyJump gate-diku
    Host *.science.domain
        User <kuid>
        ProxyJump gate-diku

This also sets up your access to the gpu-machines gpu01-diku-image to gpu11-diku-image as well as gpu02-diku-nlp. Canonical hostnames like a00701.science.domain work as well.

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

### ssh-tunnelling-and-port-forwarding
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

This can also be used to run interactive jupyter notebooks. We can launch an interactive shell using

    [xyz123@a00552 ~]$ srun -p gpu --pty --time=00:30:00 --gres gpu:1 bash
    [xyz123@gpu02-diku-image ~]$ ss -tln sport 1234 # check if TCP port 1234 is occupied
    State      Recv-Q Send-Q Local Address:Port Peer Address:Port   Process
    LISTEN     0      128    127.0.0.1:1234     *:*
    [xyz123@gpu02-diku-image ~]$ ss -tln sport 15000 # TCP port 1234 was occupied, let's check port 15000
    State      Recv-Q Send-Q Local Address:Port Peer Address:Port   Process
    [xyz123@gpu02-diku-image ~]$ # Port is not occupied, we're good. Prepare your environment and launch the jupyter server
    [xyz123@gpu02-diku-image ~]$ . ~/my_tf_env/bin/activate # Activate virtual python environment
    (my_tf_env) [xyz123@gpu02-diku-image ~]$ jupyter-notebook --host=127.0.0.1 --port=15000 --no-browser
    [I 12:27:30.597 NotebookApp] Serving notebooks from local directory: /home/xyz123
    [I 12:27:30.597 NotebookApp] Jupyter Notebook 6.1.4 is running at:
    [I 12:27:30.597 NotebookApp] http://127.0.0.1:15000/?token=d305ab86adaf9c96bf4e44611c2253a1c7da6ec9e61557c4
    [I 12:27:30.597 NotebookApp]  or http://127.0.0.1:15000/?token=d305ab86adaf9c96bf4e44611c2253a1c7da6ec9e61557c4
    [I 12:27:30.597 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
    [C 12:27:30.614 NotebookApp]
    
        To access the notebook, open this file in a browser:
            file:///home/xyz123/.local/share/jupyter/runtime/nbserver-5918-open.html
        Or copy and paste one of these URLs:
            http://127.0.0.1:15000/?token=d305ab86adaf9c96bf4e44611c2253a1c7da6ec9e61557c4
         or http://127.0.0.1:15000/?token=d305ab86adaf9c96bf4e44611c2253a1c7da6ec9e61557c4

The jupyter server is now running. To connect to it using the browser on your local machine you need use local port forwarding and connect to the correct compute node (e.g. gpu02-diku-image in our example):

    localuser@localmachine> ssh -N -L 15000:127.0.0.1:15000 gpu02-diku-image
    xyz123@ssh-diku-image.science.ku.dk's password: 

While this connection persists in the background we can access the jupyter server using the URL from above:

    firefox 'http://127.0.0.1:15000/?token=d305ab86adaf9c96bf4e44611c2253a1c7da6ec9e61557c4'

Remember to shut down the jupyter server once you are done and exit your login session (before your job ends):

    ^C[I 12:44:19.823 NotebookApp] interrupted
    Serving notebooks from local directory: /home/xyz123
    1 active kernel
    Jupyter Notebook 6.1.4 is running at:
    http://localhost:15000/?token=f503e6e409ba5043d4ddbd49af63b33da29974f19fa643d7
     or http://127.0.0.1:15000/?token=f503e6e409ba5043d4ddbd49af63b33da29974f19fa643d7
    Shutdown this notebook server (y/[n])? y
    [C 12:44:24.824 NotebookApp] Shutdown confirmed
    [I 12:44:24.829 NotebookApp] Shutting down 1 kernel
    [I 12:44:25.231 NotebookApp] Kernel shutdown: 050c72b3-2eb9-4883-a357-0c0e0142808b
    [I 12:44:25.233 NotebookApp] Shutting down 0 terminals
    (my_tf_env) [xyz123@gpu02-diku-image ~]$ exit
    exit
    [xyz123@a00552 ~]$ 

A few words of caution:

1. Make sure to use a unique port (i.e. potentially not port 15000)
2. Make sure to connect to the right compute node (i.e. potentially not gpu02-diku-image)
3. This setup is considered experimental and might need some modifications to provide a stable experience

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

### Scheduling many tasks
Please take a look at [job arrays](https://slurm.schedmd.com/job_array.html).  Job arrays are preferred to multiple jobs when you have a lot of tasks with the same requirements. They are easier on the scheduler, which does not need to attempt to schedule all tasks at the same time, but only a small subset.  You can also use job arrays to limit the number of jobs run at the same time.  This allows other users to use our cluster without having to wait.

### Determining memory requirements
Before running multiple jobs with high memory requirements consider running just one to see how much memory you need. Useful commands are /usr/bin/time (run like /usr/bin/time -v python my_script.py --my_param 42)
it outputs multiple lines, including one which looks like this:

    Maximum resident set size (kbytes): 1892412

This suggests that you don't need more than 2 GB of memory for this job.  Alternatively you can check the accounting database once your job has terminated, which might be less reliable:

    [fwc817@a00552 ~]$ sacct -j <past_job_id> -o JobName,MaxRss,State,AllocCPUs
       JobName     MaxRSS      State  AllocCPUS
    ---------- ---------- ---------- ----------
    job_name_+             COMPLETED          2
         batch  18462780K  COMPLETED          2

This job shouldn't need more than 20 GB of RAM. Remember to add a suitable amount of RAM for shared memory (column SHR when using top). Using multiple processes makes this process even less straightforward and moves into the reign of educated guesswork.

Keeping these estimates low albeit realistic increases the utilisation of our hardware, which hopefully translates into lower waiting times.

## Behind the Scenes
### Scheduling
After submitting a job (via sbatch or srun) it enters the scheduling queue. If there are no other jobs waiting it will reside there until enough resources (i.e. a node which satisfies the requested resources, including GPUs, CPU core count, and memory) are available. Until then it will show up in the scheduling queue like this:

    [fwc817@a00552 ~]$ squeue
                 JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
               1894291       gpu     bash   fwc817 PD       0:00      1 (Resources)

If there are enough other jobs waiting to be scheduled those jobs' priorities become relevant:

    [fwc817@a00552 ~]$ sprio
              JOBID PARTITION   PRIORITY       SITE        AGE  FAIRSHARE    JOBSIZE  PARTITION
            1894294 gpu              314          0          0        284         20         10

The most important factors which increase a job's priority are
- Age: this favours jobs which have been waiting for resources over recently submitted ones
- Fairshare: this inversely correlates with your account's general usage of the slurm cluster
- Job size: larger jobs are favoured over smaller jobs so they are not blocked in the queue for too long. Don't try to abuse this as it is unfair to other users and we'd be forced to increase the weight of the Fairshare factor
- Niceness: you can decrease your job's priority by increasing its niceness (sbatch --nice=1000). Usually it's 100, which decreases a job's priority (as seen in the output of sprio) by 100.

In regular intervals all jobs' priorities are recomputed. Those with the highest priority are considered in order of decreasing priority for resources allocation. Jobs are then executed if resources for that job are available and if either

1. the job under consideration has the highest priority or
2. starting the job under consideration does not delay the expected start time (check squeue --start) of any job submitted before this job (backfill scheduling).
