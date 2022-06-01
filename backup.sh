#!/bin/bash
set -e

backup_source="/Users/aronbeal"
backup_target="/Volumes/Aron/HottomaliBackup"
backup_directories=( "Dropbox" "Desktop" "Documents" "Code" "Sites" )
timestamp=$(date +%s)
if [[ ! -d  ${backup_source} ]]; then
	echo "Backup source dir ${backup_source} does not exist, exiting"
	exit 1
fi
if [[ ! -d  ${backup_target} ]]; then
	echo "Backup target dir ${backup_target} does not exist, exiting"
	exit 1
fi
# Send all output to a logging file in the target once we know it exists.

# Create the remote timestamp dir to store output in.
mkdir -p "${backup_target}/${timestamp}"	
logfile="${backup_target}/${timestamp}/output.log"
{

	# Backup important dotfiles
	backup_files=( ".aws/config" ".aws/credentials" ".profile" ".gitignore_global" ".composer/composer.json" )
	for fil in ${backup_files[@]}; do
		echo "Copying ${backup_source}/${fil} to ${backup_target}/${timestamp}/${fil}"
		mkdir -p "${backup_target}/${timestamp}/$(dirname ${fil})"
		cp "${backup_source}/${fil}" "${backup_target}/${timestamp}/${fil}"
	done

	# Temp dir for storing archive before copying over to remote.
	mytmpdir=$(mktemp -d)
	# Check all dirs before starting.
	for dir in ${backup_directories[@]}; do
		if [[ ! -d  "${backup_source}/${dir}" ]]; then
			echo "Backup source dir ${backup_source}/${dir} does not exist, exiting"
			exit 1
		fi
		echo "Backing up ${backup_source}/${dir} to ${mytmpdir}/${dir}.tgz"
		tar -czf "${mytmpdir}/${dir}.tgz" \
			--exclude "node_modules" \
			--exclude "vendor" \
			"${backup_source}/${dir}"
		echo "Copying ${mytmpdir}/${dir}.tgz to ${backup_target}/${timestamp}/${dir}.tgz"
		cp "${mytmpdir}/${dir}.tgz" "${backup_target}/${timestamp}"
	done
} 2>&1 > "${logfile}"
