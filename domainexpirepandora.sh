#!/bin/bash
# This script is intended to easily check information of a domain and report remaining days on registrar

function exit_error()
{
        # explain the error and quit.
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
        # verify difference isn't less than 60 days
	printf "$daysleft"
}
function main()
{
        # main loop
        checkUrl
        pullwhois
        drawReport
}
# if an argument is provided, it is set to the URL.
unset URL
URL="$1"
main $URL
