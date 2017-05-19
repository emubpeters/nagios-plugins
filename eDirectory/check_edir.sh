#!/bin/bash
########################
# Author: Ben Peters (bpeters@emich.edu)
# This plugin will check the status of the Novell Directory Services Daemon.
#
########################

errorlvl=0
output=""

# Run the ndsd status command
/usr/bin/sudo /etc/init.d/ndsd status > /etc/nagios/tempfile 2>&1
ndsdstatus="$?"

# If the command produces an error, return the error
if [ "$ndsdstatus" -gt "0" ]; then
  output="CRITICAL: Failed to run the ndsd status command successfully!\n`cat /etc/nagios/tempfile`"
  errorlvl=2
else
  output="OK: ndsd status is good."
fi

# Clean up the temp file, output the result and the error level
#rm -f /etc/nagios/tempfile
echo -e $output
exit $errorlvl
