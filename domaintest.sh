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
function quietCheckurl()
{
        checkUrl=`dig +short $URL`
        if [ -n "$checkUrl" ]; then
                        urlGood=true
        else
                        urlGood=false
        fi
}
function pullwhois()
{
	# pulls entire cert for given URL
	fullwhois=$(echo | whois "$URL" 2>/dev/null)
	# cuts entire cert down the a string that is the line containing the expiration date of cert
	cutwhois=$(echo "$fullwhois" | grep -i -m 1 "Expiration\|Expiry")
	# this cuts the cert date down
	cutwhois=${cutwhois#*: }
	# converts cert date to epoch time
	epochwhois=`date --date="$cutwhois" +%s`
	# gives us identical epoch time for time as run
	epochnow=`date +%s`
	# calculate differnce between epoch dates
	datediff=$(expr "$epochwhois" - "$epochnow")
	# give days left in readable format
	daysleft=$(($datediff/86400))
}
function drawReport()
{
	# draw results
	printf "\n%-20s %-40s %-20s\n" "URL" "Expires" "Difference (epoch)" #header
	printf "%-20s %-40s %-20s\n\n" "${URL}" "${cutwhois}" "${datediff}" #data
	# verify difference isn't less than 60 days
	if [ "$datediff" -lt "5184000" ]; then
			printf "\n!!!!This cert is expiring in $daysleft!!!!\n"
						printf "\n\nAn email has been sent to the root user of this machine\n\n"
						echo "ATTENTION! This cert is expiring in $daysleft days, please correct immediately: ""$URL" | \
						 mail -s "SSL Expiration Warning!" root
	else
			echo "This cert has $daysleft days left, no rush. Go grab some coffee."
	fi
}
function quietReport()
{
	printf "$daysleft"
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
	pullwhois
	drawReport
}
function quietMain()
{
        quietCheckurl
                if [ "$urlGood" = false ]; then
                        printf "URL Error"
                        exit 1
                fi
        pullwhois
        quietReport
}

# if an argument is provided, it is set to the URL.
unset URL
URL="$1"
while getopts ":q:" quiet; do
        case $quiet in
                q)
                        URL="$OPTARG"
                        quietMain $URL
                        exit 0
                        ;;
                :)
                        printf "Option -$OPTARG requires an arguement.\n"
                        exit 1
                        ;;
        esac
done

main $URL
