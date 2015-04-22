#!/bin/sh

# Copyright 2015 Plumbee Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Karotz controller in shell 
# This is not as good as a JS app running on karotz but in a simplistic control it is good enough
# note the simple xml app needs to be installed on the karotz device 


# this is tied to the install of the app on the kartoz unit
# it is display in the config for the app
INSTALLID="PUT YOU INSTALL ID HERE"

# This is tide to the app you upload ( simple xml file in our case)
API_KEY="INSERT API KEY HERE"
SECRET_KEY="INSERT SECRET KEY HERE"


TEMPFILE=`mktemp /tmp/karotzshellXXXXXX`
INTERACTIVE_KEY_FILE="${HOME}/.karotz.key"
VERBOSE=0
SENDSTOP=0
CONFIG_FILE=""

CURL_EXEC="curl"
CURL_OPT="-s"


# Print out the usage
function usage {
        echo "`basename $0` -v action  [name=value]"
	echo "   -v             verbose"
	echo "   -s             send a stop afer this command can also be done with `basename $0` interactivemode action=stop"
	echo "   -f file        save file for karotz interactive id '\$HOME/.karotz.key' default"
	echo "   -c configfile  each line contains an instuction ( sleep n exists as additional command )"
	echo "examples: "
	echo "   `basename $0` led 'action=light&color=FF0000'"
	echo "   `basename $0` tts 'action=speak&lang=EN&text=this%20is%20a%20test'"
	echo "see: http://dev.karotz.com/api/"
	echo
}

function cleanup {
	rm -f ${TEMPFILE}
	exit $1
}

# This signs the start uel
function sign_url {
	TIMESTAMP=`date +%s`
	QUERY="apikey=${API_KEY}&installid=${INSTALLID}&once=26823${RANDOM}&timestamp=${TIMESTAMP}"
	SIG=`echo -n ${QUERY}| openssl dgst -sha1 -hmac $SECRET_KEY -binary | openssl enc -base64 | perl -MURI::Escape -ne 'chomp; print uri_escape($_);'`
	echo "${QUERY}&signature=${SIG}"
}

# stop out interactive session
function karotz_stop {
	karotz_call interactivemode action=stop
	rm -f $INTERACTIVE_KEY_FILE
}

# Make karotz do something
function karotz_call {
	ACTION=$1
	DATA=$2
	LOOP_COUNT=0;
	RESPONSE=`${CURL_EXEC} ${CURL_OPT} "http://api.karotz.com/api/karotz/${ACTION}?${DATA}&interactiveid=${INTERACTIVE_ID}"`
	# Lets keep trying but do givceup
	while [ "`echo $RESPONSE | grep OK`" = "" -a ${LOOP_COUNT} -lt 5 ]; do
		 LOOP_COUNT=`expr ${LOOP_COUNT} + 1`
		# If its a 2nd try our interactive id is probably wrong
		if [ ${LOOP_COUNT} -gt 2 ]; then 
			rm -f $INTERACTIVE_KEY_FILE
			karotz_start
		fi
		if [ $VERBOSE -gt 0 ]; then 
			echo "Curl request failed returned :-"
			echo "http://api.karotz.com/api/karotz/${ACTION}?${DATA}&interactiveid=${INTERACTIVE_ID}"
			echo $RESPONSE
			echo
		fi
		RESPONSE=`${CURL_EXEC} ${CURL_OPT} "http://api.karotz.com/api/karotz/${ACTION}?${DATA}&interactiveid=${INTERACTIVE_ID}"`
	done
	
}

function karotz_start {
	SIGNED_QUERY=${sign_url}
	if [ -e ${INTERACTIVE_KEY_FILE} ]; then
		INTERACTIVE_ID=`cat ${INTERACTIVE_KEY_FILE}`
		if [ $VERBOSE -gt 0 ]; then 
			echo "loaded interactive id from ${INTERACTIVE_KEY_FILE}"
		fi
		return
	fi
	if [ $VERBOSE -gt 0 ]; then 
		echo "have signed query ${SIGNED_QUERY}"
	fi
	${CURL_EXEC} ${CURL_OPT} "http://api.karotz.com/api/karotz/start?${SIGNED_QUERY}" > $TEMPFILE
	if [ $VERBOSE -gt 0 ]; then 
		echo "data returned = ";
		cat ${TEMPFILE}
		echo 
	fi
	INTERACTIVE_ID=`cat ${TEMPFILE}| perl -ne '/.*interactiveId>([\da-f-]*)<\/interactiveId>/ && print $1;'` 
	if [ "${INTERACTIVE_ID}" = "" ]; then
		echo "Failed to get interactive id"
		echo "This generally happens if the last call did not send a stop"
		# For cloudbees its bad to stop here with non 0 exit
		cleanup 0
	fi
	if [ $VERBOSE -gt 0 ]; then 
		echo "have interactive id ${INTERACTIVE_ID}"
	fi
	echo ${INTERACTIVE_ID} > ${INTERACTIVE_KEY_FILE}
}



while getopts "hvsf:c:" OPTION
do
     case $OPTION in
	 c) 
	     CONFIG_FILE=$OPTARG
             ;;
	 f)
	     INTERACTIVE_KEY_FILE=$OPTARG
	     ;;
         s)
             SENDSTOP=1
             ;;
         v)
             VERBOSE=1
	     CURL_OPT="-v"
             ;;
         h)
             usage
             cleanup 0
             ;;
         ?)
             echo "unkown command $OPTION"
             usage
             cleanup 1
             ;;
     esac
done

shift $(($OPTIND - 1))

karotz_start
# send commad
if [ "${CONFIG_FILE}" != "" ]; then 
	while read curline; do
		if [ $VERBOSE -gt 0 ]; then
			echo "Doing $curline"
		fi
		CMD=`echo -n $curline | cut -d' ' -f 1`
		DATA=`echo -n $curline | cut -d' ' -f 2`
		if [ "${CMD}" = "sleep" ]; then
			sleep ${DATA}
		else
			karotz_call $CMD $DATA
		fi
	done < "${CONFIG_FILE}"
else
	karotz_call $1 $2
fi


# stop app
if [ ${SENDSTOP} -gt 0 ]; then 
	RESPONSE=${karotz_stop}
	if [ $VERBOSE -gt 0 ]; then 
		echo "Response from stop = ${RESPONSE}"
	fi
fi


cleanup 0

