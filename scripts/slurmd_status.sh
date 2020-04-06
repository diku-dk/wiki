#!/bin/bash
names=${1}
for name in `cat ${names}`
do 
    echo ${name}
    ssh -t ${name} "systemctl status slurmd"
done    
