#!/bin/bash

stty -echoctl
pid=$(ps -ef | grep  -m 1 diskfix.sh | grep -v grep | awk '{print $2}')
#pid=$(ps -ef | grep -v grep | grep 'diskfix.sh' | awk '{print $2}')
# pid is for some reason two values, gonna work on that line above

PreTrap() {
QUIT=1
echo
echo "CTRL+C Caught!" 
echo "In trap"
CleanUp
}

CleanUp() {
	echo
	echo "cleanup requested"
	echo
	if [[ $QUIT == 1 ]]
	then
		echo "Issue detected, exitcondition nonzero"
		exit 1
	fi
	echo "Application terminated smoothly"
	exit 0
}

trap PreTrap SIGINT SIGTERM SIGSTP INT
trap CleanUp EXIT
clear
echo '__________________________'
echo "|		          |"
echo "| Running disk fixer      |"
echo "|_________________________|"
echo "|		          |"
echo "| Current disk layout     |"
echo "|_________________________|"
echo
fdisk -l | egrep 'sd[a-z]:' | awk '{print $1, $2, $3, substr($4, 0, length($4)-1)}'
vgs vg0 | awk 'NR!=1'
pvs | grep 'vg' 
echo
echo '__________________________'
echo "|		          |"
echo "| Current disk usage      |"
echo "|_________________________|"
echo
df -hP | sort
echo 
echo 
read -p "Have you added a disk in proxmox? [y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[yY\]$ ]] 
then
	echo "Aborting..."
	echo "Go add that disk first"
	exit 1
fi

unset REPLY
echo '__________________________'
echo "|		          |"
echo "| Checking for new drives |"
echo "|_________________________|"
echo
for host in `ls -1 /sys/class/scsi_host`; do echo "- - -" > /sys/class/scsi_host/${host}/scan; done
echo
echo '__________________________'
echo "|		          |"
echo "| New disk layout         |"
echo "|_________________________|"
echo
fdisk -l | egrep 'sd[a-z]:' | awk '{print $1, $2, $3, substr($4, 0, length($4)-1)}'
vgs vg0 | awk 'NR!=1'
pvs | grep 'vg' 
read -p "Based on data above, which letter drive do we take? : " -n 1 -r
DRIVE=$REPLY
echo
echo '__________________________'
echo "|		          |"
echo "| You provided disk       |"
echo "| /dev/sd$DRIVE as your drive  |"
echo "|_________________________|"
unset REPLY
echo
read -p "Do you wish to consume this drive? [y/n]: " -n 1 -r
echo
echo
if [[ ! $REPLY =~ ^[yY\]$ ]] 
then
	echo "Aborting..."
	exit 1
fi

unset REPLY
echo

if [[ QUIT != 1 ]]
then
    echo "running pvcreate /dev/sd$DRIVE"
    pvcreate /dev/sd$DRIVE
    echo "running vgextend vg0 /dev/sd$DRIVE"
    vgextend vg0 /dev/sd$DRIVE
fi

echo
echo '__________________________'
echo "|		          |"
echo "| Please run the    	  |"
echo "| extend disk command     |"
echo "| to extend root with 5GB |"
echo "|_________________________|"
echo
printf "lvextend -rL+5G /dev/mapper/vg0-root"


