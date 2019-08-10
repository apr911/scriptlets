###############################################################################
# Title:        Batch Command Runner
# Version:      1.0
#
# File:         batch-command-runner.sh
# Author:       Tony Romero
# Email:        tony.romero@apr911.net
# Date Created: 20170920
#
# Purpose: Bulk run commands with potential dependency conflicts
# Usage: 
# batch-command-runner.sh <File Containing Line Separated Commands to Run>
# 
#
# Addtional Required Source Files: None
# Additional Reference Files: BatchExample.txt
# 
###############################################################################

#!/bin/bash

# Initialize Variables
ExecErr=0
StartIndex=0
minCmds=1
rateLimit=0.2 #Number of seconds to wait between commands.
declare -a cmdList 

# Get Commandlist File from Parameters
file=${1--}
#readarray cmdList < <(cat -- "$file")

# Read in Commandlist File
while read -r LINE;
do
    cmdList+=("$LINE")
done < <(cat -- "$file")
    
cmdTotal=${#cmdList[@]}

#Check Number of Commands to be run is greater than minCmds.
if [[ $cmdTotal -le $minCmds ]] ; then
    echo -e "\r\nReceived $minCmds Command or Less as Input.\r\nThis Tool is NOT intended for use with individual configuration items.\r\nIt should ONLY be used for Mass Configuration.\r\n"
    echo -e "Please Check Inputs and/or Manually Run Requested Command."
    exit -1
fi

#Correct for Array Indexing
let cmdIndex=$cmdTotal-1

#Loop through array
for cmdNum in $(seq $StartIndex $cmdIndex)
do
    # Print Command being run
    echo "${cmdList[$cmdNum]}"
    # Run command, if it fails, record which command in the array failed as ExecErr
    ${cmdList[$cmdNum]} || let ExecErr=$cmdNum+1

    #If ExecErr is set, then command failed. Dependent commands will fail so break loop.
    if [[ $ExecErr -ne 0 ]] ; then 
        break
    fi

    #Apply command rate limit
    sleep $rateLimit

done


echo -e "\r\n"

#If exec error is set, then a command failed. 
#Dependent commands will fail so execution should stop with message.

if [[ $ExecErr -ne 0 ]] ; then

    #Correct for Array Indexing
    let CmdPosNum=$ExecErr-1
    
    #Print Message informing user which command failed.
    echo -e "\r\n**** Command Execution Failed. ****"
    echo -e "\r\nFailed at Command Number: $ExecErr"
    echo -n "Failed Command: "
    echo ${cmdList[$CmdPosNum]}
    echo -e "\r\n"

    #If there is no commands following failed command, display different message.
    if [[ $ExecErr -eq $cmdTotal ]] ; then 
        echo "Failed at Last Command"
        echo "Correct Failed Command to Complete Import Process."
        echo -e "\r\n"
    else 
        #Print next command to be run. Functionality for resuming batch to be added later.
        echo -n "Next Command: "
        echo ${cmdList[$ExecErr]}
        echo -e "Correct and Manually Run Failed Command and re-run script with \"To-Be-Built\""
        echo -e "\r\n"
    fi

    echo "**** Command Execution Failed. ****"
    echo -e "\r\n"
    exit $ExecErr

else
    #If ExecErr is not set, then all commands completed successfully. Display message.
    echo "**** Command Execution Completed Successfully. ****"
    echo "**** Configuration Import Complete. ****"
    echo -e "\r\n"
    exit 0

fi

