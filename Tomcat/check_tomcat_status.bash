#!/bin/bash

################################################################################
#
# Author:      Ben Peters (bpeters@emich.edu)
# Description: Checks status of java tomcat process.  It first looks to see if the tomcat process is even running.
#			   Next, it tries to do a CURL to the website, to see if the site is even active. 			   
#			   Then, if it is, it checks to make sure CPU/Memory use are within acceptable limits.
#
# Usage:
# Argument 1: The unique string to search for in running processes
# Argument 2: The site to check for functionality
#
################################################################################

# Thresholds in percentage
CPUTooHigh=20
MEMTooHigh=20

# Variable Init
Output=''
ExitCode=0

# Math functions on decimals act odd, so we're multiplying everything by 10 for now because reasons
CPUTooHigh=$((10*$CPUTooHigh))
MEMTooHigh=$((10*$MEMTooHigh))

# Look up the process information
pid=`ps aux | grep ${1} | grep -v 'grep' | grep -v 'check_tomcat_status'`
IFS=' ' read -ra LINES <<< "$pid"

# First simple check; is tomcat even running?
if [ "${LINES[1]}" ]; then
	
	# Service is running, but is the website working?
	if curl ${2} > /dev/null 2>&1
	then
			
		# Now we know it's running, let's check the CPU and Memory usage
		IFS='.' read -ra CPU <<< "${LINES[2]}"
		IFS='.' read -ra MEM <<< "${LINES[3]}"
		CPUUSE=$((10*${CPU[0]}))
		MEMUSE=$((10*${MEM[0]}))
		
		# If CPU utilization is over threshold, throw warning code
		if [ $CPUUSE -gt $CPUTooHigh ]; then
			ExitCode=1
			Output="$Output CPU use too high: ${CPU[0]}%"
		fi
		
		# If Memory utilization is over threshold, throw warning code
		if [ $MEMUSE -gt $MEMTooHigh ]; then
			ExitCode=1
			Output="$Output Memory use too high: ${MEM[0]}%"		
		fi	
	
	else
		
		# Site is down, even through process is up.  Drop critical.
		ExitCode=2
		Output="CRITICAL: Process is running, but site appears to be down!"
	fi
	

else 

	# Tomcat isn't even running - critcal error.
	ExitCode=2
	Output="CRITICAL: Process is stopped!"
  
fi

# Check exit code; if it's still 0, all is good.  Write happy output.
if [ $ExitCode -eq "0" ]; then
	Output="OK: Service online.  CPU: ${CPU[0]}% Mem: ${MEM[0]}%"
fi

# Return exit code and text
echo -e $Output
exit $ExitCode