# Scheduling and Resource Allocation

## About
This document describes how the cluster currently handles ressource allocations and how jobs are scheduled. 

1. [Resource Allocation](#resource-allocation)
2. [Billing Factor](#billing-factor)
3. [Scheduling Priority](#scheduling-priority)

## Resource Allocation and Cgroups
The cluster schedules three resources: CPU threads, Memory and GPUs. The requested resources are guarded via cgroups: a job can allocate only as many
resources as requested and can not access any other resources.

CPU threads are not cores: 
each core offers two hyperthreads, which share the compute power of the core. When allocating jobs,
SLURM is configured to never allocate two different jobs on the same CPU core and when requesting more than one CPU,
slurm will by default try to minimize the allocated number of cores, i.e., when allocating 20 CPUs, you will receive 10 cores.
Finally, to optimize runtime, slurm will try to allocate as many cores on the same physical CPU Socket as possible: this way communication between cores
is fast and sharing the same L3 cache is possible.

Memory allocation is strict:

If a job requests 10G of memory, allocating more than that will lead to an out-of-memory error and the job is killed. 

GPU handling:

Currently, the cluster holds the following GPU types (note that different cards are bunched together, e.g.,
different A100 cards are all referenced as A100), which can be requested using the `--gres` switch of SBATCH:

|Type|Count|Gres    |
|----|-----|--------|
|A40 |10   |gpu:a40 |
|A100|14   |gpu:a100|

Requesting two A100 is done via `--gres=gpu:a100:2`. The NVIDIA driver will make sure that only allocated GPUs are visible to a job. Calling `nvidia-smi`
will only return allocated GPUs. GPU numbers will still be consecutive starting from zero, with the fastest GPU getting assigned id 0. From a user perspective,
a system with 8 gpus with 2 GPUs allocated to a job should not look different from a system that only has 2 GPUs.

### Job Resource Defaults

By default, allocating a GPU will automatically allocate 8 CPU threads and each CPU thread will by default allocate 4000MB of memory. 
This means, allocating a GPU leads to 8 theads and 32000MB being allocated as well. These numbers can all be changed via sbatch command options.
However, at maximum 8000MB memory are allocated to a single core to prevent memory-starving CPUs. This means that allocating more Memory will automatically allocate more 
CPUs to your job, which will affect the scheduling cost (see Billing Factor below).


## Billing factor
The billing factor is how the cluster weighs the computational costs of your jobs. The billing factor and its sibling the billed seconds are central
to how ressource limits and scheduling priority are computed. The billing factor is the weighted sum of all requested resources $R$, multiplied with cost factor $\alpha$
$$F_\text{billing} = \sum_{j}\alpha_j \text{R}_j$$

The billing factor is primarily used in computing the billing seconds, which is just the billing factor times the runtime in seconds:

$$M_\text{billing}=F_\text{billing}\cdot T_\text{job}$$

The runtime $T_\text{job}$ is the actual wallclock time a job is run, not the time that was allocated for it.

The current weight factors are:

|   |CPU|GPU|A100|
|---|---|---|---|
|$\alpha$|0.625|5|10|

Just requesting an arbitrary GPU incures a billing factor of 5. This GPU might be an A100, but also one of our smaller cards. If an A100 is explicitely requested,
this incurs an additional cost on your job and the resulting cost of an a100 is 15. You can query the billing factor of a job with 

    sacct -X --format=AllocTRES%60,Elapsed -j $jobid
    

### Examples
Using the default values, requesting an arbirary GPU using `--gres=gpu:1` also allocates 8 CPUs to your job, which incurs a billing factor of:

$$F_\text{billing} = 0.625\cdot8+5=10$$

The output of `sacct` for a job with jobid 59 with `--gres=gpu:1` produces

    $ sacct -X --format=AllocTRES%60,Elapsed -j 59
                                                   AllocTRES    Elapsed
       ----------------------------------------------------- ----------
                billing=10,cpu=8,gres/gpu=1,mem=32000M,node=1   00:01:16
                
Changing the request resources to `--gres=gpu:a100:1` results in:

$$F_\text{billing} = 0.625\cdot8+5+10=20$$

with the output of sacct being:

    $ sacct -X --format=AllocTRES%60,Elapsed -j 60
                                                       AllocTRES    Elapsed
           ----------------------------------------------------- ----------
    billing=20,cpu=8,gres/gpu:a100=1,gres/gpu=1,mem=32000M,node=1   00:01:25

allocating moe than twice the default memory (`--mem=128G`) will increase the number of cpu cores and thus the billing factor:

    $ sacct -X --format=AllocTRES%60,Elapsed -j 79
                                                       AllocTRES    Elapsed
           ----------------------------------------------------- ----------
    billing=25,cpu=16,gres/gpu:a100=1,gres/gpu=1,mem=128G,node=1   00:01:05

## Scheduling Priority
Scheduling priority is computed as a sum of two values

1. Job waiting factor
2. Fairshare factor

The job waiting factor is a simple linear factor of the time a job waited in queue divided by the maximum age time (one week) with a maximum of one.

The fairshare factor is computed based on an exponential moving average of the consumed billing seconds. The half life time is 7 days and it is updated every 5 minutes.
While the fairshare computation algorithm is pretty involved, in our simple configuration it amounts to a ranking of users based on their exponential moving average.
Your current Fairshare priority can be queried by

    $ sshare -U -u$user -o RawUsage,NormUsage,NormShares,FairShare
       RawUsage   NormUsage  NormShares  FairShare
    ----------- ----------- ----------- ----------
            317    1.000000    0.333333   0.333333

The four values are:
1. RawUsage: the current moving average of billing seconds
2. NormUsage: the fraction of billing seconds compared to the overall use of the cluster
3. NormShares: the users target share of the overall available computation time
4. FairShare: a weight assigned based on the rank of the user in terms of NormUsage. Higher usage give lower FairShare. Maximum is 1.

