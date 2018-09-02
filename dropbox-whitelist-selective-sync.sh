#!/bin/bash

LOGFILE="/var/log/dropbox-whitelist.log"

function sighuphandler() {
	exec > >(tee "$LOGFILE") 2>&1
}

trap sighuphandler SIGHUP

sighuphandler

DROPBOX_SYNC_DIR="$1"
DROPBOX_WHITELIST_FILE="$DROPBOX_SYNC_DIR/.dropbox-whitelist"

if [ -z "$DROPBOX_SYNC_DIR" ]; then
	echo "[`date "+%Y-%m-%d %H:%M:%S"`] [ERROR] - No arguments specified! Please provide a correct dropbox sync directory as an argument to this script."
	exit 1
fi

if [ ! -d $DROPBOX_SYNC_DIR ]; then
	echo "[`date "+%Y-%m-%d %H:%M:%S"`] [ERROR] - Directory $DROPBOX_SYNC_DIR doesn't exists! Please provide a correct dropbox sync directory."
	exit 1
fi

if [ ! -f $DROPBOX_WHITELIST_FILE ]; then
	echo "[`date "+%Y-%m-%d %H:%M:%S"`] [ERROR] - File $DROPBOX_WHITELIST_FILE not found!"
	exit 1
fi

LOGPATH="/var/log"
MAX_LOGFILE_SIZE=100
rotateLog() {
	find $LOGPATH -type f -wholename "$LOGFILE.*" -mtime +15 -exec rm {} \;

	currentsize=$(du -m $LOGFILE | cut -f1)
	if [ $currentsize -ge $MAX_LOGFILE_SIZE ]; then
		echo "[`date "+%Y-%m-%d %H:%M:%S"`] [INFO] - Rotating logs in the background."
		savelog -dn $LOGFILE &>/dev/null
		kill -s SIGHUP $$
	fi
}

export IFS="|"

_md5=`md5sum $DROPBOX_WHITELIST_FILE | cut -d" " -f 1`

while :; do

	# List of all the files and directories under $DROPBOX_SYNC_DIR.
	read -ra dl <<< "`find $DROPBOX_SYNC_DIR \( ! -regex '.*/\..*' \) | awk '{if(NR>1)print}' | cut -c $(expr $(echo $DROPBOX_SYNC_DIR | wc -c) + 1)- | paste -d\| -s`"

	echo "[`date "+%Y-%m-%d %H:%M:%S"`] [DEBUG] - List of all the files and directories under $DROPBOX_SYNC_DIR: ${dl[*]}"

	# List of all the whitelisted files and directories under $DROPBOX_SYNC_DIR.
	# Validation of file and directory names can't be performed for whitelisting based selective sync approach. Hence it is assumed that the file and directoriy names mentioned in whitelist are indeed correct. Incorrect file and directory names may result in undesirable results.
	wl=()
	while IFS= read -r i; do
		wl+=("$i")
	done < $DROPBOX_WHITELIST_FILE

	echo "[`date "+%Y-%m-%d %H:%M:%S"`] [DEBUG] - List of all the whitelisted files and directories under $DROPBOX_SYNC_DIR: ${wl[*]}"

	# List of elements from Directorylist that don't start with any element from Whitelist.
	diff1=()
	for i in "${dl[@]}"; do
		flag=0
		for j in "${wl[@]}"; do
			if [[ "$i" == "$j"* ]]; then
				flag=1
				break
			fi
		done
		if [ $flag == 0 ]; then
			diff1+=("$i")
		fi
	done

	# List of elements from diff1 that don't start any element in Whitelist.
	diff2=()
	for i in "${diff1[@]}"; do  
		flag=0
		for j in "${wl[@]}"; do 
			if [[ "$j" == "$i"* ]]; then
				flag=1
				break
			fi
		done 
		if [ $flag == 0 ]; then
			diff2+=("$i")
		fi
	done

	# Keep only parent directories in the diff2. This gives us the Blacklist.
	bl=()
	for i in "${diff2[@]}"; do
		flag=0
		for j in "${bl[@]}"; do
			if [[ "$i" == "$j"* ]]; then
				flag=1
				break
			fi
		done
		if [ $flag == 0 ]; then
			bl+=("$i")
		fi
	done

	echo "[`date "+%Y-%m-%d %H:%M:%S"`] [DEBUG] - List of all the blacklisted files and directories under $DROPBOX_SYNC_DIR: ${bl[*]}"

	# Reset dropbox exclusion list everytime .dropbox-whitelist is updated. 
	# Since sync after reset may take some time for files of bigger sizes, it may take a couple of iterations before they get included or excluded as part of dropbox exclusion list. This is one particular reason why file and directory names can't be validated locally per iteration.
	md5=`md5sum $DROPBOX_WHITELIST_FILE | cut -d" " -f 1`
	if [ "$md5" != "$_md5" ]; then
		echo "[`date "+%Y-%m-%d %H:%M:%S"`] [INFO] - Resetting dropbox exclusion list since $DROPBOX_WHITELIST_FILE is modified! New md5 $md5 vs old md5 $_md5."

		_md5=$md5
		dropbox exclude remove $DROPBOX_SYNC_DIR
	fi

	echo "[`date "+%Y-%m-%d %H:%M:%S"`] [INFO] - Updating dropbox exclusion list."
	for i in "${bl[@]}"; do dropbox exclude add "$DROPBOX_SYNC_DIR/$i"; done
	
	rotateLog &	

	echo "[`date "+%Y-%m-%d %H:%M:%S"`] [INFO] - Sleep for 10 sec..."
	sleep 10
done
