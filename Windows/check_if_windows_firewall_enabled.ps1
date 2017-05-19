##################################################
# Author: Ben Peters (bpeters@emich.edu)
# Check for Firewall Actually Enabled
#
# To use, the nagios command should be defined as this in your nrpe.cfg on the server:
# CheckFirewallStatus=cmd /c echo <path>\<to>\<file>\check_if_windows_firewall_enabled.ps1 $ARG1$ $ARG2$ | PowerShell.exe -Command -
#
# Then, your nagios commands.cfg should have a line like this:
#
# #Command to check for Windows Firewall Status
# define command{
#         command_name    CheckFirewallStatus
#         command_line    /usr/local/nagios/libexec/check_nrpe -H $HOSTADDRESS$ -c CheckFirewallStatus -t 500 -n -a $ARG1$ $ARG2$
# }
#
# Checks if firewall is enabled
#
##################################################	
	

$data = netsh advfirewall show currentprofile | Out-String
$lines = $data.split("`n")

if ($lines[3] -like '*ON*') {
	$ExitCode = 0
	write-host "OK: Firewall is Enabled"
} elseif ($lines[3] -like '*OFF*') {
	$ExitCode = 1
	write-host "WARNING: Firewall is Disabled."
} else {
	$ExitCode = 3
	write-host "Unknown: Scripting disabled?"
}