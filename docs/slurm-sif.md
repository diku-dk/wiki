Accessing SIF from Slurm
=======================================================================

This guide will walk you through the necessary steps to access SIF from Slurm.

Step 1: preliminaries.
-------------------------------------------------------------------------
1. Get a SIF account and create a project.
2. login to slurm and copy the contents of your `~/.ssh/id_rsa.pub` into the SIF web interface, at 
    ```
    https://sif.erda.dk/wsgi-bin/setup.py ->sftp->Authorized Public Keys
    ```
3. on slurm, `mkdir ~/sif`
4. when accessing SIF via ssh, you need the correct username, which is usermail@projectname.
   You can check your name at
   ```
   https://sif.erda.dk/wsgi-bin/setup.py -> sftp -> Show more SFTP client details... -> check the "User" lines
   ```
5. Paste the following into your `~/.ssh/config`, replacing usermail@projectname by the configuration obtained above
   ```
   Host sif-io.erda.dk
      Hostname sif-io.erda.dk
      VerifyHostKeyDNS yes
      User usermail@projectname
      Port 22
      IdentityFile ~/.ssh/id_rsa
   ```
   
Note:  If you need to mount multiple projects, change in the config above the "HOST"-part to something unique
and replace the path below by whatever you choose. you can only have access to a *single* project via SIF at any given time by choosing
the *active project* at the SIF webinterface. This is a limitation of SIF.

Step 2: Using Slurm
------------------------------------------------------------------------
We have to create a 2FA session on the node we want to do computations on, otherwise sshfs will only produce errors. 
This means that our “fire & forget” scheme of slurm usage does not work and we have to create an interactive session.

1. Make the desired proejct active on SIF.
2. Create a screen session. This will allow you to leave the head-node without interrupting your interactive slurm session
3. Inside the screen, we use srun to obtain an interactive session
    ```
    srun --pty --all-normal-slurm-options-including-gpu-requirements bash -i
    ```
    This will wait until you get a node-allocation by Slurm.

4. Next, we create the 2FA session inside our interactive session. It is valid for 24h which means that if your sshfs breaks
   after the ticket timed out, it won’t be able to reconnect (but should be fine otherwise). For this, we use lynx as a webbrowser:
   ```
   lynx -accept_all_cookies https://sif.erda.dk/wsgi-bin/twofactor.py?redirect_url=/wsgi-bin/twofactor.py
   ```
   Type in ku username, password, navigate to submit and enter. Type in your authentication token via your mobile. hit submit. repeat.
   You are done once the page says that your token is accepted (minimum 2 tries). quit lynx with q y
5. Finally, issue your mount:
   ```
   sshfs sif-io.erda.dk: ~/sif -o idmap=user -o big_writes -o reconnect
   ```
   Congratulations, you should have mounted your project under ~/sif. Now run your script and wait until it is finished
6. After your script finishes, unmount: 
   ```
   fusermount -u ~/sif
   ```
