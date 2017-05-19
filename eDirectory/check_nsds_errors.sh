#!/bin/bash
########################
# Author: Ben Peters (bpeters@emich.edu)
# This plugin will check for errors through periodic runs of ndsrepair.
# If there are more errors than your threshold limit, you get an alert.
#
########################

# Set our threshold values.
AllowedErrors=0

# Set base output
Output=''

# Get the current error status
ErrorString=`sudo /opt/novell/eDirectory/bin/ndsrepair -E | grep 'Total errors:'`
Errors=${ErrorString:20}

# Output based on errors reported
if [[ $Errors -gt $AllowedErrors ]]; then

	ExitCode=1
	Output="WARNING: $ErrorString"

else

	ExitCode=0
	Output="OK: 0 Errors Reported"
	
fi

# Return exit code and text
echo -e $Output
exit $ExitCode
