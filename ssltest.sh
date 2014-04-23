#!/bin/bash
# This script is intended to easily check information of a cert and verify validity for at least 60 days


function exit_error()
{
	# explain the error and quit.
	printf "We experienced a problem: $1\n"
	exit 1
}

function checkUrl()
{
	# gives us a value to work with.
	checkUrl=$(dig +short $URL)
	verbose "Digging for $URL"
	#checks output and displays message and gives boolean output to work with
	if [ -n "$checkUrl" ]; then
			verbose "Hostname: $URL is valid."
			URLGOOD=true
	else
			verbose "Could NOT verify $URL exists!"
			URLGOOD=false
			exit_error "URL is no good!"
	fi
}

function checkSsl()
{
	# gives variable string conetent if we found the certificate
	CERTEXISTS=$(echo | openssl s_client -connect "$URL":443 2>/dev/null | openssl x509 -noout -dates | grep After)
	# exits script if no variable value with error message
	if [[ $CERTEXISTS == *After* ]]; then
		verbose "SSL Appears to be present"
		SSLGOOD=true
	else
		verbose "SSL was not found!"
		SSLGOOD=false
		exit 0
	fi
}

function pullCert()
{
	# pulls entire cert for given URL
	FULLCERT=$(echo | openssl s_client -connect "$URL":443 2>/dev/null | openssl x509 -noout -text )
	# cuts entire cert down the a string that is the line containing the expiration date of cert
	CERTEXP=$(echo "$FULLCERT" | grep "Not After :")
	# this cuts the cert date down
	CERTEXP=${CERTEXP#*: }
	# gives us current time in identical format to cert
	DATUM=$(date +%b" "%d" "%H:%M:%S" "%Y" "%Z)
	# converts cert date to epoch time
	epochcert=`date --date="$CERTEXP" +%s`
	# gives us identical epoch time for time as run
	epochnow=`date +%s`
	# calculate differnce between epoch dates
	datediff=$(expr "$epochcert" - "$epochnow")
	# give days left in readable format
	daysleft=$(($datediff/86400))
}

function drawReport()
{
	# draw results if verbose mode is enabled
	if [[ $VERBOSE -eq 1 ]] ; then
		printf "\n%-20s %-40s %-20s\n" "URL" "Expires" "Difference (epoch)" #header
		printf "%-20s %-40s %-20s\n\n" "${URL}" "${CERTEXP}" "${datediff}" #data
	fi

	# verify difference isn't less than 60 days
	if [ "$datediff" -lt "5184000" ]; then
			verbose "!!!!This cert is expiring on %s!!!!", $CERTEXP
						verbose "\n\nAn email has been sent to the root user of this machine\n\n"
						verbose "ATTENTION! This cert is expiring in $daysleft days, please correct immediately: ""$URL" | \
						mail -s "SSL Expiration Warning!" root
	else
			verbose "This cert has $daysleft days left, much better than the $DAYS you had requested. Go grab some coffee."
	fi

	printf "$daysleft\n" #print this even if verbose isn't active, provides parseable output for other applications.
}

function parseopts() {
	# Arguments Parser

	while getopts "d:u:dhqv" OPTION ; do
		case $OPTION in
		h) usage          ;;
		d) DAYS=$OPTARG   ;;
		u) URL=$OPTARG    ;;
		v) VERBOSE=1      ;;
		esac
	done

	if [[ -z $DAYS ]] ; then
	# we need to know how many days to compare against.
		if [ $VERBOSE -eq 1 ] ; then
			read -p "How many days of validity do you require? [default: 60] " DAYS
			DAYS=${DAYS:-60}
		else
			DAYS=60
		fi
	fi

	if [[ -z $URL ]] ; then
		# no URL provided!
		usage
	fi
	verbose "Verbose mode is enabled."
	verbose "Comparing $URL against $DAYS days."
}

function main()
{
	# main loop
	verbose "Verbose mode is enabled."
	verbose "Ensuring that $URL has at least $DAYS days of validity remaining."
	checkUrl
	if [ "$URLGOOD" = false ]; then
		exit 1
	fi

	checkSsl
	pullCert
	drawReport
}

function usage() {
	cat << EOF
	usage: $0 options
	OPTIONS:
	 -h Show [H]elp (this message)
	 -d [D]ays to compare against                                                     (not yet implemented)
	 -u [U]rl to verify                                                            [Required][Value Needed]
	 -v [V]erbose
EOF
exit 1
}

function timestamp() {
	date +%F_%T
}

function verbose() {
	# if verbose mode is active, display a nice message.
	if [[ $VERBOSE -eq 1 ]] ; then
		printf "$(timestamp) $* \n"
	fi
}

# Clear any pre-existing arguments
unset URL
unset VERBOSE
unset QUIET
unset DRY

# parse all options passed from the command line.
parseopts $*
main