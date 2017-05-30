#!/bin/bash

########################
# Author: Ben Peters (bpeters@emich.edu)
# This plugin will check the replication status of a given partition.
# This will likely have to be edited pretty heavily for a new environment
# based on the output of ndsrepair -E and where the lines fall.
#
########################

# What partition are we looking for?
PARTITION='<partition name>'

# How many seconds behind should trigger a warning?
WARNSECS=120

# How many seconds behind should trigger a critical?
CRITSECS=240

# Set base output
CHECK="NO"

# remove old output
rm /etc/nagios/result.txt
rm /etc/nagios/times.txt

# Get the current error status
sudo /opt/novell/eDirectory/bin/ndsrepair -E > /etc/nagios/result.txt

# Read the file output, and go through it line by line
file="/etc/nagios/result.txt"
while IFS= read line
do
	if [[ $line == "Partition: $PARTITION" ]]; then
		# We know we're in the right partition now
		CHECK="YES"
	fi
	
	if [[ $CHECK == "YES" ]]; then
		
		# We know we're in the right partition, start reading the lines
		if [[ $line == *"Replica:"* ]]; then
		
			# Insert the server name and time into the times array
			SERVER=${line:12:4}
			#echo $SERVER
			TIMESTAMP=${line:41}
			TIMESTAMP=${TIMESTAMP//-//}
			dat2=$(date -d "$TIMESTAMP" +'%s')
			#echo $dat2
			echo $SERVER,$dat2 > /etc/nagios/times.txt		
		fi
	fi
	
done <"$file"

##########################################################################
#  Check the replica times
##########################################################################
file="/etc/nagios/times.txt"
ExitCode=0
WARNS=""
CRITS=""
NOW=$(date +'%s')
while IFS= read line
do
	SERVER=${line:0:4}
	TIME=${line:5}
	DIFF=`expr $NOW - $TIME`
	
	if [[ $DIFF -gt $WARNSECS ]]; then
		WARNS="$WARNS $SERVER "
	fi
	
	if [[ $DIFF -gt $CRITSECS ]]; then
		CRITS="$CRITS $SERVER "
	fi
	
done <"$file"

if [[ $CRITS != '' ]]; then
	echo -e "Critcal! $CRITS are more than $CRITSECS seconds behind!"
	ExitCode=2
elif [[ $WARNS != '' ]]; then
	echo -e "Warning: $WARNS are more than $WARNSECS seconds behind!"
	ExitCode=1
else 
	echo -e "OK. All replicas within $WARNSECS seconds."
	ExitCode=0
fi

exit $ExitCode