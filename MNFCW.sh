#!/usr/bin/env bash
# shellcheck disable=SC2094 # Dirty hack avoid runcommand to steal stdout

title="MiSTer NFC Writer"
scriptdir="$(dirname "$(readlink -f "${0}")")"
version="0.1"
fullFileBrowser="false"
basedir="/media/fat"

_depends() {
	if ! [[ -x "$(command -v dialog)" ]]; then
		echo "dialog not installed." >"$(tty)"
		sleep 10
		_exit 1
	fi
}

main() {
	menuOptions=(
		"Read"     "Read NFC Tag"
		"Write"    "Write NFC Tag"
		#"Settings" "Options for ${title}"
		"About"    "About this program"
	)

	selected="$(dialog \
		--backtitle "${title}" \
		--cancel-label "Exit" \
		--default-item "${selected}" \
		--menu "Choose one" \
		22 77 16 "${menuOptions[@]}" 3>&1 1>&2 2>&3 >"$(tty)")"

}

_Read() {
	_msgbox "logic to read an NFC tag hasn't been implemented yet"
}

_Write() {
	local fileSelected extension gameName
	fileSelected="$(_fselect "${basedir}")"
	extension="${fileSelected##*.}"
	extension="${extension,,}"
	fileSize="$(du -h "${fileSelected}")"
	fileSize="${fileSize%%	*}"

	if [[ ! -f "${fileSelected}" ]]; then
		_error "No file was selected."
		return
	fi

	_yesno "${fileSelected}" --title "${gameName}"  --ok-label "Write" #--extra-button --extra-label "Delete"

	case $? in
	1 | 255)
		# cancel or esc
		return
		;;

	# extra-button
	#3)
	#	#delete
	#	rm "${fileSelected}" || {
	#		_error "Unable to delete file!!"
	#		return
	#	}
	#	_msgbox "${fileSelected} deleted."
	#	return
	#	;;
	esac

	######################
	#TODO: Wite Logic here
	######################

	_msgbox "logic to write paths to NFC tags hasnt been implemented yet"
}

_About() {
	local about githash builddate gitbranch
	githash="$(git --git-dir="${scriptdir}/.git" rev-parse --short HEAD)"
	gitbranch="$(git --git-dir="${scriptdir}/.git" rev-parse --abbrev-ref HEAD)"
	builddate="$(git --git-dir="${scriptdir}/.git" log -1 --date=short --pretty=format:%cd)"
	read -rd '' about <<_EOF_
${title} ${version}-${gitbranch}-${builddate} + ${githash}

Add useful description here!
_EOF_
	_msgbox "${about}" --title "About"
}

# dialog --fselect broken out to a function,
# the purpouse is that
# if the screen is smaller then what --fselec can handle
# I can do somethig else
# Usage: _fselect "${fullPath}"
# returns the file that is selected including the full path, if full path is used.
_fselect() {
	local termh windowh dirList selected extension fileName fullPath newDir #gameName
	fullPath="${1}"
	termh="$(tput lines)"
	((windowh = "${termh}" - 10))
	[[ "${windowh}" -gt "22" ]] && windowh="22"
	if "${fullFileBrowser}" && [[ "${windowh}" -ge "8" ]]; then
		dialog \
			--backtitle "${title}" \
			--title "${fullPath}" \
			--fselect "${fullPath}/" \
			"${windowh}" 77 3>&1 1>&2 2>&3 >"$(tty)"

	else
		# in case of a very tiny terminal window
		# make an array of the filenames and put them into --menu instead
		dirList=(
			"goto" "Go to directory (keyboard required)"
			".." "Up one directory"
		)

		while read -r folderName; do
			dirList+=("$(basename "${folderName}")" "Directory")

		done < <(find "${fullPath}" -mindepth 1 -maxdepth 1 ! -name '.*' -type d)

		while read -r fileName; do
			extension="${fileName##*.}"
			#remove the next line
			echo "${extension}"
			#do something else here
			#this is legacy code from a previous project of mine
			#case "${extension,,}" in
			#"exe")
			#	dirList+=("$(basename "${fileName}")")

			#	gameName="$("${innobin}" --gog-game-id "${fileName}")"
			#	gameName="$(awk -F'"' 'NR==1{print $2}' <<<"${gameName}")"
			#	dirList+=("${gameName}")
			#	;;

			#"sh")
			#	dirList+=("$(basename "${fileName}")")

			#	gameName="$(grep -Poam 1 'label="\K.*' "${fileName}")"
			#	dirList+=("${gameName% (GOG.com)\"}")
			#	;;
			#esac

		done < <(find "${fullPath}" -maxdepth 1 -type f)

		selected="$(dialog \
			--backtitle "${title}" \
			--title "${fullPath}" \
			--menu "Pick a file to install" \
			22 77 16 "${dirList[@]}" 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)")"

		[[ "${?}" -ge 1 ]] && return

		case "${selected}" in
		"goto")
			newDir="$(_inputbox "Input a directory to go to" "${basedir}")"
			_fselect "${newDir}"
			;;
		"..")
			_fselect "${fullPath%/*}"
			;;
		*.sh | *.exe)
			echo "${fullPath}/${selected}"
			;;
		*)
			_fselect "${fullPath}/${selected}"
			;;
		esac

	fi

}

# Ask user for a string
# Usage: _inputbox "My message" "Initial text" [--optional-arguments]
# You can pass additioal arguments to the dialog program
# Backtitle is already set
_inputbox() {
	local msg opts init
	msg="${1}"
	init="${2}"
	shift 2
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		"${opts[@]}" \
		--inputbox "${msg}" \
		22 77 "${init}" 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
}

# Display a message
# Usage: _msgbox "My message" [--optional-arguments]
# You can pass additioal arguments to the dialog program
# Backtitle is already set
_msgbox() {
	local msg opts
	msg="${1}"
	shift
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		"${opts[@]}" \
		--msgbox "${msg}" \
		22 77  3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
}

# Request user input
# Usage: _yesno "My question" [--optional-arguments]
# You can pass additioal arguments to the dialog program
# Backtitle is already set
# returns the exit code from dialog which depends on the user answer
_yesno() {
	local msg opts
	msg="${1}"
	shift
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		"${opts[@]}" \
		--yesno "${msg}" \
		22 77 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
	return "${?}"
}

# Display an error
# Usage: _error "My error" [1] [--optional-arguments]
# If the second argument is a number, the program will exit with that number as an exit code.
# You can pass additioal arguments to the dialog program
# Backtitle and title are already set
# Returns the exit code of the dialog program
_error() {
	local msg opts answer exitcode
	msg="${1}"
	shift
	[[ "${1}" =~ ^[0-9]+$ ]] && exitcode="${1}" && shift
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		--title "ERROR:" \
		"${opts[@]}" \
		--msgbox "${msg}" \
		22 77 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
	answer="${?}"
	[[ -n "${exitcode}" ]] && exit "${exitcode}"
	return "${answer}"
}

_exit() {
	clear
	exit "${1:-0}"
}

_depends

while true; do
	main
	"_${selected:-exit}"
done
