##################################################
# Author: Ben Peters (bpeters@emich.edu)
# Check for size of a specific file
#
# To use, the nagios command should be defined as this in your nrpe.cfg on the server:
# CheckFileSize=cmd /c echo <path>\<to>\<file>\check_windows_file_size.ps1 $ARG1$ $ARG2$ | PowerShell.exe -Command -
#
# Then, your nagios commands.cfg should have a line like this:
#
# #Command to check for Windows File Size
# define command{
#         command_name    CheckFileSize
#         command_line    /usr/local/nagios/libexec/check_nrpe -H $HOSTADDRESS$ -c CheckFileSize -t 500 -n -a $ARG1$ $ARG2$
# }
#
# Argument 1: Should be the path of the file
# Argument 2: Should be the size (in MB) to trigger a warning
#
##################################################	
	
$file = $args[0]
$size = $args[1]
	
if (Test-Path $file) {
	$filesize = (Get-Item $file).length/1024/1024
	if ($filesize -ge $size) {
		$ExitCode = 1
		write-host "WARNING: File is over size limit! " $filesize " Mb"
	} else {
		$ExitCode = 0
		write-host "OK: Size is " $filesize " Mb"
	}
} else {
	$ExitCode = 3
	write-host "Unknown: File not found"	
}