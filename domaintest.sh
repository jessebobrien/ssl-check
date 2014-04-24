#!/bin/bash
# This script is intended to easily check information of a domain name and verify validity for at least 60 days


function exit_error()
{
	# explain the error and quit.
	printf "We experienced a problem: $1\n"
	exit 1
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
function pullWhois()
{
	# pulls entire cert for given URL
	FULLWHOIS=$(echo | whois "$URL" 2>/dev/null)
	# cuts entire cert down the a string that is the line containing the expiration date of cert
	CUTWHOIS=$(echo "$FULLWHOIS" | grep -i -m 1 "Expiration\|Expiry")
	# this cuts the cert date down
	CUTWHOIS=${CUTWHOIS#*: }
	# converts cert date to epoch time
	EPOCHWHOIS=`date --date="$CUTWHOIS" +%s`
	# gives us identical epoch time for time as run
	EPOCHNOW=`date +%s`
	# calculate differnce between epoch dates
	DATEDIFF=$(expr "$EPOCHWHOIS" - "$EPOCHNOW")
	# give days left in readable format
	DAYSLEFT=$(($DATEDIFF/86400))
}
function drawReport()
{
	# draw results if verbose mode is enabled
        if [[ $VERBOSE -eq 1 ]] ; then
		printf "\n%-20s %-40s %-20s\n" "URL" "Expires" "Difference (epoch)" #header
		printf "%-20s %-40s %-20s\n\n" "${URL}" "${CUTWHOIS}" "${DATEDIFF}" #data
	fi
	# verify difference isn't less than 60 days
	if [ "$DATEDIFF" -lt "5184000" ]; then
			verbose "!!!!This cert is expiring in $DAYSLEFT!!!!"
						verbose "\n\nAn email has been sent to the root user of this machine\n\n"
						verbose "ATTENTION! This cert is expiring in $DAYSLEFT days, please correct immediately: ""$URL" | \
						mail -s "SSL Expiration Warning!" root
	else
			verbose "This cert has $DAYSLEFT days left, no rush. Go grab some coffee."
	fi
        printf "$DAYSLEFT\n" #print this even if verbose isn't active, provides parseable output for other applications.
}
function parseopts() {
        # command-line argument parsing

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
                if [[ $VERBOSE -eq 1 ]] ; then
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
	verbose "Ensuring that $URL has at least $DAYS days left of validity remaining."
	checkUrl
	if [ "$URLGOOD" = false ]; then
		exit 1
	fi
	pullWhois
	drawReport
}

# Clear any pre-existing arguments
unset URL
unset VERBOSE
unset QUIET
unset DRY

# parse all options passed from the command line.
parseopts $*
main $URL
