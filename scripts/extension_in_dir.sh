#!/bin/bash
# Author: paco87

###################
##General Functions and Varaibles:


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
LOG_DIR="${SCRIPT_DIR}/${SCRIPT_NAME%%.sh}.log"
CLEAR_SCREEN="\n\n\n"

#Logging handling 
function log (){
	now=$(date)
	
	if [[ "$1" == "[DEBUG]" ]] ; then
		# echo -e "${now} - $@" 1>&2 | tee -a $LOG_DIR	
		if [[ "${DEBUG}" == "true" ]]; then
			echo "${now} - $@" 1>&2 > >(tee -a $LOG_DIR) 2> >(tee -a $LOG_DIR >&2)
		fi
	elif [[ "$1" == "[ERROR]" ]] ; then
		echo "${now} - $@" 1>&2 > >(tee -a $LOG_DIR) 2> >(tee -a $LOG_DIR >&2)
	else
		echo "${now} [INFO] - $@" > >(tee -a $LOG_DIR) 2> >(tee -a $LOG_DIR >&2)
	fi

}

function usage() {	
cat << EOF
USAGE: ${SCRIPT_NAME} --dir <dir> --out <file_path> --debug --help 
EOF

}

function helptext() {

	local tab=$(echo -e "\t")
cat << EOF
$(usage)
This scripts search for certain files and moves them to given directory
--dir <dir> direcotry where you want to find all extensions from files
--out <file_path> File path to where save results if not specified everything is printed to stdout
EOF

}



# argument handling to 
function arg_handler(){

log [DEBUG] "Number of argumts passed" $#

if [ $# -lt 1 ];then
	usage 
	exit 1
fi

while [ $# -ge 1 ] ; do
	log [DEBUG] "Proccessing argument $1"

	case $1 in
		--debug)
			DEBUG="true"
		;;
		--help)
			helptext
			exit 0
		;;
		--dir)
			shift 
			if [ -d $1 ];then
				DIR_MAIN=$1
			else
				log [ERROR] "given directory does not exists: $1"
				exit 1
			fi
			
			log [DEBUG] path set ${DIR_MAIN}
		;;
		--out)
			shift 
			if [ -d `dirname $1` ];then
				DIR_OUT=$1
			else
				log [ERROR] "given directory does not exists: `dirname $1`"
				exit 1
			fi
			
			if ! [ -w `dirname ${DIR_OUT}` ];then
				log  [ERROR] "You have no wright permissions to the file $1"
				exit 1
			fi
			
			log [DEBUG] path set ${DIR_OUT}
		;;


		*)
		log [ERROR] "not supported arg"
		helptext
		exit 1
		;;
	
	esac


shift
done

}
#argument handling execution this way I never lose arguments from main if shift is used 
arg_handler "$@"

log [DEBUG] "DEBUG enabled"
log [DEBUG] " main variables set-
	SCRIPT_DIR=$SCRIPT_DIR
	SCRIPT_NAME=$SCRIPT_NAME
	LOG_DIR=$LOG_DIR"
#MAIN PROGRAM and functions
log "Starting find"
FilesFound=`find ${DIR_MAIN} ! -type d -exec basename {} \;` 

IFSbkp="$IFS"
IFS=$'\n'

counter=1;
extension=""
result=""
log "cleaning ${DIR_OUT} file "
echo "" > ${DIR_OUT}
total=`echo "$FilesFound"|wc -w`
log "Iterating over $total files"
for file in $FilesFound; do
	extension=""
	extension=`echo $file |awk -F'.' '{print $NF}'`
	log [DEBUG] "Processing file ${counter}. Path: ${file} got extension $extension"
	if `echo $result |grep -qws ${extension}` ; then
		:
	else
		result=`echo -e "${result} \n ${extension}"`
		log "Current file [ ${counter} ] found [ $(echo $result|wc -w) ] numbers of extensions from ${total} "
		echo "${extension}" >> ${DIR_OUT}
	fi

	let counter++;
done
IFS="$IFSbkp"

#Prining result
if [ -z "${DIR_OUT}" ] ;then
	echo "${result}"|sort|uniq 
else
	echo "${result}"|sort|uniq 
fi
