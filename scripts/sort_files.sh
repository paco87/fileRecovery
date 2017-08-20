#!/bin/bash
# Author: paco87

###################
##General Functions and Varaibles:


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
LOG_DIR="${SCRIPT_DIR}/${SCRIPT_NAME%%.sh}.log"


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
USAGE: ${SCRIPT_NAME} --startdir <dir> --input <file_path> --savedir <dir> --debug --help
EOF

}

function helptext() {

	local tab=$(echo -e "\t")
cat << EOF
$(usage)
This scripts search for certain files and moves them to given directory
--startdir <dir> starting directory for searching
--savedir <dir> root dir for moving files 
--input <file_path> config files with extensions 
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
		--startdir)
			shift 
			if [ -d $1 ];then
				START_DIR=$1
			else
				log [ERROR] "given start directory does not exists: $1"
				exit 1
			fi
			
			log [DEBUG] path set ${START_DIR}
		;;
		--input)
			shift 
			if [ -r $1 ] && [ -f $1 ] ;then
				INPUT_DATA=$1
			else
				log [ERROR] "given data file is not readable or does not exists $1"
				exit 1
			fi
			
			log [DEBUG] path set ${INPUT_DATA}
		;;
		--savedir)
			shift 
			if [ -d $1 ];then
				SAVE_DIR=$1
			else
				log [ERROR] "given save directory does not exists: $1"
				exit 1
			fi

			if [ ! -w $1 ];then
				log [ERROR] "NO write permissions to given dir $1"
				exit 1
			fi
			
			log [DEBUG] path set ${SAVE_DIR}
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
if [ -z "${INPUT_DATA}" ] ; then
	log [ERROR] "INPUT DATA must be set"
	exit 1
fi




log [DEBUG] "START dir point $START_DIR"
log [DEBUG] "input file $INPUT_DATA"
log [DEBUG] "Everything will be save to $SAVE_DIR"


if ! `grep -qsw 'LP;extension;group;action;done' ${INPUT_DATA}` ;then
	log [ERROR] "incorrect file format"
	exit 1
fi	


config_file=`cat ${INPUT_DATA} |grep -v 'LP;extension;group;action;done'`
total=`echo "${config_file}"|wc -l`

IFSbkp="$IFS"
IFS=$'\n'


counter=1;
for line in $config_file; do

	# config line reading
	action=`echo $line |awk -F';' '{print $4}'`
	lp=`echo $line |awk -F';' '{print $1}'`
	category=`echo $line |awk -F';' '{print $3}'`
	ext=`echo $line |awk -F';' '{print $2}'`
	log [DEBUG] "Processing line ${counter} from ${total} . Line: ${line} . lp ${lp} . category ${category} . ext ${ext}"
# finding files
	found_files=""
	if [[ "${action^^}" == "LEAVE" ]] ;then
		log "Files with extension ${ext} will be not touched - find not executed"
    else
		found_files=`find ${START_DIR} -name "*.${ext}"`
		log [DEBUG] "Found files: ${found_files}"

	fi



	case "${action^^}" in 
		COPY)
			log "moving files: ${ext}"
			for movefile in ${found_files}; do
				movefileto=`echo ${SAVE_DIR}/$(basename $(dirname ${movefile}))/category/$(basename ${movefile})|sed s/\\\/\\\//\\\//g`
				log [DEBUG] "moving file ${movefile} to ${movefileto}"


			done	
			
			log "Files ${ext} moved to $movefileto"
		;;
		REMOVE)
			log "Removing files: ${ext}"

			for removefile in ${found_files}; do
				log [DEBUG] "removing file ${removefile}"
			done	
			log "Files with extension: ${ext} removed"
		;;

		LEAVE)
			log "Leave set - files will be not touched with extension: ${ext}"
		;;



		*)
		log [ERROR] "this action ${action} is not defined"
	esac	


	let counter++;
done
IFS="$IFSbkp"



