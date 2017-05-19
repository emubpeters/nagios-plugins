#!/bin/bash
########################
# This plugin will check the status of various IDM drivers.
#
# It should be called from the NRPE agent with the form: 
# 	check_driver <driver short name>
#
# This script will read the short name, and will assign the correct full DN of the driver from the list below.
# You would need to adjust those paths / short names to fit your environment.
#
########################

# Basic Variables
Username="cn=someuser,ou=someou,o=someo"
Password="areallysecurepassword"
IDMHostIP="192.168.1.2"

# Read driver from input, assign proper DN
case $1 in
	"Banner" )
		Driver="cn=Ellucian Banner,cn=somedrivercontainer,o=someo"
		;;
	"AD")
		Driver="cn=Active Directory,cn=somedrivercontainer,o=someo"
		;;
	*	)
		Driver="Error"
		;;
esac
	
# Make sure this was a valid driver
if [[ $Driver = "Error" ]]; then
	
	# Invalid driver specified; just dump out with an error.
	ExitCode=2
	Output="Unknown: Invalid driver name supplied - $Driver is not on the list."
	
else
	
	# Make sure the cert has been accepted
	if [ -f /etc/nagios/dxcmd.keystore ]; then
	
		# Get the driver state
		Output=`/usr/bin/sudo /opt/novell/eDirectory/bin/dxcmd -s -host "$IDMHostIP" -user "$Username" -password "$Password" -keystore /etc/nagios/dxcmd.keystore -getstate "$Driver"`
		case $Output in
			"0"	)
				ExitCode=2
				Output="CRITICAL: $Driver is stopped!"
				;;
			"1" )
				ExitCode=1
				Output="Warning: $Driver is starting."
				;;
			"2"	)
				ExitCode=0
				Output="OK: $Driver is running."
				;;
			"3"	)
				ExitCode=3
				Output="Warning: $Driver is stopping!"
				;;
			*	)
				ExitCode=2
				Output="Unknown: Error reported?"
				;;
		esac
		
	else
	
		# Cert hasn't been accepted.  Dump out with error.
		ExitCode=2
		Output="CRITICAL! dxcmd.keystore not found."
		
	fi
fi

# If driver is running, now let's check the unprocessed cache.
if [[ $State = 2 ]]; then

	# Query the driver to get the statisics we want
	/usr/bin/sudo /opt/novell/eDirectory/bin/dxcmd -s -host $IDMHostIP -user $Username -password $Password -keystore /etc/nagios/dxcmd.keystore -getdriverstats "$Driver" /etc/nagios/driver_stats.txt
	CacheSize=`grep "<size>" /etc/nagios/driver_stats.txt`
	CacheSize="${CacheSize//[^0-9]/}"
	UnProcessedCacheSize=`grep "<unprocessed-size>" /etc/nagios/driver_stats.txt`
	UnProcessedCacheSize="${UnProcessedCacheSize//[^0-9]/}"

	# Trigger warnings if we are over thresholds
	if [[ $CacheSize -gt 10 ]]; then
		ExitCode=1
		Output="$Output Warning: CacheSize is $CacheSize."

	# Trigger warnings if we are over thresholds
	elif [[ $UnProcessedCacheSize -gt 10 ]]; then
		ExitCode=1
		Output="$Output Warning: UnProcessedCacheSize is $UnProcessedCacheSize."
	else
		Output="$Output Cache OK."
	fi

fi

# Return exit code and text
echo -e $Output
exit $ExitCode


