#!/bin/bash
########################
# Author: Ben Peters (bpeters@emich.edu)
# This plugin will check the stats of the running eDirectory LDAP.
# You may configure your warning thresholds below.
# The thresholds are based on the difference in values between runs; so it will depend on how often you run this check.
#
########################

# Set our threshold values.  If the differences between these and the last run are over this threshold, kick out a warning.
StatsToCheck='errors securityErrors wholeSubtreeSearchOps oneLevelSearchOps searchOps strongAuthBinds simpleAuthBinds'
errors=1000
securityErrors=100
wholeSubtreeSearchOps=200
oneLevelSearchOps=200
searchOps=200
strongAuthBinds=100
simpleAuthBinds=500

# Set base output
Output=''

# If this has been run before, move the last log file
if [ -f /etc/nagios/ldapstats.txt ]; then
	mv /etc/nagios/ldapstats.txt /etc/nagios/ldapstats-old.txt
fi

# Get the current LDAP stats
ldapsearch -H ldap://127.0.0.1:389 -x -b "" -s base > /etc/nagios/ldapstats.txt

# Make sure the search even worked.  If not, just dump out now and error.
if [ $? = 0 ]; then
	Connected="Yes"
else
	FAILURE="YES"
	ExitCode=2
	Output="CRITICAL: Failed to connect to LDAP!"
fi

# If the search worked, do the next tests
if [[ $Connected = "Yes" ]]; then
	
	# Was this run previously?  If so, run comparisons.  If not, just dump out.
	if [ -f /etc/nagios/ldapstats-old.txt ]; then
		
		# Go through each of the statistics that we care about
		for Stat in `echo $StatsToCheck`;
			do
				# Read the value from both files
				OLD=`grep "^$Stat" /etc/nagios/ldapstats-old.txt | cut -f2 -d' '`
				NEW=`grep "^$Stat" /etc/nagios/ldapstats.txt | cut -f2 -d' '`
				
				# Find the difference between them
				DIFF=$((NEW-OLD))
				
				# If the values are negative, we've rebooted.  Kick out an unknown.
				if [[ $DIFF -lt 0 ]]; then
				
					ExitCode=3
					Output="Difference is negative.  LDAP recently rebooted."				
				
				else
				
					# See if this difference is greater than the threshold we set
					if [[ $DIFF -ge $Stat ]]; then
						ExitCode=1
						Output="$Output $Stat is too high! $DIFF found since last run. "
						echo $(date +%T) "$Output $Stat is too high! $DIFF found since last run. "  >> /etc/nagios/error.log
					else
						Output="$Output $Stat OK. "
					fi
				
				fi
				
		done
		
	else
		ExitCode=3
		Output="Unknown: Script just ran for the first time.  Will compare on next run."
	fi
	
fi

# Return exit code and text
echo -e $Output
exit $ExitCode
