#!/bin/bash
# This script is intended to easily check information of a cert and verify validity for at least 60 days


function exit_error()
{
	# explain the error and quit.
	printf "We experienced a problem: $1"
	exit 1
}

function getUrl()
{
	# ask for input
	echo "Please enter web address to check [www.example.com]:"
	# puts input into a string
	read URL
}
function checkUrl()
{
	# gives us a value to work with.
	checkUrl=`dig +short $URL`
	#checks output and displays message and gives boolean output to work with
	if [ -n "$checkUrl" ]; then
			printf "\nHostname: $URL is valid.\n"
			urlGood=true
	else
			printf "\nCould NOT verify $URL exists!\n"
			urlGood=false
	fi
}
function checkssl
{
	# gives variable string conetent if we found the certificate
	certexists=$(echo | openssl s_client -connect "$URL":443 2>/dev/null | openssl x509 -noout -dates | grep After)
	# exits script if no variable value with error message
	if [[ $certexists == *After* ]]; then
			printf "\nSSL Appears to be present\n"
	else
			printf "\nSSL was not found!\n"
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
	printf "\n%-20s %-40s %-20s\n" "URL" "Expires" "Difference (epoch)" #header
	printf "%-20s %-40s %-20s\n\n" "${URL}" "${certexp}" "${datediff}" #data

	# verify difference isn't less than 60 days
	if [ "$datediff" -lt "5184000" ]; then
			printf "!!!!This cert is expiring on %s!!!!", $certexp
						printf "\n\nAn email has been sent to the root user of this machine\n\n"
						echo "ATTENTION! This cert is expiring in $daysleft days, please correct immediately: ""$URL" | \
						 mail -s "SSL Expiration Warning!" root
	else
			echo "This cert has $daysleft days left, no rush. Go grab some coffee."
	fi
}

function main()
{
	# main loop

	# If the URL isn't already set, request it.
	if [[ -z "$URL" ]]; then
		getUrl
		checkUrl
		if [ "$urlGood" = false ]; then
						exit 0
				fi
	else
		URL="$1"
				checkUrl
				if [ "$urlGood" = false ]; then
						exit 0
				fi
	fi
	checkssl
	pullCert
	drawReport
}

# if an argument is provided, it is set to the URL.
unset URL
URL="$1"
main $URL
