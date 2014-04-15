#!/bin/bash
# This script is intended to easily check information of a cert and verify validity for at least 60 days


function exit_error()
{
	# explain the error and quit.
	printf "We experienced a problem: $1"
	exit 1
}
function checkUrl()
{
        # gives us a value to work with.
        checkUrl=`dig +short $URL`
        #checks output and displays message and gives boolean output to work with
        if [ -n "$checkUrl" ]; then
                urlGood=true
        else
                urlGood=false
		exit 0
        fi
}
function checkssl
{
        # gives variable string conetent if we found the certificate
        certexists=$(echo | openssl s_client -connect "$URL":443 2>/dev/null | openssl x509 -noout -dates | grep After)
        # exits script if no variable value with error message
        if [[ $certexists == *After* ]]; then
		sslGood=true
        else
		urlGood=false
                exit 0
        fi
}
function pullCert()
{
	# pulls entire cert for given URL
	fullcert=$(echo | openssl s_client -connect "$URL":443 2>/dev/null | openssl x509 -noout -text )
	# cuts entire cert down the a string that is the line containing the expiration date of cert
	certexp=$(echo "$fullcert" | grep "Not After :")
	# this cuts the cert date down
	certexp=${certexp#*: }
	# gives us current time in identical format to cert
	datum=$(date +%b" "%d" "%H:%M:%S" "%Y" "%Z)
	# converts cert date to epoch time
	epochcert=`date --date="$certexp" +%s`
	# gives us identical epoch time for time as run
	epochnow=`date +%s`
	# calculate differnce between epoch dates
	datediff=$(expr "$epochcert" - "$epochnow")
        # give days left in readable format
        daysleft=$(($datediff/86400))
}
function drawReport()
{
	# draw results
	printf "$datediff"
}

function main()
{
	# main loop
	checkUrl
	checkssl
	pullCert
	drawReport
}

# if an argument is provided, it is set to the URL.
unset URL
URL="$1"
main $URL
