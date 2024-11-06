Running Jupyter Notebooks on a compute node
=======================================================================
While we generally dont allow running jupyter notebooks on the login nodes, it is possible to run them directly on a compute node and accessing it from your own computer.

For this example we are going to use a predefined job and start it with `sbatch`but the same parameters would work for an interactive session using `srun`

Create `jupyter.job` in your home directory

    #!/bin/bash
    #SBATCH --gres-gpu:1
    #SBATCH --nodes 1
    #SBATCH --cpus-per-task 1
    #SBATCH --time 01:00:00
    #SBATCH --job-name jupyter-notebook-test
    #SBATCH -o /home/xtv244/scratch/jupyter_log/jupyter-notebook-%J.log
    #SBATCH -e /home/xtv244/scratch/jupyter_log/jupyter-notebook-%J.log

    # get tunneling info
    module load jupyter-notebook

    port=12345
    node=$(hostname -s)
    user=$(whoami)

    # run jupyter notebook
    # If you have a custom environment, active it first here
    jupyter-notebook --no-browser --port=${port} --ip=${node}

Make sure to choose a unique port and not the default (8888) or 12345! 

Run `squeue -u <your-userid>` to find the name of the compute node that your notebook is running on. In this case `hendrixgpu05fl`
```
[xtv244@hendrixgate03fl ~]$ squeue -u xtv244
JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
7587       gpu jupyter-   xtv244  R      15:30      1 hendrixgpu05fl
```

The jupyter server is now running. To connect to it using the browser on your local machine you need use local port forwarding and connect to the correct compute node (e.g. `hendrixgpu05fl` with port `12345` in our example):

    localuser@localmachine> ssh -N -L <port>:<node>:<port> <userid>@hendrix
    xyz123@hendrix's password:

While this connection persists in the background we can access the jupyter server using `localhost` and the the port we selected

    firefox 'http://127.0.0.1:12345'

Remember to shut down the jupyter server! Simply press "quit" in the Jupyter Notebook dashboard

A few words of caution:
1. Make sure to choose a short amount of time! Interactive sessions are meant for testing only! If you forget to quit the notebook, you risk blocking the node for other users!
2. Make sure to use a unique port (i.e. potentially not port 12345)
3. Make sure to connect to the right compute node (i.e. potentially not hendrixgpu05fl)
4. This setup is considered experimental and might need some modifications to provide a stable experience
5. Technically anyone with access to the cluster can now access your notebook. Consider password protecting it by:
```
    [xyz123@hendrixgate01fl ~]$ module load jupyter-notebook
    [xtv244@hendrixgate03fl ~]$ jupyter notebook --generate-config
    [xtv244@hendrixgate03fl ~]$ jupyter notebook password
```
The command will prompt you to enter a password and will automatically write it to your configuration file.