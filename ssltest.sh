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
}

function drawReport()
{
	# draw results
	printf "%-20s %-40s %-20s\n" "URL" "Expires" "Difference (epoch)" #header
	printf "%-20s %-40s %-20s\n\n" "${URL}" "${certexp}" "${datediff}" #data

	# verify difference isn't less than 60 days
	if [ "$datediff" -lt "5184000" ]; then
			printf "!!!!This cert is expiring on %s!!!!", $certexp
	else
			echo "This cert has more than 60 days left, no rush. Go grab some coffee."
	fi
}

function main()
{
	# main loop

	# If the URL isn't already set, request it.
	if [[ -z "$URL" ]]; then
		getUrl
	else
		URL="$1"
	fi
	pullCert
	drawReport
}

# if an argument is provided, it is set to the URL.
unset URL
URL="$1"
main $URL