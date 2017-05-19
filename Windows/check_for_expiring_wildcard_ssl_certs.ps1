##################################################
# Author: Ben Peters (bpeters@emich.edu)
# Check for wildcard SSL Certificate Expirations for your domain
#
# To use, the nagios command should be defined as this in your nrpe.cfg on the server:
# CheckWildCardSSLCerts=cmd /c echo <path>\<to>\<file>\check_for_expiring_wildcard_ssl_certs.ps1 $ARG1$ $ARG2$ | PowerShell.exe -Command -
#
# Then, your nagios commands.cfg should have a line like this:
#
# #Command to check for expired SSL Certificates
# define command{
#         command_name    CheckWildCardSSLCerts
#         command_line    /usr/local/nagios/libexec/check_nrpe -H $HOSTADDRESS$ -c CheckWildCardSSLCerts -t 500 -n -a $ARG1$ $ARG2$
# }
#
# Argument 1: Should be how many days you want to check - i.e. will report any that expire within that number of days
# Argument 2: Should be "Yes" if you want it to automatically generate a CSR for expiring certs
#
##################################################

# What is your domain name?
$DomainName = 'example.com'

# Who should be emailed a copy of the genrated CSR?
$EmailContact = 'someone@example.com'

# Who should it show that the CSR email came from?
$EmailFrom = 'sender@example.com'

# What is your SMTP gateway?
$SMTPRelay = 'smtp-relay.gmail.com'

# Based on your domain name, this is the wildcard certificate we'll be checking for
$DefaultCertificateCN = 'CN=*.' + $DomainName

# Run a search for all SSL certificates expiring in $DaysOut days
$list = Get-ChildItem -Path cert: -Recurse -SSLServerAuthentication | where { $_.notafter -le (get-date).AddDays($DaysOut) -AND $_.notafter -gt (get-date)} | select notafter, issuer, thumbprint, subject | sort-object notafter
    
# Find total number of certificates
$Total = Get-ChildItem -Path cert: -Recurse -SSLServerAuthentication | where { $_.notafter -gt (get-date)} | select notafter, issuer, thumbprint, subject | sort-object notafter
    
# Go through all our results
foreach ($cert in $list) {
    
    $NumberOfTotalCerts++

    # Increment the number of expired certificates, if there is one
    if ($cert.Thumbprint) {
        $NumberOfExpiringCerts++
    }
    
    # Add this to the array
    $OutputData = $cert.Thumbprint + '  '
    $PerfData += $outputData

    # Check to see if this is a * Certificate
    if ($cert.subject -like $DefaultCertificateCN) {
            
        # Check to see if we're auto generating our CSRs or not
        if ($args[1] -eq 'Yes') {
                
            # We are generating them, so set up some basics first
            $Date = (Get-Date).ToString('yyyy')
            $WebsiteName = $env:computername 
            $ReqFile = "C:\Users\Public\Desktop\$WebsiteName-" + "$Date" + ".req"
                
            # Check to see if we've already generated a CSR or not.  If not, go ahead and do so.
            if (-Not (Test-Path $ReqFile)) {
                
                $InfFile = '
                [NewRequest]
                Subject = ' + $DefaultCertificateCN +'
                KeySpec = 1
                KeyLength = 2048
                Exportable = FALSE
                ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
                MachineKeySet = True
                RequestType = CMC
                [RequestAttributes] 
                CertificateTemplate= WebServer
                '
                                    
                $FinalInfFile = "C:\Users\Public\Desktop\$WebsiteName-" + "$Date" + ".inf"
                New-Item $FinalInfFile -type file -value $InfFile
                cmd /c "certreq -new $FinalInfFile $ReqFile"

                # Now that the CSR is generated, mail it out!
                $expDate = $cert.notafter
                $body = '
                Please generate a new * cert for this server, IIS7 format.
                The current one is set to expire on ' + $expDate + '.

                The .req file is available on the public desktop of the server.

                Once the .crt file is generated, copy it to the server and run the following:
                CertReq -accept <file>.cer
                '
                
                send-mailmessage -from $EmailFrom -to $EmailContact -subject "CSR Request For $env:computername" -body $body -Attachments $ReqFile -priority High -dno onSuccess, onFailure -smtpServer $SMTPRelay
            }

        }

    }
}
    
# If we have any expiring, give a warning exit code.  Otherwise, OK
if ($NumberOfExpiringCerts -ne 0) {
    $ExitCode = 1
    write-host "Warning: " $NumberOfExpiringCerts " certificates will expire within $DaysOut days. |" "'"$PerfData"'"
} else {
    $ExitCode = 0
    $PerfData = [string]$Total.count + " Possible SSL Certificates found."
    write-host "OK! All certificates are current. |" "'"$PerfData"'"
}