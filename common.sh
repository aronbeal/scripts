#!/usr/bin/env bash
##
# Provides a common set of functionality for other scripts in this repo
# to leverage.
##

##
# Prints the message to stderr and continues processing.
#
# Parameters:
# 1: The error message to print.
##
error() {
	if [[ -z ${1} ]]; then
		echo >&2 "Error: Required first parameter 'message' missing from call to error()"
	fi
	echo >&2 "Error: ${1}"
}
##
# Prints the message to stderr and exits with error code 1
#
# Parameters:
# 1: The error message to print.
##
fail() {
	if [[ -z ${1} ]]; then
		echo >&2 "Failure: Required first parameter 'message' missing from call to fail()"
		exit 1
	fi
	echo >&2 "Failure: ${1}"
	exit 1
}

##
# Imports an environment file as env variables into the script environment.
#
# Parameters:
#   1: A relative filepath, e.g.:  ./.env
# Example usage:
#   import_environment_file ./.env;
#   confirm_required_vars "FOO" "BAR" "BAZ"
##
import_environment_file() {
	if [[ ! -f "${1}" ]]; then
		fail "The file ${1} does not exist"
	fi
	set -o allexport
	source "${1}"
	set +o allexport
}

##
# Confirms that the variable keys passed as the first argument are
# set as environment values.
#
# This is often accompanied by importing from an environment file, e.g.:
#
# set -o allexport
# source ./.env
# set +o allexport
#
# Parameters:
#   1: An array of variable keys.
#
# Example usage:
#   import_environment_file ./.env;
#   confirm_required_vars "FOO" "BAR" "BAZ"
##
confirm_required_vars() {
	local result=true
	for var in "${@}"; do
		[[ -z "${!var}" ]] && {
			error "Required variable ${var} not set."
			return 255
		}
	done
	return 0
}

##
# Tests if a command is present.
#
# Parameters:
#   1: The command to test for existence.
#   2: An optional message to display upon failure instead of the default.
# Example usage:
# test_command "aws"
# (would test for the AWS cli installation)
#
test_command() {
	hash $1 || {
		if [[ ! -z "${2}" ]]; then
			fail "${2}"
		else
			fail "The command ${1} is required for this script to operate, but is not present on your system."
		fi
	}
}

##
# Confirm before doing something.
# Parameters:
#   1: Optional.  Question string.  Defaults to "Are you sure? [y/N]"
#
# Usage: `confirm "Do you mean it?" && [do something]`
##
confirm() {
	# call with a prompt string or use a default
	local prompt="${1:-Are you sure?} [y/N]: "
	read -r -p "${prompt}" response
	case "$response" in
	[yY][eE][sS] | [yY])
		true
		;;
	*)
		false
		;;
	esac
}

##
# Checks args for invalid combinations.
# Needs to be called BEFORE first optargs invocation in primary script.
#
# Parameters:
# $1 The incompatible flags.
# $2 The remainder of the arguments to the original command.
#
# Example:
# restrict_flag_pairing 'abfhl' "$@"
##
restrict_flag_pairing() {
	[[ -z "${1}" ]] && fail "${FUNCNAME[0]}: Requires the flags that cannot be paired as the first argument."
	local incompatible_flags="${1}"
	shift
	# Allows use of getopts inside a subroutine without side-effects:
	# https://stackoverflow.com/a/16655341
	local OPTIND o;
	local all_possible_opts=$(echo {a..z} | tr -d ' ' )
	local first_incompatible_flag=false
	# Allow any character from a-z as a possible flag.  Compare each flag against
	# the incompatible list.  If we find more than one match, it's a failure.
	while getopts "${all_possible_opts}" o; do
		case "${o}" in
			*)
				case ${incompatible_flags} in
					*"${o}"*)
					if [[ ${first_incompatible_flag} == false ]]; then
						first_incompatible_flag=${o}
					else
						fail "Incompatible flags passed: -${first_incompatible_flag}, -${o}"
					fi
					;;
				esac
				;;
		esac
	done
	shift $((OPTIND-1))
}

##
# Fetches all variable names from an env file. Echoes to stdout.
# Parameters:
# $1: The full path to the env file to be parsed.
##
get_env_vars_from_file() {
	[[ -z "$1" ]] && fail "Required argument to ${FUNCNAME[0]} env_file is not set."
	[[ ! -f "$1" ]] && fail "Required argument to ${FUNCNAME[0]} env_file ($1) is not a valid file."
	local env_file="${1}"
	echo $(grep -v '^#' "${env_file}" | sed -e 's/=.*//')
}
